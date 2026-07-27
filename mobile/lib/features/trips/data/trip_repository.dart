import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'trip.dart';
import 'trip_member.dart';
import 'invite.dart';

/// Talks to /trips. Converts Dio failures into ApiException so nothing
/// Dio-specific leaks into the UI layer.
/// Distinguishes "not mentioned" from "set to null" in a PATCH. Sending null
/// where the caller meant nothing would clear a field nobody touched.
const _unset = Object();

class TripRepository {
  TripRepository({required this.dio});

  final Dio dio;

  Future<List<Trip>> list({bool archived = false}) async {
    try {
      final response = await dio.get(
        '/trips',
        queryParameters: archived ? const {'archived': true} : null,
      );
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
    String? icon,
    String? color,
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
          // Omitted rather than sent as null when the user skipped the step, so
          // "not chosen" stays the server's own default.
          'icon': ?icon,
          'color': ?color,
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

  /// Owner only. Only the keys passed are sent, so a PATCH never blanks a field
  /// the settings screen did not touch — which is why every parameter here is a
  /// sentinel rather than a plain null.
  Future<Trip> update(
    String tripId, {
    Object? name = _unset,
    Object? description = _unset,
    Object? startDate = _unset,
    Object? endDate = _unset,
    Object? baseCurrency = _unset,
    Object? icon = _unset,
    Object? color = _unset,
    Object? archived = _unset,
  }) async {
    final data = <String, dynamic>{
      if (name != _unset) 'name': name,
      if (description != _unset) 'description': description,
      if (startDate != _unset)
        'start_date': startDate == null ? null : _asDate(startDate as DateTime),
      if (endDate != _unset)
        'end_date': endDate == null ? null : _asDate(endDate as DateTime),
      if (baseCurrency != _unset) 'base_currency': baseCurrency,
      if (icon != _unset) 'icon': icon,
      if (color != _unset) 'color': color,
      if (archived != _unset) 'archived': archived,
    };
    try {
      final response = await dio.patch('/trips/$tripId', data: data);
      return Trip.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// The expense ledger as a CSV, with the filename the server chose.
  ///
  /// Bytes rather than a string: the response carries a byte-order mark so
  /// spreadsheets read it as UTF-8, and decoding then re-encoding it here would
  /// be two chances to lose that.
  Future<({List<int> bytes, String filename})> exportCsv(String tripId) async {
    try {
      final response = await dio.get<List<int>>(
        '/trips/$tripId/export.csv',
        options: Options(responseType: ResponseType.bytes),
      );
      return (
        bytes: response.data ?? const <int>[],
        filename: _filenameFrom(response.headers.value('content-disposition')),
      );
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Reads the plain `filename="..."` parameter, ignoring the RFC 5987 one:
  /// the ASCII form is already safe to write to a filesystem, which the
  /// percent-encoded original is not.
  static String _filenameFrom(String? disposition) {
    final match = RegExp('filename="([^"]+)"').firstMatch(disposition ?? '');
    return match?.group(1) ?? 'expenses.csv';
  }

  Future<bool> isMuted(String tripId) async {
    try {
      final response = await dio.get('/trips/$tripId/members/me/settings');
      return response.data['muted'] as bool;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> setMuted(String tripId, bool muted) async {
    try {
      await dio.patch(
        '/trips/$tripId/members/me/settings',
        data: {'muted': muted},
      );
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
