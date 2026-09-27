import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class DoctorDocumentStorage {
  Future<String> saveDocument(String sourcePath) async {
    final appDirectory = await getApplicationSupportDirectory();

    final documentsDirectory = Directory(
      path.join(
        appDirectory.path,
        'Wisteria',
        'doctor',
        'documents',
      ),
    );

    if (!await documentsDirectory.exists()) {
      await documentsDirectory.create(recursive: true);
    }

    final fileName = path.basename(sourcePath);

    final destinationPath = path.join(
      documentsDirectory.path,
      fileName,
    );

    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw Exception('Selected PDF does not exist.');
    }

    await sourceFile.copy(destinationPath);

    return destinationPath;
  }

  Future<void> deleteDocument(String filePath) async {
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }
  }
}