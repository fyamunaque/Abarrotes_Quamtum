/// La URL de una imagen que se pega en un formulario del panel (productos y
/// categorías). Opcional; si está, una URL http(s) completa de hasta 2000
/// caracteres, como pide el servidor.
String? validateImageUrl(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final uri = Uri.tryParse(text);
  final valid =
      uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
  if (!valid) return 'Escribe una dirección que empiece con https://';
  if (text.length > 2000) return 'Máximo 2000 caracteres.';
  return null;
}
