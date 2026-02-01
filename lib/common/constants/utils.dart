import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:file_picker/file_picker.dart';

/// Helper function để format DateTime thành ISO8601 string mà không bị lệch timezone
/// Chuyển date về UTC noon (12:00 PM) để tránh vấn đề timezone khi gửi lên server
String formatDateForApi(DateTime date) {
  final utcDate = DateTime.utc(date.year, date.month, date.day, 12, 0, 0);
  return utcDate.toIso8601String();
}

void showSnackBar(
  BuildContext context,
  String text, {
  Duration duration = const Duration(seconds: 2),
}) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(text), duration: duration));
}

Future<List<dynamic>> pickImages() async {
  List<dynamic> images = [];
  try {
    var files = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (files != null && files.files.isNotEmpty) {
      for (int i = 0; i < files.files.length; i++) {
        if (kIsWeb) {
          images.add(files.files[i].bytes!);
        } else {
          images.add(File(files.files[i].path!));
        }
      }
    }
  } catch (e) {
    debugPrint(e.toString());
  }
  return images;
}

Future<dynamic> pickImage() async {
  try {
    var result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      if (kIsWeb) {
        return result.files.first.bytes!;
      } else {
        return File(result.files.first.path!);
      }
    }
  } catch (e) {
    debugPrint(e.toString());
  }
  return null;
}
