// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'TodoTrip';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonRemove => 'Retirer';

  @override
  String get commonUndo => 'Annuler';

  @override
  String get commonTryAgain => 'Réessayer';

  @override
  String get commonClear => 'Effacer';

  @override
  String get commonCopy => 'Copier';

  @override
  String get commonOk => 'OK';

  @override
  String get commonYou => 'Vous';

  @override
  String get commonYouLower => 'vous';

  @override
  String get commonSomeone => 'Quelqu\'un';

  @override
  String get commonSomeoneLower => 'quelqu\'un';

  @override
  String get commonUnknown => 'Inconnu';

  @override
  String get commonOwner => 'Propriétaire';

  @override
  String get commonMember => 'Membre';

  @override
  String get commonComingSoon => 'Bientôt disponible';

  @override
  String get errorGeneric => 'Une erreur est survenue. Réessayez.';

  @override
  String get errorSlowConnection => 'Connexion lente. Réessayez.';

  @override
  String get errorNoConnection => 'Serveur inaccessible.';

  @override
  String get errorInvalidData => 'Vérifiez les informations saisies';

  @override
  String get errorWrongCredentials => 'E-mail ou mot de passe incorrect';

  @override
  String get errorEmailTaken => 'Cet e-mail est déjà enregistré';

  @override
  String get errorInvalidCode => 'Ce code est invalide ou a expiré';

  @override
  String get errorNoMapsApp => 'Aucune application de cartes pour l\'ouvrir.';

  @override
  String get errorNotAllowed => 'Vous n\'avez pas le droit de faire cela.';

  @override
  String get errorNotFound => 'Cela n\'existe plus.';

  @override
  String get authCreateAccount => 'Créez votre compte';

  @override
  String get authWelcomeBack => 'Bon retour';

  @override
  String get authTagline => 'Organisez vos voyages avec vos amis';

  @override
  String get authNameLabel => 'Nom';

  @override
  String get authNameEmpty => 'Saisissez votre nom';

  @override
  String get authEmailLabel => 'E-mail';

  @override
  String get authEmailEmpty => 'Saisissez votre e-mail';

  @override
  String get authEmailInvalid => 'Saisissez un e-mail valide';

  @override
  String get authPasswordLabel => 'Mot de passe';

  @override
  String get authPasswordEmpty => 'Saisissez votre mot de passe';

  @override
  String get authPasswordTooShort => 'Au moins 8 caractères';

  @override
  String get authShowPassword => 'Afficher le mot de passe';

  @override
  String get authHidePassword => 'Masquer le mot de passe';

  @override
  String get authSignIn => 'Se connecter';

  @override
  String get authSignUp => 'S\'inscrire';

  @override
  String get authSwitchToSignIn => 'Déjà un compte ? Se connecter';

  @override
  String get authSwitchToSignUp => 'Pas de compte ? S\'inscrire';

  @override
  String get navTrips => 'Voyages';

  @override
  String get navAdd => 'Ajouter';

  @override
  String get navSettings => 'Réglages';

  @override
  String get tripsTitle => 'Mes voyages';

  @override
  String get tripsEmptyTitle => 'Aucun voyage';

  @override
  String get tripsEmptyBody =>
      'Créez votre premier voyage, ou rejoignez-en\nun avec le code d\'un ami.';

  @override
  String get tripsEmptyAction => 'Commencer';

  @override
  String get addTripTitle => 'Ajouter un voyage';

  @override
  String get addTripCreate => 'Créer un voyage';

  @override
  String get addTripCreateBody => 'Commencez à organiser et invitez vos amis';

  @override
  String get addTripJoin => 'Rejoindre avec un code';

  @override
  String get addTripJoinBody =>
      'Quelqu\'un vous a partagé un code d\'invitation';

  @override
  String get tripNewTitle => 'Nouveau voyage';

  @override
  String get tripNameLabel => 'Nom du voyage';

  @override
  String get tripNameEmpty => 'Donnez un nom à votre voyage';

  @override
  String get tripAddDates => 'Ajouter des dates (facultatif)';

  @override
  String get tripClearDates => 'Effacer les dates';

  @override
  String get tripCreate => 'Créer le voyage';

  @override
  String get tripJoinTitle => 'Rejoindre un voyage';

  @override
  String get tripJoinBody => 'Saisissez le code qu\'un ami vous a partagé';

  @override
  String get tripJoinCodeEmpty => 'Saisissez le code qu\'on vous a donné';

  @override
  String get tripJoin => 'Rejoindre';

  @override
  String get tripNoDates => 'Aucune date';

  @override
  String tripDatesFrom(String date) {
    return 'À partir du $date';
  }

  @override
  String tripDatesUntil(String date) {
    return 'Jusqu\'au $date';
  }

  @override
  String get tripFallbackName => 'Voyage';

  @override
  String get tabCalendar => 'Agenda';

  @override
  String get tabTasks => 'Tâches';

  @override
  String get tabMoney => 'Dépenses';

  @override
  String get tabMap => 'Carte';

  @override
  String get tabGroup => 'Groupe';

  @override
  String get fabEvent => 'Événement';

  @override
  String get fabTask => 'Tâche';

  @override
  String get fabList => 'Liste';

  @override
  String get fabExpense => 'Dépense';

  @override
  String get calendarEmptyTitle => 'Rien de prévu';

  @override
  String get calendarEmptyBody =>
      'Ajoutez les vols, les arrivées et\ntout ce qui a une heure.';

  @override
  String get calendarToday => 'Aujourd’hui';

  @override
  String get calendarTomorrow => 'Demain';

  @override
  String get tasksViewTodo => 'À faire';

  @override
  String get tasksViewLists => 'Listes';

  @override
  String get tasksEmptyTitle => 'Rien à faire';

  @override
  String get tasksEmptyBody =>
      'Réserver l\'auberge, acheter la crème,\nse partager la conduite.';

  @override
  String tasksCompletedCount(int count) {
    return '$count terminées';
  }

  @override
  String tasksOverdue(String date) {
    return 'En retard · $date';
  }

  @override
  String tasksDueToday(String time) {
    return 'Aujourd\'hui, $time';
  }

  @override
  String tasksDueTomorrow(String time) {
    return 'Demain, $time';
  }

  @override
  String get listsEmptyTitle => 'Aucune liste';

  @override
  String get listsEmptyBody =>
      'Les courses, quoi emporter,\ndes endroits à essayer.';

  @override
  String get listEmpty => 'Vide';

  @override
  String get listAllDone => 'Tout est fait';

  @override
  String listLeftOf(int left, int total) {
    return '$left sur $total à prendre';
  }

  @override
  String listProgress(int checked, int total) {
    return '$checked sur $total';
  }

  @override
  String get listTitle => 'Liste';

  @override
  String get listGoneTitle => 'Cette liste n\'existe plus';

  @override
  String get listGoneBody => 'Quelqu\'un du groupe l\'a supprimée.';

  @override
  String get listEntriesEmptyTitle => 'Encore vide';

  @override
  String get listEntriesEmptyBody =>
      'Écrivez ci-dessous et touchez +.\nLe champ reste prêt pour la suivante.';

  @override
  String get listAddItem => 'Ajouter un élément';

  @override
  String get itemNewEvent => 'Nouvel événement';

  @override
  String get itemNewTask => 'Nouvelle tâche';

  @override
  String get itemNewList => 'Nouvelle liste';

  @override
  String get itemEventLabel => 'Que se passe-t-il ?';

  @override
  String get itemTaskLabel => 'Qu\'y a-t-il à faire ?';

  @override
  String get itemListLabel => 'À quoi sert cette liste ?';

  @override
  String get itemListHint => 'Courses';

  @override
  String get itemPickDateTime => 'Choisir la date et l\'heure';

  @override
  String get itemAddDeadline => 'Ajouter une échéance (facultatif)';

  @override
  String get itemWhereOptional => 'Où ? (facultatif)';

  @override
  String get itemAssignTo => 'ASSIGNER À';

  @override
  String get itemAssignHint =>
      'Laissez vide et n\'importe qui peut s\'en charger.';

  @override
  String get itemAddEvent => 'Ajouter l\'événement';

  @override
  String get itemAddTask => 'Ajouter la tâche';

  @override
  String get itemAddList => 'Ajouter la liste';

  @override
  String get moneyAllSettled => 'Tout est réglé';

  @override
  String get moneyYouAreOwed => 'On vous doit';

  @override
  String get moneyYouOwe => 'Vous devez';

  @override
  String moneyTripTotal(String amount) {
    return 'Total du voyage $amount';
  }

  @override
  String get moneySettleUp => 'Régler les comptes';

  @override
  String get moneyEveryonesBalance => 'Les soldes de chacun';

  @override
  String get moneyEmptyTitle => 'Aucune dépense';

  @override
  String get moneyEmptyBody =>
      'Ajoutez la première et nous suivrons\nqui doit quoi à qui.';

  @override
  String moneyPaidBy(String name) {
    return 'Payé par $name';
  }

  @override
  String moneyYourShare(String amount) {
    return 'votre part : $amount';
  }

  @override
  String get moneyNotInvolved => 'non concerné';

  @override
  String get moneyRepayment => 'Remboursement';

  @override
  String moneyPaidSomeone(String payer, String payee) {
    return '$payer a payé $payee';
  }

  @override
  String get moneyToday => 'Aujourd\'hui';

  @override
  String get moneyYesterday => 'Hier';

  @override
  String get expenseNewTitle => 'Nouvelle dépense';

  @override
  String get expenseWhatFor => 'Pour quoi ?';

  @override
  String get expensePaidBy => 'PAYÉ PAR';

  @override
  String get expenseSplitBetween => 'PARTAGÉ ENTRE';

  @override
  String get expenseSplitEqually => 'Parts égales';

  @override
  String get expenseCustomAmounts => 'Montants personnalisés';

  @override
  String get expenseRemaining => 'Restant';

  @override
  String get expenseSave => 'Enregistrer';

  @override
  String get expenseSplitLabel => 'PARTAGE';

  @override
  String get expenseDelete => 'Supprimer la dépense';

  @override
  String get expenseDeleting => 'Suppression…';

  @override
  String get expenseSuggestionExamples => 'Dîner';

  @override
  String get expenseSuggestionGroceries => 'Courses';

  @override
  String get expenseSuggestionTaxi => 'Taxi';

  @override
  String get expenseSuggestionHotel => 'Hôtel';

  @override
  String get expenseSuggestionDrinks => 'Boissons';

  @override
  String get settleTitle => 'Régler les comptes';

  @override
  String get settleBody => 'Le plus simple pour tout solder :';

  @override
  String get settleAllSquare => 'Tout le monde est à jour.';

  @override
  String settleSummary(int payments, int expenses) {
    String _temp0 = intl.Intl.pluralLogic(
      payments,
      locale: localeName,
      other: '$payments paiements',
      one: '1 paiement',
    );
    return '$_temp0 au lieu de $expenses';
  }

  @override
  String get settleMarkAsPaid => 'Marquer comme payé';

  @override
  String get settleUndoTitle => 'Annuler ce remboursement ?';

  @override
  String get settleUndoBody =>
      'Les soldes de chacun reviennent à ce qu\'ils étaient avant son enregistrement.';

  @override
  String get settleUndoAction => 'Annuler ce remboursement';

  @override
  String get settleUndoing => 'Annulation…';

  @override
  String settleOnlySenderCanUndo(String name) {
    return 'Seul $name peut l\'annuler.';
  }

  @override
  String get settleRepaymentTitle => 'Remboursement';

  @override
  String groupPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes',
      one: '1 personne',
    );
    return '$_temp0';
  }

  @override
  String get groupInvitePeople => 'Inviter des personnes';

  @override
  String get groupDangerZone => 'Zone sensible';

  @override
  String get groupDeleteTrip => 'Supprimer le voyage';

  @override
  String get groupLeaveTrip => 'Quitter le voyage';

  @override
  String groupJoined(String date) {
    return 'Arrivé le $date';
  }

  @override
  String get inviteTitle => 'Inviter des personnes';

  @override
  String get inviteBody =>
      'Partagez un code et n\'importe qui peut rejoindre ce voyage.';

  @override
  String get inviteCreate => 'Créer un code d\'invitation';

  @override
  String get inviteNewCode => 'Nouveau code';

  @override
  String get inviteNotUsedYet => 'Pas encore utilisé';

  @override
  String inviteUsedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Utilisé $count fois',
      one: 'Utilisé une fois',
    );
    return '$_temp0';
  }

  @override
  String get inviteCodeCopied => 'Code copié';

  @override
  String get inviteRevoke => 'Révoquer ce code';

  @override
  String get inviteCodeHint => 'ABCD1234';

  @override
  String get memberNoLongerHere => 'Cette personne n\'est plus dans le voyage.';

  @override
  String get memberMakeOwner => 'Nommer propriétaire';

  @override
  String get memberMakeOwnerDetail =>
      'Elle reprend le voyage, vous devenez membre.';

  @override
  String get memberRemove => 'Retirer du voyage';

  @override
  String get memberRemoveDetail => 'Elle perd l\'accès immédiatement.';

  @override
  String get memberLeaveAndDelete => 'Quitter et supprimer le voyage';

  @override
  String get memberLeaveBlocked =>
      'Vous êtes propriétaire. Nommez d\'abord quelqu\'un d\'autre.';

  @override
  String get memberLeaveLastOne =>
      'Vous êtes le dernier, le voyage partira avec vous.';

  @override
  String get memberOwnerOnly => 'Seul le propriétaire peut gérer les membres.';

  @override
  String memberMakeOwnerTitle(String name) {
    return 'Nommer $name propriétaire ?';
  }

  @override
  String memberMakeOwnerBody(String name) {
    return '$name pourra inviter des personnes, retirer des membres et supprimer le voyage. Vous devenez un membre ordinaire, et seul $name pourra vous le rendre.';
  }

  @override
  String memberRemoveTitle(String name) {
    return 'Retirer $name ?';
  }

  @override
  String get memberRemoveBody =>
      'Cette personne perd immédiatement l\'accès à ce voyage. Ce qu\'elle a ajouté reste : dépenses, tâches et soldes des autres ne changent pas.';

  @override
  String get memberNotSettledTitle => 'Comptes non soldés';

  @override
  String memberOwesAmount(String name, String amount) {
    return '$name doit $amount. Soldez avant de la retirer.';
  }

  @override
  String memberIsOwedAmount(String name, String amount) {
    return 'On doit $amount à $name. Soldez avant de la retirer.';
  }

  @override
  String memberYouOweAmount(String amount) {
    return 'Vous devez $amount. Soldez avant de partir.';
  }

  @override
  String memberYouAreOwedAmount(String amount) {
    return 'On vous doit $amount. Soldez avant de partir.';
  }

  @override
  String get memberOwnerTitle => 'Vous êtes propriétaire';

  @override
  String get memberOwnerBody =>
      'Nommez quelqu\'un d\'autre propriétaire avant de partir, pour que le groupe garde une personne capable de gérer le voyage.';

  @override
  String memberLeaveTitle(String trip) {
    return 'Quitter $trip ?';
  }

  @override
  String get memberLeaveBody =>
      'Vous perdrez l\'accès au programme et aux dépenses. Ce que vous avez ajouté reste au groupe.';

  @override
  String memberLeaveDeleteTitle(String trip) {
    return 'Quitter et supprimer $trip ?';
  }

  @override
  String get memberLeaveDeleteBody =>
      'Vous êtes le dernier. En partant, ce voyage sera supprimé avec tout ce qu\'il contient : dépenses, agenda, tâches et listes. C\'est irréversible.';

  @override
  String get memberLeaveDeleteAction => 'Quitter et supprimer';

  @override
  String get memberLeaveAction => 'Quitter';

  @override
  String tripDeleteTitle(String trip) {
    return 'Supprimer $trip ?';
  }

  @override
  String get tripDeleteBody =>
      'Cela supprime définitivement le programme, chaque dépense et les soldes de tous. C\'est irréversible.';

  @override
  String deleteItemTitle(String title) {
    return 'Supprimer « $title » ?';
  }

  @override
  String deleteListTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get deleteListEmptyBody => 'La liste est retirée pour tout le monde.';

  @override
  String deleteListBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ses $count éléments partent avec elle, pour tout le monde.',
      one: 'Son élément part avec elle, pour tout le monde.',
    );
    return '$_temp0';
  }

  @override
  String deleteEntryTitle(String text) {
    return 'Retirer « $text » ?';
  }

  @override
  String deleteExpenseTitle(String description) {
    return 'Supprimer « $description » ?';
  }

  @override
  String get deleteExpenseBody => 'Les soldes de chacun seront recalculés.';

  @override
  String get deleteExpenseWithRepayments =>
      'Ce voyage contient des remboursements enregistrés. Supprimer cette dépense changera les soldes de tout le monde.';

  @override
  String get mapShareOn => 'Vous partagez votre position';

  @override
  String get mapShareOff => 'Partager ma position';

  @override
  String get mapShareForegroundOnly =>
      'Seulement quand cette carte est ouverte.';

  @override
  String get mapServicesOff =>
      'La localisation est désactivée sur cet appareil.';

  @override
  String get mapPermissionDenied => 'Autorisation de localisation refusée.';

  @override
  String get mapPermissionBlocked =>
      'La localisation est bloquée pour TodoTrip.';

  @override
  String get mapOpenSettings => 'Ouvrir les réglages';

  @override
  String get mapFitEveryone => 'Voir tout le monde';

  @override
  String get mapCentreOnMe => 'Me centrer';

  @override
  String get mapEmptyHint => 'Appui long n\'importe où pour poser un repère.';

  @override
  String get mapAttribution => 'contributeurs d\'OpenStreetMap';

  @override
  String get mapRightNow => 'À l\'instant';

  @override
  String mapMinutesAgo(int count) {
    return 'il y a $count minutes';
  }

  @override
  String mapLastSeen(String time) {
    return 'Vu à $time';
  }

  @override
  String get mapGetDirections => 'Itinéraire';

  @override
  String get mapAppleMaps => 'Apple Plans';

  @override
  String get mapGoogleMaps => 'Google Maps';

  @override
  String get pinNewTitle => 'Nouveau repère';

  @override
  String get pinNameLabel => 'Qu\'y a-t-il ici ?';

  @override
  String get pinNameHint => 'Auberge Lisbonne';

  @override
  String get pinCategoryLabel => 'CATÉGORIE';

  @override
  String get pinNotesLabel => 'Notes (facultatif)';

  @override
  String get pinDrop => 'Poser le repère';

  @override
  String get pinDelete => 'Supprimer le repère';

  @override
  String pinDeleteTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get pinDeleteBody => 'Il disparaît de la carte pour tout le monde.';

  @override
  String pinAddedBy(String name, String date) {
    return 'Ajouté par $name · $date';
  }

  @override
  String get pinCategoryLodging => 'Logement';

  @override
  String get pinCategoryFood => 'Restauration';

  @override
  String get pinCategoryMeetingPoint => 'Point de rendez-vous';

  @override
  String get pinCategoryParking => 'Stationnement';

  @override
  String get pinCategorySight => 'À voir';

  @override
  String get pinCategoryOther => 'Autre';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPushNotifications => 'Notifications push';

  @override
  String get settingsPushNotificationsBody =>
      'Mises à jour du voyage et nouvelles tâches';

  @override
  String get settingsExpenseAlerts => 'Alertes de dépenses';

  @override
  String get settingsExpenseAlertsBody => 'Quand quelqu\'un ajoute une dépense';

  @override
  String get settingsPreferences => 'Préférences';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageSystem => 'Système';

  @override
  String get settingsDefaultCurrency => 'Devise par défaut';

  @override
  String get settingsDefaultCurrencyHint =>
      'Utilisée à la création d\'un voyage. Les voyages existants gardent la leur.';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsSignOut => 'Se déconnecter';

  @override
  String get settingsSignOutTitle => 'Se déconnecter ?';

  @override
  String get settingsSignOutBody =>
      'Il vous faudra votre e-mail et votre mot de passe pour revenir.';

  @override
  String get tripStageNow => 'En cours';

  @override
  String tripStageDayOf(int day, int total) {
    return 'Jour $day sur $total';
  }

  @override
  String get tripStageToday => 'Commence aujourd\'hui';

  @override
  String get tripStageTomorrow => 'Demain';

  @override
  String tripStageInDays(int days) {
    return 'Dans $days jours';
  }

  @override
  String get tripStageEnded => 'Terminé';

  @override
  String get moneySettledShort => 'Réglé';

  @override
  String get commonJustNow => 'À l\'instant';

  @override
  String commonMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count minutes',
      one: 'il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String commonHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String commonDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'il y a $count jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get tripIconLabel => 'Icône';

  @override
  String get tripColorLabel => 'Couleur';

  @override
  String get tripAddDescription => 'Ajouter une description';

  @override
  String get tripDescriptionLabel => 'Description';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsAccentColour => 'Couleur principale';

  @override
  String get settingsAccentColourBody =>
      'Utilisée pour les boutons, les éléments actifs et la barre d’onglets.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileSaved => 'Profil mis à jour';

  @override
  String get profileEmailLocked =>
      'Changer d’adresse e-mail suppose de vérifier la nouvelle, ce qui n’est pas encore possible.';

  @override
  String get profileChangePassword => 'Changer de mot de passe';

  @override
  String get profileChangePasswordBody => 'Vous déconnecte partout ailleurs';

  @override
  String get profileChangePasswordWarning =>
      'Tous les autres appareils connectés à ce compte seront déconnectés.';

  @override
  String get profileCurrentPassword => 'Mot de passe actuel';

  @override
  String get profileNewPassword => 'Nouveau mot de passe';

  @override
  String get profileRepeatPassword => 'Répétez le nouveau mot de passe';

  @override
  String get profilePasswordMismatch =>
      'Les deux mots de passe ne correspondent pas';

  @override
  String get profileWrongPassword => 'Ce n’est pas votre mot de passe actuel';

  @override
  String get profilePasswordChanged => 'Mot de passe modifié';

  @override
  String get profileDeleteAccount => 'Supprimer le compte';

  @override
  String get profileDeleteTitle => 'Supprimer votre compte ?';

  @override
  String get profileDeleteBody =>
      'Votre nom, votre e-mail et votre mot de passe sont effacés et vous êtes déconnecté partout. Les dépenses auxquelles vous avez participé restent, sans votre nom, car elles déterminent ce que les autres doivent. C’est irréversible.';

  @override
  String get profileDeleteConfirm => 'Supprimer';

  @override
  String get profileDeleteOwnsTrips =>
      'Vous êtes encore propriétaire d’un voyage où se trouvent d’autres personnes. Transmettez-le ou supprimez-le, puis réessayez.';

  @override
  String get tripSettingsTitle => 'Réglages du voyage';

  @override
  String get tripSettingsEdit => 'Modifier';

  @override
  String get tripSettingsInfo => 'Informations';

  @override
  String get tripSettingsPersonal => 'Rien que pour vous';

  @override
  String get tripSettingsDanger => 'Zone sensible';

  @override
  String get tripCurrencyLabel => 'Devise';

  @override
  String get tripCurrencyWarning =>
      'Changer de devise ne convertit pas les dépenses déjà saisies. Les montants restent identiques, seul le symbole change.';

  @override
  String get tripSaveChanges => 'Enregistrer les modifications';

  @override
  String get tripSaved => 'Voyage mis à jour';

  @override
  String tripCreatedByOn(String name, String date) {
    return 'Créé par $name le $date';
  }

  @override
  String tripStatMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
    );
    return '$_temp0';
  }

  @override
  String tripStatExpenses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dépenses',
      one: '1 dépense',
    );
    return '$_temp0';
  }

  @override
  String tripStatItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments du programme',
      one: '1 élément du programme',
    );
    return '$_temp0';
  }

  @override
  String get tripTotalSpent => 'Total dépensé';

  @override
  String get tripExportCsv => 'Exporter les dépenses en CSV';

  @override
  String get tripExportEmpty => 'Il n’y a pas encore de dépenses à exporter.';

  @override
  String tripExportShareText(String trip) {
    return '$trip — dépenses';
  }

  @override
  String get tripMuteLabel => 'Mettre ce voyage en sourdine';

  @override
  String get tripMuteBody => 'Ne plus recevoir de notifications';

  @override
  String get tripArchive => 'Archiver le voyage';

  @override
  String get tripArchiveBody =>
      'Le retire de votre liste. Tout le monde continue à le lire, personne ne peut plus rien y ajouter.';

  @override
  String get tripArchiveTitle => 'Archiver ce voyage ?';

  @override
  String get tripUnarchive => 'Sortir de l’archive';

  @override
  String get tripArchivedBanner =>
      'Ce voyage est archivé. On ne peut plus rien y ajouter.';

  @override
  String get tripsArchivedTitle => 'Archivés';

  @override
  String tripsArchivedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voyages archivés',
      one: '1 voyage archivé',
    );
    return '$_temp0';
  }

  @override
  String get tripsArchivedEmpty => 'Rien d’archivé pour l’instant.';

  @override
  String get tripUnsavedChanges =>
      'Vous avez des modifications non enregistrées';

  @override
  String get calendarYesterday => 'Hier';

  @override
  String get calendarStartsNow => 'Maintenant';

  @override
  String calendarStartsInMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dans $count min',
      one: 'dans 1 min',
    );
    return '$_temp0';
  }

  @override
  String calendarStartsInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'dans $count heures',
      one: 'dans 1 heure',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Tout marquer comme lu';

  @override
  String get notificationsEmptyTitle => 'Vous êtes à jour';

  @override
  String get notificationsEmptyBody =>
      'Les nouvelles dépenses, les plans et les\npersonnes apparaîtront ici.';

  @override
  String notificationExpenseAdded(
    String actor,
    String amount,
    String description,
  ) {
    return '$actor a ajouté $amount pour $description';
  }

  @override
  String notificationExpenseDeleted(String actor, String description) {
    return '$actor a supprimé la dépense pour $description';
  }

  @override
  String notificationSettlement(String actor, String amount) {
    return '$actor vous a remboursé $amount';
  }

  @override
  String notificationTaskAssigned(String actor, String title) {
    return '$actor vous a confié « $title »';
  }

  @override
  String notificationEventAdded(String actor, String title) {
    return '$actor a ajouté $title au programme';
  }

  @override
  String notificationMemberJoined(String actor) {
    return '$actor a rejoint le voyage';
  }

  @override
  String notificationSomethingHappened(String actor) {
    return '$actor a fait quelque chose dans ce voyage';
  }

  @override
  String get settingsMuteTrip => 'Mettre ce voyage en sourdine';

  @override
  String get settingsMuteTripBody => 'Ne plus recevoir de notifications';

  @override
  String get notificationsClearAll => 'Tout supprimer';

  @override
  String get notificationsClearAllTitle =>
      'Supprimer toutes les notifications ?';

  @override
  String get notificationsClearAllBody =>
      'Elles disparaissent pour vous seul. C’est irréversible.';

  @override
  String get notificationDeleteTitle => 'Supprimer cette notification ?';

  @override
  String get notificationDeleteBody =>
      'Elle disparaît pour vous seul. Ce qu’elle annonçait reste.';

  @override
  String get onboardSkip => 'Passer';

  @override
  String get onboardNext => 'Suivant';

  @override
  String get onboardStart => 'Commencer';

  @override
  String get onboardTripsTitle => 'Un endroit par voyage';

  @override
  String get onboardTripsBody =>
      'Créez un voyage, partagez le code, et tout le monde arrive dans le même programme.';

  @override
  String get onboardPlanTitle => 'Tout ce qui a une heure';

  @override
  String get onboardPlanBody =>
      'Vols, arrivées, le tram de neuf heures. Et les tâches dont personne ne sait qui les a prises.';

  @override
  String get onboardMoneyTitle => 'Qui doit quoi, réglé';

  @override
  String get onboardMoneyBody =>
      'Ajoutez les dépenses au fur et à mesure. Les comptes se font tout seuls, au centime près.';

  @override
  String get onboardTogetherTitle => 'Et où vous êtes';

  @override
  String get onboardTogetherBody =>
      'Enregistrez les lieux choisis ensemble, et partagez votre position tant que vous le voulez. Jamais par défaut.';
}
