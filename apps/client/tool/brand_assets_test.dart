// Genera el logo y los íconos de la app desde el logo original del cliente
// (brand/logo.jpg), sin paquetes: solo dart:ui. Desde apps/client:
//
//   flutter test tool/brand_assets_test.dart
//
// Escribe los PNG y después comprueba lo que escribió. Cuando llegue el
// original en SVG o PNG, se reemplaza brand/logo.jpg (un PNG con fondo
// blanco o transparente también sirve) y se vuelve a correr.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const _source = 'brand/logo.jpg';

/// El rojo del logo, como `NeilsColors.primary`.
const _red = ui.Color(0xFFC8281E);
const _white = ui.Color(0xFFFFFFFF);

/// El verde del rojo del logo (≈ 40) y del fondo (255): la transparencia de
/// cada píxel sale de dónde cae su verde entre los dos. Así los bordes quedan
/// suaves y del mismo rojo, sin el halo blanco de recortar por un umbral.
const _inkGreen = 40;

/// El ruido del JPEG sobre el blanco (verde de 247 a 255) queda transparente.
const _noise = 8;

/// Un logo como máscara: cuánto cubre cada píxel (0 a 255).
class _Mask {
  _Mask(this.width, this.height, this.alpha);

  final int width;
  final int height;
  final Uint8List alpha;

  int at(int x, int y) => alpha[y * width + x];
}

Future<_Mask> _loadMask() async {
  final codec = await ui.instantiateImageCodec(File(_source).readAsBytesSync());
  final image = (await codec.getNextFrame()).image;
  final rgba = (await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  ))!.buffer.asUint8List();
  final alpha = Uint8List(image.width * image.height);
  for (var i = 0; i < alpha.length; i++) {
    final green = rgba[i * 4 + 1];
    final sourceAlpha = rgba[i * 4 + 3];
    final cover = (255 - _noise - green) / (255 - _noise - _inkGreen);
    alpha[i] = (cover.clamp(0.0, 1.0) * sourceAlpha).round();
  }
  return _Mask(image.width, image.height, alpha);
}

/// Los bloques de filas con contenido, de arriba abajo: el tenedor, "NEIL'S"
/// y "FOOD SERVICE'S". Una fila cuenta si algún píxel cubre al menos 30 %; un
/// bloque de menos de 4 filas es ruido.
List<(int top, int bottom)> _blocks(_Mask mask) {
  final blocks = <(int, int)>[];
  int? start;
  for (var y = 0; y <= mask.height; y++) {
    var filled = false;
    if (y < mask.height) {
      for (var x = 0; x < mask.width && !filled; x++) {
        filled = mask.at(x, y) >= 77;
      }
    }
    if (filled) {
      start ??= y;
    } else if (start != null) {
      if (y - start >= 4) blocks.add((start, y - 1));
      start = null;
    }
  }
  return blocks;
}

/// El recorte de las filas [top] a [bottom], al ancho de su contenido, con
/// un margen transparente del 2 % del lado mayor.
_Mask _crop(_Mask mask, int top, int bottom) {
  var left = mask.width;
  var right = -1;
  for (var y = top; y <= bottom; y++) {
    for (var x = 0; x < mask.width; x++) {
      if (mask.at(x, y) > 12) {
        left = math.min(left, x);
        right = math.max(right, x);
      }
    }
  }
  final contentWidth = right - left + 1;
  final contentHeight = bottom - top + 1;
  final margin = (math.max(contentWidth, contentHeight) * 0.02).round();
  final width = contentWidth + margin * 2;
  final height = contentHeight + margin * 2;
  final alpha = Uint8List(width * height);
  for (var y = 0; y < contentHeight; y++) {
    for (var x = 0; x < contentWidth; x++) {
      alpha[(y + margin) * width + x + margin] = mask.at(left + x, top + y);
    }
  }
  return _Mask(width, height, alpha);
}

/// La máscara pintada de [color]. `decodeImageFromPixels` toma los píxeles
/// con el alfa premultiplicado.
Future<ui.Image> _paint(_Mask mask, ui.Color color) {
  final pixels = Uint8List(mask.width * mask.height * 4);
  final r = (color.r * 255).round();
  final g = (color.g * 255).round();
  final b = (color.b * 255).round();
  for (var i = 0; i < mask.alpha.length; i++) {
    final a = mask.alpha[i];
    pixels[i * 4] = (r * a / 255).round();
    pixels[i * 4 + 1] = (g * a / 255).round();
    pixels[i * 4 + 2] = (b * a / 255).round();
    pixels[i * 4 + 3] = a;
  }
  final done = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    pixels,
    mask.width,
    mask.height,
    ui.PixelFormat.rgba8888,
    done.complete,
  );
  return done.future;
}

/// Un ícono de [size] px: [background] (o transparente) y [logo] centrado,
/// con un ancho de [logoWidth] del lado.
Future<ui.Image> _icon(
  ui.Image logo,
  int size, {
  required double logoWidth,
  ui.Color? background,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final side = size.toDouble();
  if (background != null) {
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, side, side),
      ui.Paint()..color = background,
    );
  }
  final width = side * logoWidth;
  final height = width * logo.height / logo.width;
  canvas.drawImageRect(
    logo,
    ui.Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
    ui.Rect.fromLTWH((side - width) / 2, (side - height) / 2, width, height),
    ui.Paint()
      ..filterQuality = ui.FilterQuality.high
      ..isAntiAlias = true,
  );
  return recorder.endRecording().toImage(size, size);
}

Future<void> _writePng(String path, ui.Image image) async {
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(png!.buffer.asUint8List());
}

