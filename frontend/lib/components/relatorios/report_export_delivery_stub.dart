import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> deliverReportExport(
  List<int> bytes,
  String filename,
  String mimeType,
) async {
  final file = XFile.fromData(
    Uint8List.fromList(bytes),
    name: filename,
    mimeType: mimeType,
  );
  await SharePlus.instance.share(ShareParams(files: [file], subject: filename));
}
