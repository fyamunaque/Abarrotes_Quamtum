import 'dart:typed_data';

import 'package:abarrotes_server/src/common/http_json.dart';
import 'package:abarrotes_server/src/products/product_images.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

/// Una foto de [width] × [height] de un solo color.
img.Image _photo(int width, int height, {int numChannels = 3}) =>
    img.Image(width: width, height: height, numChannels: numChannels)
      ..clear(img.ColorRgb8(200, 120, 40));

img.Image _decode(Uint8List bytes) => img.decodeJpg(bytes)!;

Matcher _badRequest(String text) => isA<ApiException>()
    .having((e) => e.statusCode, 'statusCode', 400)
    .having((e) => '${e.message}', 'message', contains(text));

void main() {
  group('ProductImages.process', () {
    test('una foto grande queda en JPEG de 800 px por su lado largo', () {
      final out = ProductImages.process(img.encodePng(_photo(2000, 1000)));

      expect(img.findFormatForData(out), img.ImageFormat.jpg);
      final photo = _decode(out);
      expect((photo.width, photo.height), (800, 400));
    });

    test('vertical: el lado largo es el alto', () {
      final photo = _decode(
        ProductImages.process(img.encodeJpg(_photo(900, 1800))),
      );
      expect((photo.width, photo.height), (400, 800));
    });

    test('una chica no se agranda', () {
      final photo = _decode(
        ProductImages.process(img.encodeJpg(_photo(300, 200))),
      );
      expect((photo.width, photo.height), (300, 200));
    });

    test('se endereza según su EXIF y sale sin metadatos', () {
      // Tomada con el teléfono de lado: 400 × 200 con orientación 6 (girar
      // 90°), y con datos de la cámara.
      final source = _photo(400, 200);
      source.exif.imageIfd.orientation = 6;
      source.exif.imageIfd['Make'] = 'Cámara de prueba';
      source.exif.imageIfd['Model'] = 'Modelo X';

      final photo = _decode(ProductImages.process(img.encodeJpg(source)));

      expect((photo.width, photo.height), (200, 400));
      expect(photo.exif.isEmpty, isTrue);
    });

    test('lo transparente de un PNG queda blanco', () {
      final source = _photo(100, 100, numChannels: 4)
        ..clear(img.ColorRgba8(0, 0, 0, 0));

      final pixel = _decode(
        ProductImages.process(img.encodePng(source)),
      ).getPixel(50, 50);

      expect([pixel.r, pixel.g, pixel.b], everyElement(greaterThan(245)));
    });

    test('acepta WebP', () {
      // image no codifica WebP: uno de 1 × 1 sin pérdida, hecho a mano.
      final webp = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, 0x1a, 0x00, 0x00, 0x00, 0x57, 0x45, 0x42, //
        0x50, 0x56, 0x50, 0x38, 0x4c, 0x0d, 0x00, 0x00, 0x00, 0x2f, 0x00,
        0x00, 0x00, 0x10, 0x07, 0x10, 0x11, 0x11, 0x88, 0x88, 0xfe, 0x07,
        0x00,
      ]);
      expect(img.findFormatForData(webp), img.ImageFormat.webp);

      final photo = _decode(ProductImages.process(webp));
      expect((photo.width, photo.height), (1, 1));
    });

    test('algo que no es una imagen: 400', () {
      expect(
        () => ProductImages.process(Uint8List.fromList(List.filled(500, 7))),
        throwsA(_badRequest('JPEG, PNG o WebP')),
      );
    });

    test('un formato que no se acepta (GIF): 400', () {
      expect(
        () => ProductImages.process(img.encodeGif(_photo(10, 10))),
        throwsA(_badRequest('JPEG, PNG o WebP')),
      );
    });

    test('un JPEG cortado antes de decir su tamaño: 400', () {
      final jpeg = img.encodeJpg(_photo(200, 200));
      expect(
        () => ProductImages.process(
          Uint8List.sublistView(jpeg, 0, _markerOffset(jpeg, 0xC0)),
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });

    test('más de 40 megapíxeles se rechaza antes de abrirla', () {
      // Un JPEG chico que dice medir 8000 × 8000 (64 MP): basta la cabecera.
      final jpeg = img.encodeJpg(_photo(16, 16));
      final sof = _markerOffset(jpeg, 0xC0);
      ByteData.sublistView(jpeg)
        ..setUint16(sof + 5, 8000)
        ..setUint16(sof + 7, 8000);

      expect(
        () => ProductImages.process(jpeg),
        throwsA(_badRequest('40 megapíxeles')),
      );
    });
  });

  test('isStored distingue la foto subida de una URL externa', () {
    expect(ProductImages.isStored('/images/products/a/b.jpg'), isTrue);
    expect(ProductImages.isStored('https://cdn.tienda.pe/a.jpg'), isFalse);
    expect(ProductImages.isStored(null), isFalse);
  });
}

/// Dónde empieza el marcador JPEG 0xFF[marker] (p. ej. 0xC0, el SOF0).
int _markerOffset(Uint8List jpeg, int marker) {
  for (var i = 0; i < jpeg.length - 1; i++) {
    if (jpeg[i] == 0xFF && jpeg[i + 1] == marker) return i;
  }
  throw StateError('Sin el marcador $marker');
}
