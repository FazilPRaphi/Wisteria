import 'package:drift/drift.dart';

import '../database.dart';

class DoctorRepository {
  final WisteriaDatabase database;

  DoctorRepository(this.database);

  Future<DoctorProfile?> getProfile() {
    return database.select(database.doctorProfiles).getSingleOrNull();
  }

  Future<void> saveProfile({
    required String id,
    required String doctorName,
    String? specialization,
    String? clinicName,
    String? clinicAddress,
    String? clinicPhoneNumber,
    String? signature,
  }) async {
    final existing = await getProfile();

    final companion = DoctorProfilesCompanion(
      id: Value(id),
      doctorName: Value(doctorName),
      specialization: Value(specialization),
      clinicName: Value(clinicName),
      clinicAddress: Value(clinicAddress),
      clinicPhoneNumber: Value(clinicPhoneNumber),
      signature: Value(signature),
    );

    if (existing == null) {
      await database.into(database.doctorProfiles).insert(companion);
    } else {
      await database
          .update(database.doctorProfiles)
          .write(companion);
    }
  }
}