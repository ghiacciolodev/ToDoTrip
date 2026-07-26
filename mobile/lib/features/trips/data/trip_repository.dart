import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'trip.dart';
import 'trip_member.dart';
import 'invite.dart';

/// Talks to /trips. Converts Dio failures into ApiException so nothing
/// Dio-specific leaks into the UI layer.
class TripRepository {
  TripRepository({required this.dio});

  final Dio dio;

  Future<List<Trip>> list() async {
    try {
      final response = await dio.get('/trips');
      return (response.data as List)
          .map((json) => Trip.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Trip> create({
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await dio.post(
        '/trips',
        data: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
          // The API column is DATE, not timestamp: sending an ISO datetime
          // would be rejected, so only the calendar day is sent.
          if (startDate != null) 'start_date': _asDate(startDate),
          if (endDate != null) 'end_date': _asDate(endDate),
        },
      );
      return Trip.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Trip> joinByCode(String code) async {
    try {
      final response = await dio.post(
        '/trips/join',
        data: {'code': code.trim().toUpperCase()},
      );
      return Trip.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  static String _asDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  Future<Trip> byId(String tripId) async {
    try {
      final response = await dio.get('/trips/$tripId');
      return Trip.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<TripMember>> members(String tripId) async {
    try {
      final response = await dio.get('/trips/$tripId/members');
      return (response.data as List)
          .map((json) => TripMember.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Leaves the trip, or deletes it when the caller is the last member.
  ///
  /// A 409 carries a code: `owner_must_transfer` when the trip would be left
  /// unmanaged, `outstanding_balance` when there is money open, with the amount
  /// in the details.
  Future<void> leave(String tripId) async {
    try {
      await dio.delete('/trips/$tripId/members/me');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Owner only. Fails with `outstanding_balance` if the member is not settled.
  Future<void> removeMember(String tripId, String userId) async {
    try {
      await dio.delete('/trips/$tripId/members/$userId');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Owner only. Returns the members with their new roles: the caller has just
  /// stopped being the owner, and the UI has to reflect both changes at once.
  Future<List<TripMember>> makeOwner(String tripId, String userId) async {
    try {
      final response = await dio.post('/trips/$tripId/members/$userId/owner');
      return (response.data as List)
          .map((json) => TripMember.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> delete(String tripId) async {
    try {
      await dio.delete('/trips/$tripId');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<Invite>> invites(String tripId) async {
    try {
      final response = await dio.get('/trips/$tripId/invites');
      return (response.data as List)
          .map((json) => Invite.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Codes are created on demand, never on screen open: otherwise every visit
  /// to the Group tab would leave a row behind.
  Future<Invite> createInvite(String tripId) async {
    try {
      final response = await dio.post('/trips/$tripId/invites', data: {});
      return Invite.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> revokeInvite(String tripId, String inviteId) async {
    try {
      await dio.delete('/trips/$tripId/invites/$inviteId');
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}
