import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

class ShareService {
  Future<void> shareFile(String filePath, {String? subject}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File tidak ditemukan untuk dibagikan');
    }

    final xFile = XFile(filePath);
    await Share.shareXFiles(
      [xFile],
      subject: subject ?? 'Hasil Optimasi Promptix',
      text: 'Dibagikan dari Promptix',
    );
  }

  Future<void> openFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File tidak ditemukan');
    }

    final result = await OpenFilex.open(filePath);
    if (result.type == ResultType.noAppToOpen) {
      throw Exception('Tidak ada aplikasi untuk membuka file ini');
    }
    if (result.type == ResultType.permissionDenied) {
      throw Exception('Izin ditolak untuk membuka file');
    }
  }
}
