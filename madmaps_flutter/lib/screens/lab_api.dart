import 'dart:convert';

import '../client.dart';

abstract interface class LabApi {
  Future<Map<String, dynamic>> capabilities();
  Future<String> start(Map<String, dynamic> request);
  Future<Map<String, dynamic>> getJob(String id);
}

class ServerpodLabApi implements LabApi {
  @override
  Future<Map<String, dynamic>> capabilities() async =>
      jsonDecode(await client.extractionLab.capabilities())
          as Map<String, dynamic>;

  @override
  Future<String> start(Map<String, dynamic> request) async =>
      (jsonDecode(await client.extractionLab.start(jsonEncode(request)))
              as Map<String, dynamic>)['job_id']
          as String;

  @override
  Future<Map<String, dynamic>> getJob(String id) async =>
      jsonDecode(await client.extractionLab.getJob(id)) as Map<String, dynamic>;
}
