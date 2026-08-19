// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'TodoTrip';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonDelete => 'Elimina';

  @override
  String get commonRemove => 'Rimuovi';

  @override
  String get commonUndo => 'Annulla';

  @override
  String get commonTryAgain => 'Riprova';

  @override
  String get commonClear => 'Cancella';

  @override
  String get commonCopy => 'Copia';

  @override
  String get commonOk => 'OK';

  @override
  String get commonYou => 'Tu';

  @override
  String get commonYouLower => 'te';

  @override
  String get commonSomeone => 'Qualcuno';

  @override
  String get commonSomeoneLower => 'qualcuno';

  @override
  String get commonUnknown => 'Sconosciuto';

  @override
  String get commonOwner => 'Proprietario';

  @override
  String get commonMember => 'Membro';

  @override
  String get commonComingSoon => 'In arrivo';

  @override
  String get errorGeneric => 'Qualcosa è andato storto. Riprova.';

  @override
  String get errorSlowConnection => 'Connessione lenta. Riprova.';

  @override
  String get errorNoConnection => 'Impossibile raggiungere il server.';

  @override
  String get errorInvalidData => 'Controlla i dati che hai inserito';

  @override
  String get errorWrongCredentials => 'Email o password non corretti';

  @override
  String get errorEmailTaken => 'Questa email è già registrata';

  @override
  String get errorInvalidCode => 'Il codice non è valido o è scaduto';

  @override
  String get errorNoMapsApp => 'Nessuna app di mappe per aprirlo.';

  @override
  String get errorNotAllowed => 'Non hai i permessi per farlo.';

  @override
  String get errorNotFound => 'Non c\'è più.';

  @override
  String get authCreateAccount => 'Crea il tuo account';

  @override
  String get authWelcomeBack => 'Bentornato';

  @override
  String get authTagline => 'Organizza i viaggi con i tuoi amici';

  @override
  String authPrivacyAccept(String policy) {
    return 'Ho letto e accetto la $policy';
  }

  @override
  String get authPrivacyPolicyLink => 'informativa sulla privacy';

  @override
  String get authPrivacyRequired =>
      'Devi accettare l\'informativa sulla privacy per creare un account';

  @override
  String get authNameLabel => 'Nome';

  @override
  String get authNameEmpty => 'Inserisci il tuo nome';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailEmpty => 'Inserisci la tua email';

  @override
  String get authEmailInvalid => 'Inserisci un\'email valida';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordEmpty => 'Inserisci la tua password';

  @override
  String get authPasswordTooShort => 'Almeno 8 caratteri';

  @override
  String get authShowPassword => 'Mostra password';

  @override
  String get authHidePassword => 'Nascondi password';

  @override
  String get authSignIn => 'Accedi';

  @override
  String get authSignUp => 'Registrati';

  @override
  String get authSwitchToSignIn => 'Hai già un account? Accedi';

  @override
  String get authSwitchToSignUp => 'Non hai un account? Registrati';

  @override
  String get navTrips => 'Viaggi';

  @override
  String get navAdd => 'Aggiungi';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get tripsTitle => 'I miei viaggi';

  @override
  String get tripsEmptyTitle => 'Nessun viaggio';

  @override
  String get tripsEmptyBody =>
      'Crea il tuo primo viaggio, o entra\nin uno col codice di un amico.';

  @override
  String get tripsEmptyAction => 'Inizia';

  @override
  String get addTripTitle => 'Aggiungi un viaggio';

  @override
  String get addTripCreate => 'Crea un viaggio';

  @override
  String get addTripCreateBody => 'Inizia a organizzare e invita gli amici';

  @override
  String get addTripJoin => 'Entra con un codice';

  @override
  String get addTripJoinBody => 'Qualcuno ti ha condiviso un codice invito';

  @override
  String get tripNewTitle => 'Nuovo viaggio';

  @override
  String get tripNameLabel => 'Nome del viaggio';

  @override
  String get tripNameEmpty => 'Dai un nome al viaggio';

  @override
  String get tripAddDates => 'Aggiungi le date (opzionale)';

  @override
  String get tripClearDates => 'Cancella le date';

  @override
  String get tripCreate => 'Crea viaggio';

  @override
  String get tripJoinTitle => 'Entra in un viaggio';

  @override
  String get tripJoinBody => 'Inserisci il codice che ti ha dato un amico';

  @override
  String get tripJoinCodeEmpty => 'Inserisci il codice che ti è stato dato';

  @override
  String get tripJoin => 'Entra';

  @override
  String get tripNoDates => 'Nessuna data';

  @override
  String tripDatesFrom(String date) {
    return 'Dal $date';
  }

  @override
  String tripDatesUntil(String date) {
    return 'Fino al $date';
  }

  @override
  String get tripFallbackName => 'Viaggio';

  @override
  String get tabCalendar => 'Calendario';

  @override
  String get tabTasks => 'Attività';

  @override
  String get tabMoney => 'Spese';

  @override
  String get tabMap => 'Mappa';

  @override
  String get tabGroup => 'Gruppo';

  @override
  String get fabEvent => 'Evento';

  @override
  String get fabTask => 'Attività';

  @override
  String get fabList => 'Lista';

  @override
  String get fabExpense => 'Spesa';

  @override
  String get calendarEmptyTitle => 'Niente in programma';

  @override
  String get calendarEmptyBody =>
      'Aggiungi voli, check-in e\ntutto ciò che ha un orario.';

  @override
  String get calendarToday => 'Oggi';

  @override
  String get calendarTomorrow => 'Domani';

  @override
  String get tasksViewTodo => 'Da fare';

  @override
  String get tasksViewLists => 'Liste';

  @override
  String get tasksEmptyTitle => 'Niente da fare';

  @override
  String get tasksEmptyBody =>
      'Prenotare l\'ostello, comprare la crema,\ndividersi la guida.';

  @override
  String tasksCompletedCount(int count) {
    return '$count completate';
  }

  @override
  String tasksOverdue(String date) {
    return 'In ritardo · $date';
  }

  @override
  String tasksDueToday(String time) {
    return 'Oggi, $time';
  }

  @override
  String tasksDueTomorrow(String time) {
    return 'Domani, $time';
  }

  @override
  String get listsEmptyTitle => 'Nessuna lista';

  @override
  String get listsEmptyBody =>
      'La spesa, cosa mettere in valigia,\nposti da provare.';

  @override
  String get listEmpty => 'Vuota';

  @override
  String get listAllDone => 'Tutto fatto';

  @override
  String listLeftOf(int left, int total) {
    return '$left da prendere su $total';
  }

  @override
  String listProgress(int checked, int total) {
    return '$checked di $total';
  }

  @override
  String get listTitle => 'Lista';

  @override
  String get listGoneTitle => 'Questa lista non c\'è più';

  @override
  String get listGoneBody => 'Qualcuno del gruppo l\'ha eliminata.';

  @override
  String get listEntriesEmptyTitle => 'Ancora vuota';

  @override
  String get listEntriesEmptyBody =>
      'Scrivi qui sotto e tocca +.\nIl campo resta pronto per la prossima.';

  @override
  String get listAddItem => 'Aggiungi una voce';

  @override
  String get itemNewEvent => 'Nuovo evento';

  @override
  String get itemNewTask => 'Nuova attività';

  @override
  String get itemNewList => 'Nuova lista';

  @override
  String get itemEventLabel => 'Cosa succede?';

  @override
  String get itemTaskLabel => 'Cosa c\'è da fare?';

  @override
  String get itemListLabel => 'A cosa serve la lista?';

  @override
  String get itemListHint => 'Spesa';

  @override
  String get itemPickDateTime => 'Scegli data e ora';

  @override
  String get itemAddDeadline => 'Aggiungi una scadenza (opzionale)';

  @override
  String get itemWhereOptional => 'Dove? (opzionale)';

  @override
  String get itemAssignTo => 'ASSEGNA A';

  @override
  String get itemAssignHint => 'Lascia vuoto e può farlo chiunque.';

  @override
  String get itemAddEvent => 'Aggiungi evento';

  @override
  String get itemAddTask => 'Aggiungi attività';

  @override
  String get itemAddList => 'Aggiungi lista';

  @override
  String get moneyAllSettled => 'Tutto in pari';

  @override
  String get moneyYouAreOwed => 'Ti devono';

  @override
  String get moneyYouOwe => 'Devi';

  @override
  String moneyTripTotal(String amount) {
    return 'Totale del viaggio $amount';
  }

  @override
  String get moneySettleUp => 'Salda i conti';

  @override
  String get moneyEveryonesBalance => 'I saldi di tutti';

  @override
  String get moneyEmptyTitle => 'Nessuna spesa';

  @override
  String get moneyEmptyBody =>
      'Aggiungi la prima e teniamo\nnoi il conto di chi deve cosa.';

  @override
  String moneyPaidBy(String name) {
    return 'Pagato da $name';
  }

  @override
  String moneyYourShare(String amount) {
    return 'tua parte: $amount';
  }

  @override
  String get moneyNotInvolved => 'non partecipi';

  @override
  String get moneyRepayment => 'Rimborso';

  @override
  String moneyPaidSomeone(String payer, String payee) {
    return '$payer ha pagato $payee';
  }

  @override
  String get moneyToday => 'Oggi';

  @override
  String get moneyYesterday => 'Ieri';

  @override
  String get expenseNewTitle => 'Nuova spesa';

  @override
  String get expenseWhatFor => 'Per cosa?';

  @override
  String get expensePaidBy => 'PAGATO DA';

  @override
  String get expenseSplitBetween => 'DIVISO TRA';

  @override
  String get expenseSplitEqually => 'Dividi in parti uguali';

  @override
  String get expenseCustomAmounts => 'Importi personalizzati';

  @override
  String get expenseRemaining => 'Rimanente';

  @override
  String get expenseSave => 'Salva spesa';

  @override
  String get expenseSplitLabel => 'DIVISIONE';

  @override
  String get expenseDelete => 'Elimina spesa';

  @override
  String get expenseDeleting => 'Eliminazione…';

  @override
  String get expenseSuggestionExamples => 'Cena';

  @override
  String get expenseSuggestionGroceries => 'Spesa';

  @override
  String get expenseSuggestionTaxi => 'Taxi';

  @override
  String get expenseSuggestionHotel => 'Hotel';

  @override
  String get expenseSuggestionDrinks => 'Bevute';

  @override
  String get settleTitle => 'Salda i conti';

  @override
  String get settleBody => 'Il modo più semplice per sistemare tutto:';

  @override
  String get settleAllSquare => 'Siete tutti in pari.';

  @override
  String settleSummary(int payments, int expenses) {
    String _temp0 = intl.Intl.pluralLogic(
      payments,
      locale: localeName,
      other: '$payments pagamenti',
      one: '1 pagamento',
    );
    return '$_temp0 invece di $expenses';
  }

  @override
  String get settleMarkAsPaid => 'Segna come pagato';

  @override
  String get settleUndoTitle => 'Annullare questo rimborso?';

  @override
  String get settleUndoBody =>
      'I saldi di tutti tornano come erano prima che venisse registrato.';

  @override
  String get settleUndoAction => 'Annulla questo rimborso';

  @override
  String get settleUndoing => 'Annullamento…';

  @override
  String settleOnlySenderCanUndo(String name) {
    return 'Solo $name può annullarlo.';
  }

  @override
  String get settleRepaymentTitle => 'Rimborso';

  @override
  String groupPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count persone',
      one: '1 persona',
    );
    return '$_temp0';
  }

  @override
  String get groupInvitePeople => 'Invita persone';

  @override
  String get groupDangerZone => 'Zona pericolosa';

  @override
  String get groupDeleteTrip => 'Elimina viaggio';

  @override
  String get groupLeaveTrip => 'Esci dal viaggio';

  @override
  String groupJoined(String date) {
    return 'Entrato il $date';
  }

  @override
  String get inviteTitle => 'Invita persone';

  @override
  String get inviteBody =>
      'Condividi un codice e chiunque può entrare in questo viaggio.';

  @override
  String get inviteCreate => 'Crea un codice invito';

  @override
  String get inviteNewCode => 'Nuovo codice';

  @override
  String get inviteNotUsedYet => 'Non ancora usato';

  @override
  String inviteUsedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usato $count volte',
      one: 'Usato una volta',
    );
    return '$_temp0';
  }

  @override
  String get inviteCodeCopied => 'Codice copiato';

  @override
  String get inviteRevoke => 'Revoca questo codice';

  @override
  String get inviteCodeHint => 'ABCD1234';

  @override
  String get memberNoLongerHere => 'Questa persona non è più nel viaggio.';

  @override
  String get memberMakeOwner => 'Rendi proprietario';

  @override
  String get memberMakeOwnerDetail =>
      'Prende il viaggio, tu diventi un membro.';

  @override
  String get memberRemove => 'Rimuovi dal viaggio';

  @override
  String get memberRemoveDetail => 'Perde l\'accesso immediatamente.';

  @override
  String get memberLeaveAndDelete => 'Esci ed elimina il viaggio';

  @override
  String get memberLeaveBlocked =>
      'Sei il proprietario. Prima rendi proprietario qualcun altro.';

  @override
  String get memberLeaveLastOne =>
      'Sei l\'ultimo rimasto, quindi il viaggio se ne va con te.';

  @override
  String get memberOwnerOnly => 'Solo il proprietario può gestire i membri.';

  @override
  String memberMakeOwnerTitle(String name) {
    return 'Rendere $name proprietario?';
  }

  @override
  String memberMakeOwnerBody(String name) {
    return '$name potrà invitare persone, rimuovere membri ed eliminare il viaggio. Tu diventi un membro normale, e solo $name potrà restituirtelo.';
  }

  @override
  String memberRemoveTitle(String name) {
    return 'Rimuovere $name?';
  }

  @override
  String get memberRemoveBody =>
      'Perde subito l\'accesso a questo viaggio. Ciò che ha aggiunto resta: spese, attività e i saldi di tutti gli altri non cambiano.';

  @override
  String get memberNotSettledTitle => 'Conti non in pari';

  @override
  String memberOwesAmount(String name, String amount) {
    return '$name deve $amount. Saldate prima di rimuoverlo.';
  }

  @override
  String memberIsOwedAmount(String name, String amount) {
    return 'A $name devono $amount. Saldate prima di rimuoverlo.';
  }

  @override
  String memberYouOweAmount(String amount) {
    return 'Devi $amount. Salda prima di uscire.';
  }

  @override
  String memberYouAreOwedAmount(String amount) {
    return 'Ti devono $amount. Saldate prima che tu esca.';
  }

  @override
  String get memberOwnerTitle => 'Sei il proprietario';

  @override
  String get memberOwnerBody =>
      'Rendi proprietario qualcun altro prima di uscire, così il gruppo resta con qualcuno che può gestire il viaggio.';

  @override
  String memberLeaveTitle(String trip) {
    return 'Uscire da $trip?';
  }

  @override
  String get memberLeaveBody =>
      'Perderai l\'accesso al programma e alle spese. Quello che hai aggiunto resta al gruppo.';

  @override
  String memberLeaveDeleteTitle(String trip) {
    return 'Uscire ed eliminare $trip?';
  }

  @override
  String get memberLeaveDeleteBody =>
      'Sei l\'ultimo rimasto. Uscendo, questo viaggio viene eliminato con tutto quello che contiene: spese, calendario, attività e liste. Non è reversibile.';

  @override
  String get memberLeaveDeleteAction => 'Esci ed elimina';

  @override
  String get memberLeaveAction => 'Esci';

  @override
  String tripDeleteTitle(String trip) {
    return 'Eliminare $trip?';
  }

  @override
  String get tripDeleteBody =>
      'Questo elimina per sempre il programma, ogni spesa e i saldi di tutti. Non è reversibile.';

  @override
  String deleteItemTitle(String title) {
    return 'Eliminare \"$title\"?';
  }

  @override
  String deleteListTitle(String name) {
    return 'Eliminare \"$name\"?';
  }

  @override
  String get deleteListEmptyBody => 'La lista viene rimossa per tutti.';

  @override
  String deleteListBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Le sue $count voci se ne vanno con lei, per tutti.',
      one: 'La sua voce se ne va con lei, per tutti.',
    );
    return '$_temp0';
  }

  @override
  String deleteEntryTitle(String text) {
    return 'Rimuovere \"$text\"?';
  }

  @override
  String deleteExpenseTitle(String description) {
    return 'Eliminare \"$description\"?';
  }

  @override
  String get deleteExpenseBody => 'I saldi di tutti verranno ricalcolati.';

  @override
  String get deleteExpenseWithRepayments =>
      'In questo viaggio ci sono rimborsi registrati. Eliminando questa spesa cambieranno i saldi di tutti.';

  @override
  String get mapShareOn => 'Stai condividendo la tua posizione';

  @override
  String get mapShareOff => 'Condividi la mia posizione';

  @override
  String get mapShareForegroundOnly => 'Solo mentre questa mappa è aperta.';

  @override
  String get mapServicesOff =>
      'La posizione è disattivata su questo dispositivo.';

  @override
  String get mapPermissionDenied => 'Permesso di posizione negato.';

  @override
  String get mapPermissionBlocked => 'La posizione è bloccata per TodoTrip.';

  @override
  String get mapOpenSettings => 'Apri impostazioni';

  @override
  String get mapFitEveryone => 'Inquadra tutti';

  @override
  String get mapCentreOnMe => 'Centra su di me';

  @override
  String get mapEmptyHint =>
      'Tieni premuto sulla mappa per lasciare un segnaposto.';

  @override
  String get mapAttribution => 'contributori di OpenStreetMap';

  @override
  String get mapRightNow => 'Adesso';

  @override
  String mapMinutesAgo(int count) {
    return '$count minuti fa';
  }

  @override
  String mapLastSeen(String time) {
    return 'Visto alle $time';
  }

  @override
  String get mapGetDirections => 'Indicazioni';

  @override
  String get mapAppleMaps => 'Apple Maps';

  @override
  String get mapGoogleMaps => 'Google Maps';

  @override
  String get pinNewTitle => 'Nuovo segnaposto';

  @override
  String get pinNameLabel => 'Cosa c\'è qui?';

  @override
  String get pinNameHint => 'Ostello Lisbona';

  @override
  String get pinCategoryLabel => 'CATEGORIA';

  @override
  String get pinNotesLabel => 'Note (opzionale)';

  @override
  String get pinDrop => 'Lascia il segnaposto';

  @override
  String get pinDelete => 'Elimina segnaposto';

  @override
  String pinDeleteTitle(String name) {
    return 'Eliminare \"$name\"?';
  }

  @override
  String get pinDeleteBody => 'Sparisce dalla mappa per tutti.';

  @override
  String pinAddedBy(String name, String date) {
    return 'Aggiunto da $name · $date';
  }

  @override
  String get pinCategoryLodging => 'Alloggio';

  @override
  String get pinCategoryFood => 'Cibo';

  @override
  String get pinCategoryMeetingPoint => 'Punto d\'incontro';

  @override
  String get pinCategoryParking => 'Parcheggio';

  @override
  String get pinCategorySight => 'Da vedere';

  @override
  String get pinCategoryOther => 'Altro';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsNotifications => 'Notifiche';

  @override
  String get settingsPushNotifications => 'Notifiche push';

  @override
  String get settingsPushNotificationsBody =>
      'Aggiornamenti del viaggio e nuove attività';

  @override
  String get settingsExpenseAlerts => 'Avvisi sulle spese';

  @override
  String get settingsExpenseAlertsBody => 'Quando qualcuno aggiunge una spesa';

  @override
  String get settingsPreferences => 'Preferenze';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get settingsDefaultCurrency => 'Valuta predefinita';

  @override
  String get settingsDefaultCurrencyHint =>
      'Usata quando crei un viaggio. I viaggi esistenti mantengono la loro.';

  @override
  String get settingsAbout => 'Info';

  @override
  String get settingsVersion => 'Versione';

  @override
  String get settingsPrivacyPolicy => 'Informativa sulla privacy';

  @override
  String get settingsSignOut => 'Esci';

  @override
  String get settingsSignOutTitle => 'Uscire?';

  @override
  String get settingsSignOutBody =>
      'Ti serviranno email e password per rientrare.';

  @override
  String get tripStageNow => 'In corso';

  @override
  String tripStageDayOf(int day, int total) {
    return 'Giorno $day di $total';
  }

  @override
  String get tripStageToday => 'Parte oggi';

  @override
  String get tripStageTomorrow => 'Domani';

  @override
  String tripStageInDays(int days) {
    return 'Tra $days giorni';
  }

  @override
  String get tripStageEnded => 'Concluso';

  @override
  String get moneySettledShort => 'In pari';

  @override
  String get commonJustNow => 'Adesso';

  @override
  String commonMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuti fa',
      one: '1 minuto fa',
    );
    return '$_temp0';
  }

  @override
  String commonHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ore fa',
      one: '1 ora fa',
    );
    return '$_temp0';
  }

  @override
  String commonDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni fa',
      one: '1 giorno fa',
    );
    return '$_temp0';
  }

  @override
  String get tripIconLabel => 'Icona';

  @override
  String get tripColorLabel => 'Colore';

  @override
  String get tripAddDescription => 'Aggiungi una descrizione';

  @override
  String get tripDescriptionLabel => 'Descrizione';

  @override
  String get commonSave => 'Salva';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get settingsAccentColour => 'Colore principale';

  @override
  String get settingsAccentColourBody =>
      'Usato per i pulsanti, gli elementi in evidenza e la barra delle schede.';

  @override
  String get profileTitle => 'Profilo';

  @override
  String get profileSaved => 'Profilo aggiornato';

  @override
  String get profileEmailLocked =>
      'Cambiare email richiede di verificare il nuovo indirizzo, cosa non ancora disponibile.';

  @override
  String get profileChangePassword => 'Cambia password';

  @override
  String get profileChangePasswordBody =>
      'Disconnette tutti gli altri dispositivi';

  @override
  String get profileChangePasswordWarning =>
      'Ogni altro dispositivo collegato a questo account verrà disconnesso.';

  @override
  String get profileCurrentPassword => 'Password attuale';

  @override
  String get profileNewPassword => 'Nuova password';

  @override
  String get profileRepeatPassword => 'Ripeti la nuova password';

  @override
  String get profilePasswordMismatch => 'Le due password non coincidono';

  @override
  String get profileWrongPassword => 'Non è la tua password attuale';

  @override
  String get profilePasswordChanged => 'Password cambiata';

  @override
  String get profileDeleteAccount => 'Elimina account';

  @override
  String get profileDeleteTitle => 'Eliminare il tuo account?';

  @override
  String get profileDeleteBody =>
      'Nome, email e password vengono cancellati e verrai disconnesso ovunque. Le spese a cui hai partecipato restano, senza il tuo nome, perché determinano quanto devono gli altri. Non è reversibile.';

  @override
  String get profileDeleteConfirm => 'Elimina';

  @override
  String get profileDeleteOwnsTrips =>
      'Sei ancora proprietario di un viaggio in cui ci sono altre persone. Passalo a qualcun altro, oppure eliminalo, e riprova.';

  @override
  String get tripSettingsTitle => 'Impostazioni del viaggio';

  @override
  String get tripSettingsEdit => 'Modifica';

  @override
  String get tripSettingsInfo => 'Informazioni';

  @override
  String get tripSettingsPersonal => 'Solo per te';

  @override
  String get tripSettingsDanger => 'Zona pericolo';

  @override
  String get tripCurrencyLabel => 'Valuta';

  @override
  String get tripCurrencyWarning =>
      'Cambiare valuta non converte le spese già inserite. Gli importi restano gli stessi, cambia solo il simbolo.';

  @override
  String get tripSaveChanges => 'Salva le modifiche';

  @override
  String get tripSaved => 'Viaggio aggiornato';

  @override
  String tripCreatedByOn(String name, String date) {
    return 'Creato da $name il $date';
  }

  @override
  String tripStatMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membri',
      one: '1 membro',
    );
    return '$_temp0';
  }

  @override
  String tripStatExpenses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spese',
      one: '1 spesa',
    );
    return '$_temp0';
  }

  @override
  String tripStatItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voci del piano',
      one: '1 voce del piano',
    );
    return '$_temp0';
  }

  @override
  String get tripTotalSpent => 'Totale speso';

  @override
  String get tripExportCsv => 'Esporta le spese in CSV';

  @override
  String get tripExportEmpty => 'Non ci sono ancora spese da esportare.';

  @override
  String tripExportShareText(String trip) {
    return '$trip — spese';
  }

  @override
  String get tripMuteLabel => 'Silenzia questo viaggio';

  @override
  String get tripMuteBody => 'Smetti di ricevere notifiche';

  @override
  String get tripArchive => 'Archivia viaggio';

  @override
  String get tripArchiveBody =>
      'Lo toglie dalla tua lista. Tutti continuano a leggerlo, nessuno può più aggiungerci nulla.';

  @override
  String get tripArchiveTitle => 'Archiviare questo viaggio?';

  @override
  String get tripUnarchive => 'Riporta dall\'archivio';

  @override
  String get tripArchivedBanner =>
      'Questo viaggio è archiviato. Non ci si può più aggiungere nulla.';

  @override
  String get tripsArchivedTitle => 'Archiviati';

  @override
  String tripsArchivedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viaggi archiviati',
      one: '1 viaggio archiviato',
    );
    return '$_temp0';
  }

  @override
  String get tripsArchivedEmpty => 'Non hai ancora archiviato niente.';

  @override
  String get tripUnsavedChanges => 'Ci sono modifiche non salvate';

  @override
  String get calendarYesterday => 'Ieri';

  @override
  String get calendarStartsNow => 'Adesso';

  @override
  String calendarStartsInMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tra $count min',
      one: 'tra 1 min',
    );
    return '$_temp0';
  }

  @override
  String calendarStartsInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tra $count ore',
      one: 'tra 1 ora',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTitle => 'Notifiche';

  @override
  String get notificationsMarkAllRead => 'Segna tutte lette';

  @override
  String get notificationsEmptyTitle => 'Sei in pari';

  @override
  String get notificationsEmptyBody =>
      'Nuove spese, programmi e persone\ncompariranno qui.';

  @override
  String notificationExpenseAdded(
    String actor,
    String amount,
    String description,
  ) {
    return '$actor ha aggiunto $amount per $description';
  }

  @override
  String notificationExpenseDeleted(String actor, String description) {
    return '$actor ha eliminato la spesa per $description';
  }

  @override
  String notificationSettlement(String actor, String amount) {
    return '$actor ti ha rimborsato $amount';
  }

  @override
  String notificationTaskAssigned(String actor, String title) {
    return '$actor ti ha assegnato «$title»';
  }

  @override
  String notificationEventAdded(String actor, String title) {
    return '$actor ha aggiunto $title al programma';
  }

  @override
  String notificationMemberJoined(String actor) {
    return '$actor è entrato nel viaggio';
  }

  @override
  String notificationSomethingHappened(String actor) {
    return '$actor ha fatto qualcosa in questo viaggio';
  }

  @override
  String get settingsMuteTrip => 'Silenzia questo viaggio';

  @override
  String get settingsMuteTripBody => 'Smetti di ricevere notifiche';

  @override
  String get notificationsClearAll => 'Elimina tutte';

  @override
  String get notificationsClearAllTitle => 'Eliminare tutte le notifiche?';

  @override
  String get notificationsClearAllBody =>
      'Spariscono solo per te. Non è reversibile.';

  @override
  String get notificationDeleteTitle => 'Eliminare questa notifica?';

  @override
  String get notificationDeleteBody =>
      'Sparisce solo per te. Quello a cui si riferisce resta.';

  @override
  String get onboardSkip => 'Salta';

  @override
  String get onboardNext => 'Avanti';

  @override
  String get onboardStart => 'Inizia';

  @override
  String get onboardTripsTitle => 'Un posto per ogni viaggio';

  @override
  String get onboardTripsBody =>
      'Crea un viaggio, condividi il codice, e tutti finiscono nello stesso programma.';

  @override
  String get onboardPlanTitle => 'Tutto ciò che ha un orario';

  @override
  String get onboardPlanBody =>
      'Voli, check-in, il tram delle nove. Più le cose da fare che nessuno ricorda chi si è preso.';

  @override
  String get onboardMoneyTitle => 'Chi deve cosa, sistemato';

  @override
  String get onboardMoneyBody =>
      'Aggiungi le spese mentre le fai. I conti si fanno da soli, al centesimo.';

  @override
  String get onboardTogetherTitle => 'E dove siete tutti';

  @override
  String get onboardTogetherBody =>
      'Salva i posti su cui vi siete accordati, e condividi la posizione finché vuoi. Mai di default.';
}
