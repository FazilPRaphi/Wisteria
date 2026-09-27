import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class MedicalImageStorage {
  Future<String> saveImage({
    required String patientId,
    required String examinationId,
    required String originalFilePath,
  }) async {
    final appDirectory = await getApplicationSupportDirectory();

    final imagesDirectory = Directory(
      path.join(
        appDirectory.path,
        'Wisteria',
        'patients',
        patientId,
        'examinations',
        examinationId,
        'images',
      ),
    );

    if (!await imagesDirectory.exists()) {
      await imagesDirectory.create(recursive: true);
    }

    final originalFileName = path.basename(originalFilePath);

    final destinationPath = path.join(
      imagesDirectory.path,
      originalFileName,
    );

    final sourceFile = File(originalFilePath);

    if (!await sourceFile.exists()) {
      throw Exception('Selected image file does not exist.');
    }

    await sourceFile.copy(destinationPath);

    return destinationPath;
  }

  Future<void> deleteImage(String filePath) async {
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }
  }
}