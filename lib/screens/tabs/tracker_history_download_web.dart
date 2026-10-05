// Web implementation — triggers a browser download via dart:html
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> saveAndShareFile({
  required List<int> bytes,
  required String    filename,
  required String    mimeType,
  String?            subject,
}) async {
  final blob   = html.Blob([bytes], mimeType);
  final url    = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return false; // no "Downloads folder" concept on web
}