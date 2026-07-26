import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'checklist.dart';

class ChecklistRepository {
  ChecklistRepository({required this.dio});

  final Dio dio;

  Future<List<Checklist>> list(String tripId) async {
    try {
      final response = await dio.get('/trips/$tripId/checklists');
      return (response.data as List)
          .map((json) => Checklist.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Checklist> create({
    required String tripId,
    required String name,
  }) async {
    try {
      final response = await dio.post(
        '/trips/$tripId/checklists',
        data: {'name': name},
      );
      return Checklist.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> delete(String tripId, String checklistId) async {
    try {
      await dio.delete('/trips/$tripId/checklists/$checklistId');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ChecklistEntry> addEntry({
    required String tripId,
    required String checklistId,
    required String text,
  }) async {
    try {
      final response = await dio.post(
        '/trips/$tripId/checklists/$checklistId/entries',
        data: {'text': text},
      );
      return ChecklistEntry.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> deleteEntry({
    required String tripId,
    required String checklistId,
    required String entryId,
  }) async {
    try {
      await dio.delete(
        '/trips/$tripId/checklists/$checklistId/entries/$entryId',
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ChecklistEntry> setChecked({
    required String tripId,
    required String checklistId,
    required String entryId,
    required bool checked,
  }) async {
    try {
      final path =
          '/trips/$tripId/checklists/$checklistId/entries/$entryId/check';
      final response = checked ? await dio.post(path) : await dio.delete(path);
      return ChecklistEntry.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}
