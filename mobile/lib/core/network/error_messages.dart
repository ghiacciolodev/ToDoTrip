import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import 'api_exception.dart';

/// Turns an API failure into copy a user can act on, in their language.
///
/// The server speaks English and speaks to developers: "Only the sender can undo
/// this repayment" is a correct answer to a client, not a sentence to show
/// someone. So nothing from `message` is rendered — the mapping is by status
/// code and by the machine-readable `code`, both of which are stable in a way
/// prose is not.
///
/// The exception is the auth screen's ambiguity: the backend answers the same
/// thing for a wrong password and an unknown email, on purpose, so that
/// responses cannot be used to discover which addresses are registered. The
/// wording here preserves that.
String friendlyError(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context);
  if (error is! ApiException) return l10n.errorGeneric;

  return switch (error) {
    ApiException(statusCode: null) => _byType(l10n, error),
    ApiException(code: 'outstanding_balance') => l10n.memberNotSettledTitle,
    ApiException(code: 'owner_must_transfer') => l10n.memberOwnerTitle,
    ApiException(statusCode: 401) => l10n.errorWrongCredentials,
    ApiException(statusCode: 403) => l10n.errorNotAllowed,
    ApiException(statusCode: 404) => l10n.errorNotFound,
    ApiException(statusCode: 409) => l10n.errorEmailTaken,
    ApiException(statusCode: 422) => l10n.errorInvalidData,
    _ => l10n.errorGeneric,
  };
}

/// Transport failures carry no status code, only a kind.
String _byType(AppLocalizations l10n, ApiException error) =>
    switch (error.kind) {
      ApiFailure.timeout => l10n.errorSlowConnection,
      ApiFailure.offline => l10n.errorNoConnection,
      _ => l10n.errorGeneric,
    };
