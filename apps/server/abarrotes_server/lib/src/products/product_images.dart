import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:serverpod/serverpod.dart';

import '../common/http_json.dart';

/// Las fotos de los productos. Las procesa ([process]) y las guarda en el
/// almacenamiento `public` de Serverpod: la base de datos, salvo que se
/// configure otro (S3, Google Cloud) en `server.dart`.
///
/// En `Product.imageUrl` va una ruta relativa a este servidor
/// (`/images/products/<id del producto>/<archivo>.jpg`), sin el host: la app
/// la completa con la dirección por la que lo ve (`localhost` en la web,
/// `10.0.2.2` en el emulador). Cada foto subida tiene un nombre nuevo, así el
/// navegador puede guardarla en caché para siempre.
class ProductImages {
  ProductImages({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  static const storageId = 'public';

  /// El comienzo de la URL de una foto subida (y de la ruta que la sirve).
  static const urlPrefix = '/images/products/';

  /// Lo más que puede pesar la foto que llega.
  static const maxUploadBytes = 8 * 1024 * 1024;

  /// El lado más largo de la foto guardada.
  static const maxSide = 800;

  /// Más que esto no se abre: una imagen chica en bytes puede pedir cientos
  /// de MB al decodificarse.
  static const maxPixels = 40 * 1000 * 1000;

  static const jpegQuality = 82;

  static final _fileName = RegExp(r'^[0-9a-f]{16}\.jpg$');
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );

  /// Si [url] es de una foto subida aquí (y no una URL externa).
  static bool isStored(String? url) => url != null && url.startsWith(urlPrefix);

  /// La foto lista para guardar: JPEG, de hasta [maxSide] px por lado,
  /// derecha según su EXIF, sobre blanco si tenía transparencia y sin
  /// metadatos (ni ubicación ni cámara). Acepta JPEG, PNG y WebP, que
  /// reconoce por su contenido. Si no es una de esas o es demasiado grande
  /// para abrirla, [ApiException] 400.
  static Uint8List process(Uint8List bytes) {
    final decoder = img.findDecoderForData(bytes);
    if (decoder == null ||
        !const {
          img.ImageFormat.jpg,
          img.ImageFormat.png,
          img.ImageFormat.webp,
        }.contains(decoder.format)) {
      throw const ApiException.badRequest(
        'La foto tiene que ser una imagen JPEG, PNG o WebP',
      );
    }
    img.DecodeInfo? info;
    try {
      info = decoder.startDecode(bytes);
    } catch (_) {
      throw _unreadable;
    }
    if (info == null) throw _unreadable;
    if (info.width * info.height > maxPixels) {
      throw const ApiException.badRequest(
        'La foto es demasiado grande: como máximo 40 megapíxeles',
      );
    }

    img.Image? decoded;
    try {
      decoded = decoder.decode(bytes, frame: 0);
    } catch (_) {
      throw _unreadable;
    }
    if (decoded == null) throw _unreadable;

    var photo = img.bakeOrientation(decoded);
    if (max(photo.width, photo.height) > maxSide) {
      photo = photo.width >= photo.height
          ? img.copyResize(
              photo,
              width: maxSide,
              interpolation: img.Interpolation.average,
            )
          : img.copyResize(
              photo,
              height: maxSide,
              interpolation: img.Interpolation.average,
            );
    }
    // Una imagen nueva, sin el EXIF ni el perfil de color de la original; lo
    // transparente queda blanco (JPEG no tiene transparencia).
    final clean = img.Image(width: photo.width, height: photo.height)
      ..clear(img.ColorRgb8(255, 255, 255));
    img.compositeImage(clean, photo);
    return img.encodeJpg(clean, quality: jpegQuality);
  }

  static const _unreadable = ApiException.badRequest(
    'No se pudo leer la foto: el archivo está dañado o no es una imagen',
  );

  /// Guarda [jpeg] (ya procesada) como una foto nueva del producto
  /// [productId] y devuelve su URL.
  Future<String> store(
    Session session,
    UuidValue productId,
    Uint8List jpeg,
  ) async {
    final name = '${_hex(8)}.jpg';
    await session.storage.storeFile(
      storageId: storageId,
      path: 'products/$productId/$name',
      byteData: ByteData.sublistView(jpeg),
    );
    return '$urlPrefix$productId/$name';
  }

  /// La foto [file] del producto [productId], o null si no existe (o el
  /// nombre no es uno de los que pone [store]).
  Future<Uint8List?> read(
    Session session,
    String productId,
    String file,
  ) async {
    if (!_uuid.hasMatch(productId) || !_fileName.hasMatch(file)) return null;
    try {
      final data = await session.storage.retrieveFile(
        storageId: storageId,
        path: 'products/$productId/$file',
      );
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } on CloudStorageFileNotFoundException {
      return null;
    }
  }

  /// Borra la foto de [url] si es una subida aquí. Una URL externa no se
  /// toca. Si falla, queda en el log: el producto ya no la usa.
  Future<void> delete(Session session, String? url) async {
    if (url == null || !isStored(url)) return;
    try {
      await session.storage.deleteFile(
        storageId: storageId,
        path: 'products/${url.substring(urlPrefix.length)}',
      );
    } on CloudStorageException catch (error) {
      session.log(
        'No se pudo borrar la foto $url: $error',
        level: LogLevel.warning,
      );
    }
  }

  String _hex(int bytes) => [
    for (var i = 0; i < bytes; i++)
      _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
}
