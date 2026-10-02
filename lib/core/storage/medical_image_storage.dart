import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class MedicalImageStorage {
  static const _uuid = Uuid();

  Future<String> saveImage({
    required String patientId,
    required String examinationId,
    required String originalFilePath,
  }) async {
    final sourceFile = File(originalFilePath);

    if (!await sourceFile.exists()) {
      throw Exception('Selected image file does not exist.');
    }

    final extension = path.extension(originalFilePath);

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

    await imagesDirectory.create(recursive: true);

    final uniqueFileName = '${_uuid.v4()}$extension';

    final destinationPath = path.join(imagesDirectory.path, uniqueFileName);

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
