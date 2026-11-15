/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

enum LocationCategory implements _isc.SerializableModel {
  bathroom,
  studySpace,
  exit,
  entrance,
  elevator,
  stairs,
  classroom,
  auditorium,
  food,
  office,
  accessibilityService,
  landmark,
  other;

  static LocationCategory fromJson(String name) {
    switch (name) {
      case 'bathroom':
        return LocationCategory.bathroom;
      case 'studySpace':
        return LocationCategory.studySpace;
      case 'exit':
        return LocationCategory.exit;
      case 'entrance':
        return LocationCategory.entrance;
      case 'elevator':
        return LocationCategory.elevator;
      case 'stairs':
        return LocationCategory.stairs;
      case 'classroom':
        return LocationCategory.classroom;
      case 'auditorium':
        return LocationCategory.auditorium;
      case 'food':
        return LocationCategory.food;
      case 'office':
        return LocationCategory.office;
      case 'accessibilityService':
        return LocationCategory.accessibilityService;
      case 'landmark':
        return LocationCategory.landmark;
      case 'other':
        return LocationCategory.other;
      default:
        return LocationCategory.other;
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
