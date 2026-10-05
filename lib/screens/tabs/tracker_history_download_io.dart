// Mobile/desktop implementation — uses dart:io + share_plus
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<bool> saveAndShareFile({
  required List<int> bytes,
  required String    filename,
  required String    mimeType,
  String?            subject,
}) async {
  bool savedToDownloads = false;

  // Save to Downloads folder so it persists after the share sheet closes
  try {
    final dl = await getDownloadsDirectory();
    if (dl != null) {
      await File('${dl.path}/$filename').writeAsBytes(bytes);
      savedToDownloads = true;
    }
  } catch (_) {}

  // Also write to temp dir for the share sheet
  final tmp  = await getTemporaryDirectory();
  final file = File('${tmp.path}/$filename');
  await file.writeAsBytes(bytes);

  await Share.shareXFiles(
    [XFile(file.path, mimeType: mimeType)],
    subject: subject,
  );

  return savedToDownloads;
}