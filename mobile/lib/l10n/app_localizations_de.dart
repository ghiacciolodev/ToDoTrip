// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'TodoTrip';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonRemove => 'Entfernen';

  @override
  String get commonUndo => 'Rückgängig';

  @override
  String get commonTryAgain => 'Erneut versuchen';

  @override
  String get commonClear => 'Löschen';

  @override
  String get commonCopy => 'Kopieren';

  @override
  String get commonOk => 'OK';

  @override
  String get commonYou => 'Du';

  @override
  String get commonYouLower => 'dir';

  @override
  String get commonSomeone => 'Jemand';

  @override
  String get commonSomeoneLower => 'jemand';

  @override
  String get commonUnknown => 'Unbekannt';

  @override
  String get commonOwner => 'Inhaber';

  @override
  String get commonMember => 'Mitglied';

  @override
  String get commonComingSoon => 'Demnächst';

  @override
  String get errorGeneric =>
      'Etwas ist schiefgelaufen. Bitte erneut versuchen.';

  @override
  String get errorSlowConnection => 'Langsame Verbindung. Erneut versuchen.';

  @override
  String get errorNoConnection => 'Server nicht erreichbar.';

  @override
  String get errorInvalidData => 'Bitte prüfe deine Eingaben';

  @override
  String get errorWrongCredentials => 'E-Mail oder Passwort falsch';

  @override
  String get errorEmailTaken => 'Diese E-Mail ist bereits registriert';

  @override
  String get errorInvalidCode => 'Der Code ist ungültig oder abgelaufen';

  @override
  String get errorNoMapsApp => 'Keine Karten-App zum Öffnen vorhanden.';

  @override
  String get errorNotAllowed => 'Dazu hast du keine Berechtigung.';

  @override
  String get errorNotFound => 'Das gibt es nicht mehr.';

  @override
  String get authCreateAccount => 'Konto erstellen';

  @override
  String get authWelcomeBack => 'Willkommen zurück';

  @override
  String get authTagline => 'Reisen gemeinsam mit Freunden planen';

  @override
  String authPrivacyAccept(String policy) {
    return 'Ich habe die $policy gelesen und akzeptiere sie';
  }

  @override
  String get authPrivacyPolicyLink => 'Datenschutzerklärung';

  @override
  String get authPrivacyRequired =>
      'Sie müssen die Datenschutzerklärung akzeptieren, um ein Konto zu erstellen';

  @override
  String get authNameLabel => 'Name';

  @override
  String get authNameEmpty => 'Gib deinen Namen ein';

  @override
  String get authEmailLabel => 'E-Mail';

  @override
  String get authEmailEmpty => 'Gib deine E-Mail ein';

  @override
  String get authEmailInvalid => 'Gib eine gültige E-Mail ein';

  @override
  String get authPasswordLabel => 'Passwort';

  @override
  String get authPasswordEmpty => 'Gib dein Passwort ein';

  @override
  String get authPasswordTooShort => 'Mindestens 8 Zeichen';

  @override
  String get authShowPassword => 'Passwort anzeigen';

  @override
  String get authHidePassword => 'Passwort verbergen';

  @override
  String get authSignIn => 'Anmelden';

  @override
  String get authSignUp => 'Registrieren';

  @override
  String get authSwitchToSignIn => 'Schon ein Konto? Anmelden';

  @override
  String get authSwitchToSignUp => 'Noch kein Konto? Registrieren';

  @override
  String get navTrips => 'Reisen';

  @override
  String get navAdd => 'Neu';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get tripsTitle => 'Meine Reisen';

  @override
  String get tripsEmptyTitle => 'Noch keine Reisen';

  @override
  String get tripsEmptyBody =>
      'Erstelle deine erste Reise, oder tritt\neiner mit dem Code eines Freundes bei.';

  @override
  String get tripsEmptyAction => 'Los geht\'s';

  @override
  String get addTripTitle => 'Reise hinzufügen';

  @override
  String get addTripCreate => 'Reise erstellen';

  @override
  String get addTripCreateBody => 'Planen beginnen und Freunde einladen';

  @override
  String get addTripJoin => 'Mit Code beitreten';

  @override
  String get addTripJoinBody => 'Jemand hat dir einen Einladungscode geschickt';

  @override
  String get tripNewTitle => 'Neue Reise';

  @override
  String get tripNameLabel => 'Name der Reise';

  @override
  String get tripNameEmpty => 'Gib der Reise einen Namen';

  @override
  String get tripAddDates => 'Daten hinzufügen (optional)';

  @override
  String get tripClearDates => 'Daten entfernen';

  @override
  String get tripCreate => 'Reise erstellen';

  @override
  String get tripJoinTitle => 'Reise beitreten';

  @override
  String get tripJoinBody =>
      'Gib den Code ein, den dir ein Freund geschickt hat';

  @override
  String get tripJoinCodeEmpty => 'Gib den erhaltenen Code ein';

  @override
  String get tripJoin => 'Beitreten';

  @override
  String get tripNoDates => 'Keine Daten';

  @override
  String tripDatesFrom(String date) {
    return 'Ab $date';
  }

  @override
  String tripDatesUntil(String date) {
    return 'Bis $date';
  }

  @override
  String get tripFallbackName => 'Reise';

  @override
  String get tabCalendar => 'Kalender';

  @override
  String get tabTasks => 'Aufgaben';

  @override
  String get tabMoney => 'Geld';

  @override
  String get tabMap => 'Karte';

  @override
  String get tabGroup => 'Gruppe';

  @override
  String get fabEvent => 'Termin';

  @override
  String get fabTask => 'Aufgabe';

  @override
  String get fabList => 'Liste';

  @override
  String get fabExpense => 'Ausgabe';

  @override
  String get calendarEmptyTitle => 'Noch nichts geplant';

  @override
  String get calendarEmptyBody =>
      'Füge Flüge, Check-ins und\nalles mit Uhrzeit hinzu.';

  @override
  String get calendarToday => 'Heute';

  @override
  String get calendarTomorrow => 'Morgen';

  @override
  String get tasksViewTodo => 'To-do';

  @override
  String get tasksViewLists => 'Listen';

  @override
  String get tasksEmptyTitle => 'Nichts zu tun';

  @override
  String get tasksEmptyBody =>
      'Hostel buchen, Sonnencreme kaufen,\nFahren aufteilen.';

  @override
  String tasksCompletedCount(int count) {
    return '$count erledigt';
  }

  @override
  String tasksOverdue(String date) {
    return 'Überfällig · $date';
  }

  @override
  String tasksDueToday(String time) {
    return 'Heute, $time';
  }

  @override
  String tasksDueTomorrow(String time) {
    return 'Morgen, $time';
  }

  @override
  String get listsEmptyTitle => 'Noch keine Listen';

  @override
  String get listsEmptyBody =>
      'Einkaufsliste, Packliste,\nOrte zum Ausprobieren.';

  @override
  String get listEmpty => 'Leer';

  @override
  String get listAllDone => 'Alles erledigt';

  @override
  String listLeftOf(int left, int total) {
    return '$left von $total offen';
  }

  @override
  String listProgress(int checked, int total) {
    return '$checked von $total';
  }

  @override
  String get listTitle => 'Liste';

  @override
  String get listGoneTitle => 'Diese Liste gibt es nicht mehr';

  @override
  String get listGoneBody => 'Jemand aus der Gruppe hat sie gelöscht.';

  @override
  String get listEntriesEmptyTitle => 'Noch leer';

  @override
  String get listEntriesEmptyBody =>
      'Unten schreiben und + tippen.\nDas Feld bleibt für den nächsten Eintrag bereit.';

  @override
  String get listAddItem => 'Eintrag hinzufügen';

  @override
  String get itemNewEvent => 'Neuer Termin';

  @override
  String get itemNewTask => 'Neue Aufgabe';

  @override
  String get itemNewList => 'Neue Liste';

  @override
  String get itemEventLabel => 'Was passiert?';

  @override
  String get itemTaskLabel => 'Was ist zu tun?';

  @override
  String get itemListLabel => 'Wofür ist die Liste?';

  @override
  String get itemListHint => 'Einkaufen';

  @override
  String get itemPickDateTime => 'Datum und Uhrzeit wählen';

  @override
  String get itemAddDeadline => 'Frist hinzufügen (optional)';

  @override
  String get itemWhereOptional => 'Wo? (optional)';

  @override
  String get itemAssignTo => 'ZUWEISEN AN';

  @override
  String get itemAssignHint => 'Leer lassen, dann kann es jeder übernehmen.';

  @override
  String get itemAddEvent => 'Termin hinzufügen';

  @override
  String get itemAddTask => 'Aufgabe hinzufügen';

  @override
  String get itemAddList => 'Liste hinzufügen';

  @override
  String get moneyAllSettled => 'Alles ausgeglichen';

  @override
  String get moneyYouAreOwed => 'Du bekommst';

  @override
  String get moneyYouOwe => 'Du schuldest';

  @override
  String moneyTripTotal(String amount) {
    return 'Reise insgesamt $amount';
  }

  @override
  String get moneySettleUp => 'Ausgleichen';

  @override
  String get moneyEveryonesBalance => 'Salden aller';

  @override
  String get moneyEmptyTitle => 'Noch keine Ausgaben';

  @override
  String get moneyEmptyBody =>
      'Füge die erste hinzu, wir behalten\nden Überblick, wer wem was schuldet.';

  @override
  String moneyPaidBy(String name) {
    return 'Bezahlt von $name';
  }

  @override
  String moneyYourShare(String amount) {
    return 'dein Anteil: $amount';
  }

  @override
  String get moneyNotInvolved => 'nicht beteiligt';

  @override
  String get moneyRepayment => 'Rückzahlung';

  @override
  String moneyPaidSomeone(String payer, String payee) {
    return '$payer hat $payee bezahlt';
  }

  @override
  String get moneyToday => 'Heute';

  @override
  String get moneyYesterday => 'Gestern';

  @override
  String get expenseNewTitle => 'Neue Ausgabe';

  @override
  String get expenseWhatFor => 'Wofür?';

  @override
  String get expensePaidBy => 'BEZAHLT VON';

  @override
  String get expenseSplitBetween => 'GETEILT ZWISCHEN';

  @override
  String get expenseSplitEqually => 'Gleich aufteilen';

  @override
  String get expenseCustomAmounts => 'Eigene Beträge';

  @override
  String get expenseRemaining => 'Restbetrag';

  @override
  String get expenseSave => 'Ausgabe speichern';

  @override
  String get expenseSplitLabel => 'AUFTEILUNG';

  @override
  String get expenseDelete => 'Ausgabe löschen';

  @override
  String get expenseDeleting => 'Wird gelöscht…';

  @override
  String get expenseSuggestionExamples => 'Abendessen';

  @override
  String get expenseSuggestionGroceries => 'Einkauf';

  @override
  String get expenseSuggestionTaxi => 'Taxi';

  @override
  String get expenseSuggestionHotel => 'Hotel';

  @override
  String get expenseSuggestionDrinks => 'Getränke';

  @override
  String get settleTitle => 'Ausgleichen';

  @override
  String get settleBody => 'Der einfachste Weg, alles zu klären:';

  @override
  String get settleAllSquare => 'Alle sind quitt.';

  @override
  String settleSummary(int payments, int expenses) {
    String _temp0 = intl.Intl.pluralLogic(
      payments,
      locale: localeName,
      other: '$payments Zahlungen',
      one: '1 Zahlung',
    );
    return '$_temp0 statt $expenses';
  }

  @override
  String get settleMarkAsPaid => 'Als bezahlt markieren';

  @override
  String get settleUndoTitle => 'Rückzahlung widerrufen?';

  @override
  String get settleUndoBody =>
      'Die Salden aller kehren auf den Stand vor der Erfassung zurück.';

  @override
  String get settleUndoAction => 'Rückzahlung widerrufen';

  @override
  String get settleUndoing => 'Wird widerrufen…';

  @override
  String settleOnlySenderCanUndo(String name) {
    return 'Nur $name kann das widerrufen.';
  }

  @override
  String get settleRepaymentTitle => 'Rückzahlung';

  @override
  String groupPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen',
      one: '1 Person',
    );
    return '$_temp0';
  }

  @override
  String get groupInvitePeople => 'Leute einladen';

  @override
  String get groupDangerZone => 'Kritischer Bereich';

  @override
  String get groupDeleteTrip => 'Reise löschen';

  @override
  String get groupLeaveTrip => 'Reise verlassen';

  @override
  String groupJoined(String date) {
    return 'Dabei seit $date';
  }

  @override
  String get inviteTitle => 'Leute einladen';

  @override
  String get inviteBody =>
      'Teile einen Code und jeder kann dieser Reise beitreten.';

  @override
  String get inviteCreate => 'Einladungscode erstellen';

  @override
  String get inviteNewCode => 'Neuer Code';

  @override
  String get inviteNotUsedYet => 'Noch nicht verwendet';

  @override
  String inviteUsedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-mal verwendet',
      one: 'Einmal verwendet',
    );
    return '$_temp0';
  }

  @override
  String get inviteCodeCopied => 'Code kopiert';

  @override
  String get inviteRevoke => 'Diesen Code sperren';

  @override
  String get inviteCodeHint => 'ABCD1234';

  @override
  String get memberNoLongerHere => 'Diese Person ist nicht mehr dabei.';

  @override
  String get memberMakeOwner => 'Zum Inhaber machen';

  @override
  String get memberMakeOwnerDetail => 'Übernimmt die Reise, du wirst Mitglied.';

  @override
  String get memberRemove => 'Aus der Reise entfernen';

  @override
  String get memberRemoveDetail => 'Verliert sofort den Zugriff.';

  @override
  String get memberLeaveAndDelete => 'Verlassen und Reise löschen';

  @override
  String get memberLeaveBlocked =>
      'Du bist Inhaber. Mach zuerst jemand anderen zum Inhaber.';

  @override
  String get memberLeaveLastOne =>
      'Du bist der letzte, die Reise geht mit dir.';

  @override
  String get memberOwnerOnly => 'Nur der Inhaber kann Mitglieder verwalten.';

  @override
  String memberMakeOwnerTitle(String name) {
    return '$name zum Inhaber machen?';
  }

  @override
  String memberMakeOwnerBody(String name) {
    return '$name kann dann Leute einladen, Mitglieder entfernen und die Reise löschen. Du wirst ein normales Mitglied, und nur $name kann es zurückgeben.';
  }

  @override
  String memberRemoveTitle(String name) {
    return '$name entfernen?';
  }

  @override
  String get memberRemoveBody =>
      'Verliert sofort den Zugriff auf diese Reise. Das Hinzugefügte bleibt: Ausgaben, Aufgaben und die Salden aller anderen ändern sich nicht.';

  @override
  String get memberNotSettledTitle => 'Nicht ausgeglichen';

  @override
  String memberOwesAmount(String name, String amount) {
    return '$name schuldet $amount. Vor dem Entfernen ausgleichen.';
  }

  @override
  String memberIsOwedAmount(String name, String amount) {
    return '$name bekommt $amount. Vor dem Entfernen ausgleichen.';
  }

  @override
  String memberYouOweAmount(String amount) {
    return 'Du schuldest $amount. Vor dem Verlassen ausgleichen.';
  }

  @override
  String memberYouAreOwedAmount(String amount) {
    return 'Du bekommst $amount. Vor dem Verlassen ausgleichen.';
  }

  @override
  String get memberOwnerTitle => 'Du bist Inhaber';

  @override
  String get memberOwnerBody =>
      'Mach jemand anderen zum Inhaber, bevor du gehst, damit die Gruppe jemanden behält, der die Reise verwalten kann.';

  @override
  String memberLeaveTitle(String trip) {
    return '$trip verlassen?';
  }

  @override
  String get memberLeaveBody =>
      'Du verlierst den Zugriff auf Planung und Ausgaben. Was du hinzugefügt hast, bleibt bei der Gruppe.';

  @override
  String memberLeaveDeleteTitle(String trip) {
    return '$trip verlassen und löschen?';
  }

  @override
  String get memberLeaveDeleteBody =>
      'Du bist der letzte. Wenn du gehst, wird diese Reise mit allem gelöscht: Ausgaben, Kalender, Aufgaben und Listen. Das kann nicht rückgängig gemacht werden.';

  @override
  String get memberLeaveDeleteAction => 'Verlassen und löschen';

  @override
  String get memberLeaveAction => 'Verlassen';

  @override
  String tripDeleteTitle(String trip) {
    return '$trip löschen?';
  }

  @override
  String get tripDeleteBody =>
      'Das löscht endgültig die Planung, jede Ausgabe und die Salden aller. Es kann nicht rückgängig gemacht werden.';

  @override
  String deleteItemTitle(String title) {
    return '„$title“ löschen?';
  }

  @override
  String deleteListTitle(String name) {
    return '„$name“ löschen?';
  }

  @override
  String get deleteListEmptyBody => 'Die Liste wird für alle entfernt.';

  @override
  String deleteListBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ihre $count Einträge gehen für alle mit ihr.',
      one: 'Ihr Eintrag geht für alle mit ihr.',
    );
    return '$_temp0';
  }

  @override
  String deleteEntryTitle(String text) {
    return '„$text“ entfernen?';
  }

  @override
  String deleteExpenseTitle(String description) {
    return '„$description“ löschen?';
  }

  @override
  String get deleteExpenseBody => 'Die Salden aller werden neu berechnet.';

  @override
  String get deleteExpenseWithRepayments =>
      'In dieser Reise sind Rückzahlungen erfasst. Diese Ausgabe zu löschen ändert die Salden aller.';

  @override
  String get mapShareOn => 'Du teilst deinen Standort';

  @override
  String get mapShareOff => 'Standort teilen';

  @override
  String get mapShareForegroundOnly => 'Nur solange diese Karte offen ist.';

  @override
  String get mapServicesOff => 'Die Standortdienste sind auf diesem Gerät aus.';

  @override
  String get mapPermissionDenied => 'Standortberechtigung abgelehnt.';

  @override
  String get mapPermissionBlocked => 'Der Standort ist für TodoTrip gesperrt.';

  @override
  String get mapOpenSettings => 'Einstellungen öffnen';

  @override
  String get mapFitEveryone => 'Alle zeigen';

  @override
  String get mapCentreOnMe => 'Auf mich zentrieren';

  @override
  String get mapEmptyHint => 'Lange tippen, um eine Markierung zu setzen.';

  @override
  String get mapAttribution => 'OpenStreetMap-Mitwirkende';

  @override
  String get mapRightNow => 'Gerade jetzt';

  @override
  String mapMinutesAgo(int count) {
    return 'vor $count Minuten';
  }

  @override
  String mapLastSeen(String time) {
    return 'Zuletzt $time';
  }

  @override
  String get mapGetDirections => 'Route';

  @override
  String get mapAppleMaps => 'Apple Karten';

  @override
  String get mapGoogleMaps => 'Google Maps';

  @override
  String get pinNewTitle => 'Neue Markierung';

  @override
  String get pinNameLabel => 'Was ist hier?';

  @override
  String get pinNameHint => 'Hostel Lissabon';

  @override
  String get pinCategoryLabel => 'KATEGORIE';

  @override
  String get pinNotesLabel => 'Notizen (optional)';

  @override
  String get pinDrop => 'Markierung setzen';

  @override
  String get pinDelete => 'Markierung löschen';

  @override
  String pinDeleteTitle(String name) {
    return '„$name“ löschen?';
  }

  @override
  String get pinDeleteBody => 'Sie verschwindet für alle von der Karte.';

  @override
  String pinAddedBy(String name, String date) {
    return 'Von $name · $date';
  }

  @override
  String get pinCategoryLodging => 'Unterkunft';

  @override
  String get pinCategoryFood => 'Essen';

  @override
  String get pinCategoryMeetingPoint => 'Treffpunkt';

  @override
  String get pinCategoryParking => 'Parken';

  @override
  String get pinCategorySight => 'Sehenswürdigkeit';

  @override
  String get pinCategoryOther => 'Sonstiges';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsNotifications => 'Benachrichtigungen';

  @override
  String get settingsPushNotifications => 'Push-Benachrichtigungen';

  @override
  String get settingsPushNotificationsBody => 'Reise-Updates und neue Aufgaben';

  @override
  String get settingsExpenseAlerts => 'Ausgaben-Hinweise';

  @override
  String get settingsExpenseAlertsBody => 'Wenn jemand eine Ausgabe hinzufügt';

  @override
  String get settingsPreferences => 'Präferenzen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsDefaultCurrency => 'Standardwährung';

  @override
  String get settingsDefaultCurrencyHint =>
      'Wird bei neuen Reisen verwendet. Bestehende Reisen behalten ihre.';

  @override
  String get settingsAbout => 'Info';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Datenschutzerklärung';

  @override
  String get settingsSignOut => 'Abmelden';

  @override
  String get settingsSignOutTitle => 'Abmelden?';

  @override
  String get settingsSignOutBody =>
      'Zum Zurückkommen brauchst du E-Mail und Passwort.';

  @override
  String get tripStageNow => 'Läuft';

  @override
  String tripStageDayOf(int day, int total) {
    return 'Tag $day von $total';
  }

  @override
  String get tripStageToday => 'Beginnt heute';

  @override
  String get tripStageTomorrow => 'Morgen';

  @override
  String tripStageInDays(int days) {
    return 'In $days Tagen';
  }

  @override
  String get tripStageEnded => 'Beendet';

  @override
  String get moneySettledShort => 'Ausgeglichen';

  @override
  String get commonJustNow => 'Gerade eben';

  @override
  String commonMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Minuten',
      one: 'vor 1 Minute',
    );
    return '$_temp0';
  }

  @override
  String commonHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Stunden',
      one: 'vor 1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String commonDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get tripIconLabel => 'Symbol';

  @override
  String get tripColorLabel => 'Farbe';

  @override
  String get tripAddDescription => 'Beschreibung hinzufügen';

  @override
  String get tripDescriptionLabel => 'Beschreibung';

  @override
  String get commonSave => 'Speichern';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsAccentColour => 'Akzentfarbe';

  @override
  String get settingsAccentColourBody =>
      'Für Schaltflächen, Hervorhebungen und die Tab-Leiste.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSaved => 'Profil aktualisiert';

  @override
  String get profileEmailLocked =>
      'Für eine neue E-Mail-Adresse müsste diese bestätigt werden, was noch nicht möglich ist.';

  @override
  String get profileChangePassword => 'Passwort ändern';

  @override
  String get profileChangePasswordBody => 'Meldet dich überall sonst ab';

  @override
  String get profileChangePasswordWarning =>
      'Alle anderen Geräte, die bei diesem Konto angemeldet sind, werden abgemeldet.';

  @override
  String get profileCurrentPassword => 'Aktuelles Passwort';

  @override
  String get profileNewPassword => 'Neues Passwort';

  @override
  String get profileRepeatPassword => 'Neues Passwort wiederholen';

  @override
  String get profilePasswordMismatch =>
      'Die beiden Passwörter stimmen nicht überein';

  @override
  String get profileWrongPassword => 'Das ist nicht dein aktuelles Passwort';

  @override
  String get profilePasswordChanged => 'Passwort geändert';

  @override
  String get profileDeleteAccount => 'Konto löschen';

  @override
  String get profileDeleteTitle => 'Konto löschen?';

  @override
  String get profileDeleteBody =>
      'Name, E-Mail und Passwort werden gelöscht und du wirst überall abgemeldet. Ausgaben, an denen du beteiligt warst, bleiben ohne deinen Namen bestehen, weil sie bestimmen, was die anderen schulden. Das lässt sich nicht rückgängig machen.';

  @override
  String get profileDeleteConfirm => 'Löschen';

  @override
  String get profileDeleteOwnsTrips =>
      'Dir gehört noch eine Reise, in der andere Personen sind. Übergib sie jemandem oder lösche sie und versuche es erneut.';

  @override
  String get tripSettingsTitle => 'Reise-Einstellungen';

  @override
  String get tripSettingsEdit => 'Bearbeiten';

  @override
  String get tripSettingsInfo => 'Informationen';

  @override
  String get tripSettingsPersonal => 'Nur für dich';

  @override
  String get tripSettingsDanger => 'Gefahrenzone';

  @override
  String get tripCurrencyLabel => 'Währung';

  @override
  String get tripCurrencyWarning =>
      'Ein Währungswechsel rechnet bestehende Ausgaben nicht um. Die Beträge bleiben gleich, nur das Symbol ändert sich.';

  @override
  String get tripSaveChanges => 'Änderungen speichern';

  @override
  String get tripSaved => 'Reise aktualisiert';

  @override
  String tripCreatedByOn(String name, String date) {
    return 'Erstellt von $name am $date';
  }

  @override
  String tripStatMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder',
      one: '1 Mitglied',
    );
    return '$_temp0';
  }

  @override
  String tripStatExpenses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ausgaben',
      one: '1 Ausgabe',
    );
    return '$_temp0';
  }

  @override
  String tripStatItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Programmpunkte',
      one: '1 Programmpunkt',
    );
    return '$_temp0';
  }

  @override
  String get tripTotalSpent => 'Gesamt ausgegeben';

  @override
  String get tripExportCsv => 'Ausgaben als CSV exportieren';

  @override
  String get tripExportEmpty => 'Es gibt noch keine Ausgaben zum Exportieren.';

  @override
  String tripExportShareText(String trip) {
    return '$trip — Ausgaben';
  }

  @override
  String get tripMuteLabel => 'Diese Reise stummschalten';

  @override
  String get tripMuteBody => 'Keine Benachrichtigungen mehr dazu';

  @override
  String get tripArchive => 'Reise archivieren';

  @override
  String get tripArchiveBody =>
      'Nimmt sie aus deiner Liste. Alle lesen sie weiter, niemand kann etwas hinzufügen.';

  @override
  String get tripArchiveTitle => 'Diese Reise archivieren?';

  @override
  String get tripUnarchive => 'Aus dem Archiv holen';

  @override
  String get tripArchivedBanner =>
      'Diese Reise ist archiviert. Es lässt sich nichts mehr hinzufügen.';

  @override
  String get tripsArchivedTitle => 'Archiviert';

  @override
  String tripsArchivedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivierte Reisen',
      one: '1 archivierte Reise',
    );
    return '$_temp0';
  }

  @override
  String get tripsArchivedEmpty => 'Noch nichts archiviert.';

  @override
  String get tripUnsavedChanges => 'Es gibt ungespeicherte Änderungen';

  @override
  String get calendarYesterday => 'Gestern';

  @override
  String get calendarStartsNow => 'Jetzt';

  @override
  String calendarStartsInMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count Min',
      one: 'in 1 Min',
    );
    return '$_temp0';
  }

  @override
  String calendarStartsInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count Stunden',
      one: 'in 1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get notificationsMarkAllRead => 'Alle als gelesen markieren';

  @override
  String get notificationsEmptyTitle => 'Alles gelesen';

  @override
  String get notificationsEmptyBody =>
      'Neue Ausgaben, Pläne und Personen\nerscheinen hier.';

  @override
  String notificationExpenseAdded(
    String actor,
    String amount,
    String description,
  ) {
    return '$actor hat $amount für $description hinzugefügt';
  }

  @override
  String notificationExpenseDeleted(String actor, String description) {
    return '$actor hat die Ausgabe für $description gelöscht';
  }

  @override
  String notificationSettlement(String actor, String amount) {
    return '$actor hat dir $amount zurückgezahlt';
  }

  @override
  String notificationTaskAssigned(String actor, String title) {
    return '$actor hat dir „$title“ gegeben';
  }

  @override
  String notificationEventAdded(String actor, String title) {
    return '$actor hat $title zum Programm hinzugefügt';
  }

  @override
  String notificationMemberJoined(String actor) {
    return '$actor ist der Reise beigetreten';
  }

  @override
  String notificationSomethingHappened(String actor) {
    return '$actor hat etwas in dieser Reise getan';
  }

  @override
  String get settingsMuteTrip => 'Diese Reise stummschalten';

  @override
  String get settingsMuteTripBody => 'Keine Benachrichtigungen mehr dazu';

  @override
  String get notificationsClearAll => 'Alle löschen';

  @override
  String get notificationsClearAllTitle => 'Alle Benachrichtigungen löschen?';

  @override
  String get notificationsClearAllBody =>
      'Sie verschwinden nur für dich. Das lässt sich nicht rückgängig machen.';

  @override
  String get notificationDeleteTitle => 'Diese Benachrichtigung löschen?';

  @override
  String get notificationDeleteBody =>
      'Sie verschwindet nur für dich. Worum es ging, bleibt bestehen.';

  @override
  String get onboardSkip => 'Überspringen';

  @override
  String get onboardNext => 'Weiter';

  @override
  String get onboardStart => 'Los geht\'s';

  @override
  String get onboardTripsTitle => 'Ein Ort pro Reise';

  @override
  String get onboardTripsBody =>
      'Reise anlegen, Code teilen — und alle landen im selben Plan.';

  @override
  String get onboardPlanTitle => 'Alles, was eine Uhrzeit hat';

  @override
  String get onboardPlanBody =>
      'Flüge, Check-ins, die Bahn um neun. Dazu die Aufgaben, bei denen niemand mehr weiß, wer sie übernommen hat.';

  @override
  String get onboardMoneyTitle => 'Wer wem was schuldet';

  @override
  String get onboardMoneyBody =>
      'Ausgaben eintragen, während sie entstehen. Die Salden ergeben sich von selbst, auf den Cent genau.';

  @override
  String get onboardTogetherTitle => 'Und wo alle sind';

  @override
  String get onboardTogetherBody =>
      'Speichert die Orte, auf die ihr euch geeinigt habt, und teilt euren Standort, solange ihr wollt. Nie von allein.';
}