/// Un PNG escrito, leído de vuelta: ancho, alto y RGBA sin premultiplicar.
Future<(int, int, Uint8List)> _read(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final image = (await codec.getNextFrame()).image;
  final rgba = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  return (image.width, image.height, rgba!.buffer.asUint8List());
}

const _logo = 'assets/images/neils_logo.png';
const _logoWhite = 'assets/images/neils_logo_white.png';
const _res = 'android/app/src/main/res';

/// Los íconos: dónde van, su lado, el ancho del logo y si tienen fondo rojo.
/// - Normal y favicon: el logo al 76 % del lado.
/// - `maskable` (web): 60 %, dentro de la zona segura del 80 %.
/// - Primer plano del ícono adaptable de Android: 58 %, dentro de la zona
///   segura de 66/108, sobre transparente (el fondo rojo lo pone el XML).
const _icons = <(String, int, double, bool)>[
  ('web/favicon.png', 64, 0.76, true),
  ('web/icons/Icon-192.png', 192, 0.76, true),
  ('web/icons/Icon-512.png', 512, 0.76, true),
  ('web/icons/Icon-maskable-192.png', 192, 0.60, true),
  ('web/icons/Icon-maskable-512.png', 512, 0.60, true),
  ('$_res/mipmap-mdpi/ic_launcher.png', 48, 0.76, true),
  ('$_res/mipmap-hdpi/ic_launcher.png', 72, 0.76, true),
  ('$_res/mipmap-xhdpi/ic_launcher.png', 96, 0.76, true),
  ('$_res/mipmap-xxhdpi/ic_launcher.png', 144, 0.76, true),
  ('$_res/mipmap-xxxhdpi/ic_launcher.png', 192, 0.76, true),
  ('$_res/mipmap-mdpi/ic_launcher_foreground.png', 108, 0.58, false),
  ('$_res/mipmap-hdpi/ic_launcher_foreground.png', 162, 0.58, false),
  ('$_res/mipmap-xhdpi/ic_launcher_foreground.png', 216, 0.58, false),
  ('$_res/mipmap-xxhdpi/ic_launcher_foreground.png', 324, 0.58, false),
  ('$_res/mipmap-xxxhdpi/ic_launcher_foreground.png', 432, 0.58, false),
];

void main() {
  late List<(int, int)> sourceBlocks;
  late List<(int, int)> iconBlocks;

  setUpAll(() async {
    final source = await _loadMask();
    sourceBlocks = _blocks(source);
    if (sourceBlocks.length != 3) {
      fail(
        'El logo tiene que tener tres bloques (tenedor, NEIL\'S y FOOD '
        'SERVICE\'S); se encontraron ${sourceBlocks.length}: $sourceBlocks',
      );
    }
    final full = _crop(source, sourceBlocks.first.$1, sourceBlocks.last.$2);
    // El ícono: el tenedor y NEIL'S, sin FOOD SERVICE'S.
    final icon = _crop(source, sourceBlocks[0].$1, sourceBlocks[1].$2);
    iconBlocks = _blocks(icon);

    await _writePng(_logo, await _paint(full, _red));
    await _writePng(_logoWhite, await _paint(full, _white));
    final iconLogo = await _paint(icon, _white);
    for (final (path, size, logoWidth, withBackground) in _icons) {
      Directory(File(path).parent.path).createSync(recursive: true);
      await _writePng(
        path,
        await _icon(
          iconLogo,
          size,
          logoWidth: logoWidth,
          background: withBackground ? _red : null,
        ),
      );
    }
  });

  bool nearRed(Uint8List p, int i, int tolerance) =>
      (p[i] - 0xC8).abs() <= tolerance &&
      (p[i + 1] - 0x28).abs() <= tolerance &&
      (p[i + 2] - 0x1E).abs() <= tolerance;

  test('el logo tiene fondo transparente y es rojo', () async {
    final (width, height, pixels) = await _read(_logo);
    expect(pixels[3], 0, reason: 'la esquina es transparente');
    var opaqueRed = 0;
    var edges = 0;
    var edgesRed = 0;
    for (var i = 0; i < width * height * 4; i += 4) {
      final a = pixels[i + 3];
      if (a == 255 && nearRed(pixels, i, 2)) opaqueRed++;
      if (a > 32 && a < 224) {
        edges++;
        if (nearRed(pixels, i, 16)) edgesRed++;
      }
    }
    expect(opaqueRed, greaterThan(1000));
    // Los bordes son rojo semitransparente, no un halo blanco ni oscuro.
    expect(edgesRed / edges, greaterThan(0.95));
  });

  test('el logo blanco es el mismo, en blanco', () async {
    final (width, height, _) = await _read(_logo);
    final (whiteWidth, whiteHeight, pixels) = await _read(_logoWhite);
    expect((whiteWidth, whiteHeight), (width, height));
    for (var i = 0; i < pixels.length; i += 4) {
      if (pixels[i + 3] == 255) {
        expect(pixels.sublist(i, i + 3), [255, 255, 255]);
      }
    }
  });

  test('cada ícono tiene su tamaño y fondo rojo', () async {
    for (final (path, size, _, withBackground) in _icons) {
      final (width, height, pixels) = await _read(path);
      expect((width, height), (size, size), reason: path);
      if (withBackground) {
        expect(pixels[3], 255, reason: '$path: esquina opaca');
        expect(nearRed(pixels, 0, 2), isTrue, reason: '$path: esquina roja');
      } else {
        expect(pixels[3], 0, reason: '$path: esquina transparente');
      }
    }
  });

  test("el ícono lleva el tenedor y NEIL'S, sin FOOD SERVICE'S", () {
    expect(sourceBlocks, hasLength(3));
    expect(iconBlocks, hasLength(2));
  });
}
