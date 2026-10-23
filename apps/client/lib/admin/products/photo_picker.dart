import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Una foto elegida, lista para subir: sus bytes y su tipo.
typedef PickedPhoto = ({Uint8List bytes, String contentType});

/// De dónde sale la foto.
enum PhotoSource { gallery, camera }

/// Elige una foto del dispositivo: de la galería o los archivos (en la web y
/// en el teléfono) o con la cámara (solo en el teléfono). Las pantallas la
/// usan por [photoPickerProvider]; los tests la reemplazan.
abstract interface class PhotoPicker {
  /// Si se puede tomar la foto con la cámara.
  bool get canUseCamera;

  /// La foto elegida, ya achicada a [maxSide] px por lado como máximo para
  /// subir menos datos (el servidor la achica igual), o null si la persona
  /// canceló.
  Future<PickedPhoto?> pick(PhotoSource source);

  static const maxSide = 1600.0;
}

/// [PhotoPicker] con el paquete `image_picker`.
class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  bool get canUseCamera =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: switch (source) {
        PhotoSource.gallery => ImageSource.gallery,
        PhotoSource.camera => ImageSource.camera,
      },
      maxWidth: PhotoPicker.maxSide,
      maxHeight: PhotoPicker.maxSide,
      imageQuality: 85,
    );
    if (file == null) return null;
    return (bytes: await file.readAsBytes(), contentType: _typeOf(file));
  }

  /// El tipo que dice el archivo, o el de su extensión. El servidor reconoce
  /// la imagen por su contenido: esto es solo informativo.
  static String _typeOf(XFile file) {
    if (file.mimeType case final type? when type.startsWith('image/')) {
      return type;
    }
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => ImagePickerPhotoPicker(),
);
