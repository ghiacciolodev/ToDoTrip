// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TodoTrip';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonOk => 'OK';

  @override
  String get commonYou => 'You';

  @override
  String get commonYouLower => 'you';

  @override
  String get commonSomeone => 'Someone';

  @override
  String get commonSomeoneLower => 'someone';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get commonOwner => 'Owner';

  @override
  String get commonMember => 'Member';

  @override
  String get commonComingSoon => 'Coming soon';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorSlowConnection => 'Slow connection. Try again.';

  @override
  String get errorNoConnection => 'Cannot reach the server.';

  @override
  String get errorInvalidData => 'Please check the details you entered';

  @override
  String get errorWrongCredentials => 'Incorrect email or password';

  @override
  String get errorEmailTaken => 'This email is already registered';

  @override
  String get errorInvalidCode => 'That code is invalid or has expired';

  @override
  String get errorNoMapsApp => 'No maps app to open this with.';

  @override
  String get errorNotAllowed => 'You are not allowed to do that.';

  @override
  String get errorNotFound => 'That is no longer there.';

  @override
  String get authCreateAccount => 'Create your account';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authTagline => 'Plan trips together with your friends';

  @override
  String get authNameLabel => 'Name';

  @override
  String get authNameEmpty => 'Enter your name';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailEmpty => 'Enter your email';

  @override
  String get authEmailInvalid => 'Enter a valid email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordEmpty => 'Enter your password';

  @override
  String get authPasswordTooShort => 'At least 8 characters';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authSwitchToSignIn => 'Already have an account? Sign in';

  @override
  String get authSwitchToSignUp => 'Don\'t have an account? Sign up';

  @override
  String get navTrips => 'Trips';

  @override
  String get navAdd => 'Add';

  @override
  String get navSettings => 'Settings';

  @override
  String get tripsTitle => 'My trips';

  @override
  String get tripsEmptyTitle => 'No trips yet';

  @override
  String get tripsEmptyBody =>
      'Create your first trip, or join one\nwith a code from a friend.';

  @override
  String get tripsEmptyAction => 'Get started';

  @override
  String get addTripTitle => 'Add a trip';

  @override
  String get addTripCreate => 'Create a trip';

  @override
  String get addTripCreateBody => 'Start planning and invite your friends';

  @override
  String get addTripJoin => 'Join with a code';

  @override
  String get addTripJoinBody => 'Someone shared an invite code with you';

  @override
  String get tripNewTitle => 'New trip';

  @override
  String get tripNameLabel => 'Trip name';

  @override
  String get tripNameEmpty => 'Give your trip a name';

  @override
  String get tripAddDates => 'Add dates (optional)';

  @override
  String get tripClearDates => 'Clear dates';

  @override
  String get tripCreate => 'Create trip';

  @override
  String get tripJoinTitle => 'Join a trip';

  @override
  String get tripJoinBody => 'Enter the code a friend shared with you';

  @override
  String get tripJoinCodeEmpty => 'Enter the code you were given';

  @override
  String get tripJoin => 'Join';

  @override
  String get tripNoDates => 'No dates yet';

  @override
  String tripDatesFrom(String date) {
    return 'From $date';
  }

  @override
  String tripDatesUntil(String date) {
    return 'Until $date';
  }

  @override
  String get tripFallbackName => 'Trip';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabTasks => 'Tasks';

  @override
  String get tabMoney => 'Money';

  @override
  String get tabMap => 'Map';

  @override
  String get tabGroup => 'Group';

  @override
  String get fabEvent => 'Event';

  @override
  String get fabTask => 'Task';

  @override
  String get fabList => 'List';

  @override
  String get fabExpense => 'Expense';

  @override
  String get calendarEmptyTitle => 'Nothing planned yet';

  @override
  String get calendarEmptyBody =>
      'Add flights, check-ins and\nanything with a time on it.';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarTomorrow => 'Tomorrow';

  @override
  String get tasksViewTodo => 'To-do';

  @override
  String get tasksViewLists => 'Lists';

  @override
  String get tasksEmptyTitle => 'Nothing to do yet';

  @override
  String get tasksEmptyBody =>
      'Book the hostel, buy sunscreen,\nsplit the driving.';

  @override
  String tasksCompletedCount(int count) {
    return '$count completed';
  }

  @override
  String tasksOverdue(String date) {
    return 'Overdue · $date';
  }

  @override
  String tasksDueToday(String time) {
    return 'Today, $time';
  }

  @override
  String tasksDueTomorrow(String time) {
    return 'Tomorrow, $time';
  }

  @override
  String get listsEmptyTitle => 'No lists yet';

  @override
  String get listsEmptyBody =>
      'A shopping list, things to pack,\nplaces you want to try.';

  @override
  String get listEmpty => 'Empty';

  @override
  String get listAllDone => 'All done';

  @override
  String listLeftOf(int left, int total) {
    return '$left left of $total';
  }

  @override
  String listProgress(int checked, int total) {
    return '$checked of $total';
  }

  @override
  String get listTitle => 'List';

  @override
  String get listGoneTitle => 'This list is gone';

  @override
  String get listGoneBody => 'Someone in the group deleted it.';

  @override
  String get listEntriesEmptyTitle => 'Nothing on it yet';

  @override
  String get listEntriesEmptyBody =>
      'Type below and tap +.\nThe field stays ready for the next one.';

  @override
  String get listAddItem => 'Add an item';

  @override
  String get itemNewEvent => 'New event';

  @override
  String get itemNewTask => 'New task';

  @override
  String get itemNewList => 'New list';

  @override
  String get itemEventLabel => 'What is happening?';

  @override
  String get itemTaskLabel => 'What needs doing?';

  @override
  String get itemListLabel => 'What is the list for?';

  @override
  String get itemListHint => 'Groceries';

  @override
  String get itemPickDateTime => 'Pick a date and time';

  @override
  String get itemAddDeadline => 'Add a deadline (optional)';

  @override
  String get itemWhereOptional => 'Where? (optional)';

  @override
  String get itemAssignTo => 'ASSIGN TO';

  @override
  String get itemAssignHint => 'Leave empty and anyone can pick it up.';

  @override
  String get itemAddEvent => 'Add event';

  @override
  String get itemAddTask => 'Add task';

  @override
  String get itemAddList => 'Add list';

  @override
  String get moneyAllSettled => 'All settled';

  @override
  String get moneyYouAreOwed => 'You are owed';

  @override
  String get moneyYouOwe => 'You owe';

  @override
  String moneyTripTotal(String amount) {
    return 'Trip total $amount';
  }

  @override
  String get moneySettleUp => 'Settle up';

  @override
  String get moneyEveryonesBalance => 'Everyone\'s balance';

  @override
  String get moneyEmptyTitle => 'No expenses yet';

  @override
  String get moneyEmptyBody =>
      'Add the first one and we’ll keep\ntrack of who owes what.';

  @override
  String moneyPaidBy(String name) {
    return 'Paid by $name';
  }

  @override
  String moneyYourShare(String amount) {
    return 'you: $amount';
  }

  @override
  String get moneyNotInvolved => 'not involved';

  @override
  String get moneyRepayment => 'Repayment';

  @override
  String moneyPaidSomeone(String payer, String payee) {
    return '$payer paid $payee';
  }

  @override
  String get moneyToday => 'Today';

  @override
  String get moneyYesterday => 'Yesterday';

  @override
  String get expenseNewTitle => 'New expense';

  @override
  String get expenseWhatFor => 'What for?';

  @override
  String get expensePaidBy => 'PAID BY';

  @override
  String get expenseSplitBetween => 'SPLIT BETWEEN';

  @override
  String get expenseSplitEqually => 'Split equally';

  @override
  String get expenseCustomAmounts => 'Custom amounts';

  @override
  String get expenseRemaining => 'Remaining';

  @override
  String get expenseSave => 'Save expense';

  @override
  String get expenseSplitLabel => 'SPLIT';

  @override
  String get expenseDelete => 'Delete expense';

  @override
  String get expenseDeleting => 'Deleting…';

  @override
  String get expenseSuggestionExamples => 'Dinner';

  @override
  String get expenseSuggestionGroceries => 'Groceries';

  @override
  String get expenseSuggestionTaxi => 'Taxi';

  @override
  String get expenseSuggestionHotel => 'Hotel';

  @override
  String get expenseSuggestionDrinks => 'Drinks';

  @override
  String get settleTitle => 'Settle up';

  @override
  String get settleBody => 'The simplest way to clear everything:';

  @override
  String get settleAllSquare => 'Everyone is square.';

  @override
  String settleSummary(int payments, int expenses) {
    String _temp0 = intl.Intl.pluralLogic(
      payments,
      locale: localeName,
      other: '$payments payments',
      one: '1 payment',
    );
    return '$_temp0 instead of $expenses';
  }

  @override
  String get settleMarkAsPaid => 'Mark as paid';

  @override
  String get settleUndoTitle => 'Undo this repayment?';

  @override
  String get settleUndoBody =>
      'Everyone\'s balance goes back to what it was before it was recorded.';

  @override
  String get settleUndoAction => 'Undo this repayment';

  @override
  String get settleUndoing => 'Undoing…';

  @override
  String settleOnlySenderCanUndo(String name) {
    return 'Only $name can undo this.';
  }

  @override
  String get settleRepaymentTitle => 'Repayment';

  @override
  String groupPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get groupInvitePeople => 'Invite people';

  @override
  String get groupDangerZone => 'Danger zone';

  @override
  String get groupDeleteTrip => 'Delete trip';

  @override
  String get groupLeaveTrip => 'Leave trip';

  @override
  String groupJoined(String date) {
    return 'Joined $date';
  }

  @override
  String get inviteTitle => 'Invite people';

  @override
  String get inviteBody => 'Share a code and anyone can join this trip.';

  @override
  String get inviteCreate => 'Create an invite code';

  @override
  String get inviteNewCode => 'New code';

  @override
  String get inviteNotUsedYet => 'Not used yet';

  @override
  String inviteUsedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Used $count times',
      one: 'Used once',
    );
    return '$_temp0';
  }

  @override
  String get inviteCodeCopied => 'Code copied';

  @override
  String get inviteRevoke => 'Revoke this code';

  @override
  String get inviteCodeHint => 'ABCD1234';

  @override
  String get memberNoLongerHere => 'This person is no longer in the trip.';

  @override
  String get memberMakeOwner => 'Make owner';

  @override
  String get memberMakeOwnerDetail =>
      'They take over the trip, you become a member.';

  @override
  String get memberRemove => 'Remove from trip';

  @override
  String get memberRemoveDetail => 'They lose access immediately.';

  @override
  String get memberLeaveAndDelete => 'Leave and delete trip';

  @override
  String get memberLeaveBlocked =>
      'You\'re the owner. Make someone else the owner first.';

  @override
  String get memberLeaveLastOne =>
      'You\'re the only one left, so the trip goes too.';

  @override
  String get memberOwnerOnly => 'Only the owner can manage members.';

  @override
  String memberMakeOwnerTitle(String name) {
    return 'Make $name the owner?';
  }

  @override
  String memberMakeOwnerBody(String name) {
    return '$name will be able to invite people, remove members and delete the trip. You become a regular member, and only $name can give it back.';
  }

  @override
  String memberRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get memberRemoveBody =>
      'They lose access to this trip immediately. What they added stays: expenses, tasks and everyone else’s balances are untouched.';

  @override
  String get memberNotSettledTitle => 'Not settled up';

  @override
  String memberOwesAmount(String name, String amount) {
    return '$name owes $amount. Settle up before removing them.';
  }

  @override
  String memberIsOwedAmount(String name, String amount) {
    return '$name is owed $amount. Settle up before removing them.';
  }

  @override
  String memberYouOweAmount(String amount) {
    return 'You owe $amount. Settle up before leaving.';
  }

  @override
  String memberYouAreOwedAmount(String amount) {
    return 'You\'re owed $amount. Settle up before leaving.';
  }

  @override
  String get memberOwnerTitle => 'You\'re the owner';

  @override
  String get memberOwnerBody =>
      'Make someone else the owner before leaving, so the group keeps someone who can manage the trip.';

  @override
  String memberLeaveTitle(String trip) {
    return 'Leave $trip?';
  }

  @override
  String get memberLeaveBody =>
      'You\'ll lose access to the plan and expenses. Anything you already added stays with the group.';

  @override
  String memberLeaveDeleteTitle(String trip) {
    return 'Leave and delete $trip?';
  }

  @override
  String get memberLeaveDeleteBody =>
      'You\'re the only one left. Leaving will delete this trip and everything in it: expenses, calendar, tasks and lists. It cannot be undone.';

  @override
  String get memberLeaveDeleteAction => 'Leave and delete';

  @override
  String get memberLeaveAction => 'Leave';

  @override
  String tripDeleteTitle(String trip) {
    return 'Delete $trip?';
  }

  @override
  String get tripDeleteBody =>
      'This permanently deletes the plan, every expense and everyone’s balances. It cannot be undone.';

  @override
  String deleteItemTitle(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String deleteListTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteListEmptyBody => 'The list is removed for everyone.';

  @override
  String deleteListBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Its $count items go with it, for everyone.',
      one: 'Its 1 item goes with it, for everyone.',
    );
    return '$_temp0';
  }

  @override
  String deleteEntryTitle(String text) {
    return 'Remove \"$text\"?';
  }

  @override
  String deleteExpenseTitle(String description) {
    return 'Delete \"$description\"?';
  }

  @override
  String get deleteExpenseBody => 'Everyone\'s balance will be recalculated.';

  @override
  String get deleteExpenseWithRepayments =>
      'This trip has recorded repayments. Deleting this expense will change everyone\'s balance.';

  @override
  String get mapShareOn => 'You\'re sharing your location';

  @override
  String get mapShareOff => 'Share my location';

  @override
  String get mapShareForegroundOnly => 'Only while this map is open.';

  @override
  String get mapServicesOff => 'Location is switched off on this device.';

  @override
  String get mapPermissionDenied => 'Location permission was refused.';

  @override
  String get mapPermissionBlocked => 'Location is blocked for TodoTrip.';

  @override
  String get mapOpenSettings => 'Open settings';

  @override
  String get mapFitEveryone => 'Fit everyone';

  @override
  String get mapCentreOnMe => 'Centre on me';

  @override
  String get mapEmptyHint => 'Long-press anywhere to drop a pin.';

  @override
  String get mapAttribution => 'OpenStreetMap contributors';

  @override
  String get mapRightNow => 'Right now';

  @override
  String mapMinutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String mapLastSeen(String time) {
    return 'Last seen $time';
  }

  @override
  String get mapGetDirections => 'Get directions';

  @override
  String get mapAppleMaps => 'Apple Maps';

  @override
  String get mapGoogleMaps => 'Google Maps';

  @override
  String get pinNewTitle => 'New pin';

  @override
  String get pinNameLabel => 'What is here?';

  @override
  String get pinNameHint => 'Hostel Lisboa';

  @override
  String get pinCategoryLabel => 'CATEGORY';

  @override
  String get pinNotesLabel => 'Notes (optional)';

  @override
  String get pinDrop => 'Drop pin';

  @override
  String get pinDelete => 'Delete pin';

  @override
  String pinDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get pinDeleteBody => 'It disappears from the map for everyone.';

  @override
  String pinAddedBy(String name, String date) {
    return 'Added by $name · $date';
  }

  @override
  String get pinCategoryLodging => 'Lodging';

  @override
  String get pinCategoryFood => 'Food';

  @override
  String get pinCategoryMeetingPoint => 'Meeting point';

  @override
  String get pinCategoryParking => 'Parking';

  @override
  String get pinCategorySight => 'Sight';

  @override
  String get pinCategoryOther => 'Other';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsPushNotifications => 'Push notifications';

  @override
  String get settingsPushNotificationsBody => 'Trip updates and new tasks';

  @override
  String get settingsExpenseAlerts => 'Expense alerts';

  @override
  String get settingsExpenseAlertsBody => 'When someone adds an expense';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsDefaultCurrency => 'Default currency';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsSignOutTitle => 'Sign out?';

  @override
  String get settingsSignOutBody =>
      'You\'ll need your email and password to get back in.';

  @override
  String get tripStageNow => 'Now';

  @override
  String tripStageDayOf(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String get tripStageToday => 'Starts today';

  @override
  String get tripStageTomorrow => 'Tomorrow';

  @override
  String tripStageInDays(int days) {
    return 'In $days days';
  }

  @override
  String get tripStageEnded => 'Ended';

  @override
  String get moneySettledShort => 'Settled';

  @override
  String get commonJustNow => 'Just now';

  @override
  String commonMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String commonHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String commonDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get tripIconLabel => 'Icon';

  @override
  String get tripColorLabel => 'Colour';

  @override
  String get tripAddDescription => 'Add a description';

  @override
  String get tripDescriptionLabel => 'Description';

  @override
  String get commonSave => 'Save';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAccentColour => 'Accent colour';

  @override
  String get settingsAccentColourBody =>
      'Used for buttons, highlights and the tab bar.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSaved => 'Profile updated';

  @override
  String get profileEmailLocked =>
      'Changing your email needs the new address to be verified, which is not available yet.';

  @override
  String get profileChangePassword => 'Change password';

  @override
  String get profileChangePasswordBody => 'Signs you out everywhere else';

  @override
  String get profileChangePasswordWarning =>
      'Every other device signed in to this account will be signed out.';

  @override
  String get profileCurrentPassword => 'Current password';

  @override
  String get profileNewPassword => 'New password';

  @override
  String get profileRepeatPassword => 'Repeat new password';

  @override
  String get profilePasswordMismatch => 'The two passwords do not match';

  @override
  String get profileWrongPassword => 'That is not your current password';

  @override
  String get profilePasswordChanged => 'Password changed';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get profileDeleteTitle => 'Delete your account?';

  @override
  String get profileDeleteBody =>
      'Your name, email and password are erased and you are signed out everywhere. Expenses you took part in stay, without your name on them, because they decide what other people owe. This cannot be undone.';

  @override
  String get profileDeleteConfirm => 'Delete';

  @override
  String get profileDeleteOwnsTrips =>
      'You still own a trip other people are in. Hand it over to someone else, or delete it, then try again.';

  @override
  String get tripSettingsTitle => 'Trip settings';

  @override
  String get tripSettingsEdit => 'Edit';

  @override
  String get tripSettingsInfo => 'Information';

  @override
  String get tripSettingsPersonal => 'Just for you';

  @override
  String get tripSettingsDanger => 'Danger zone';

  @override
  String get tripCurrencyLabel => 'Currency';

  @override
  String get tripCurrencyWarning =>
      'Changing the currency won\'t convert existing expenses. Amounts stay the same, only the symbol changes.';

  @override
  String get tripSaveChanges => 'Save changes';

  @override
  String get tripSaved => 'Trip updated';

  @override
  String tripCreatedByOn(String name, String date) {
    return 'Created by $name on $date';
  }

  @override
  String tripStatMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String tripStatExpenses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return '$_temp0';
  }

  @override
  String tripStatItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plan entries',
      one: '1 plan entry',
    );
    return '$_temp0';
  }

  @override
  String get tripTotalSpent => 'Total spent';

  @override
  String get tripExportCsv => 'Export expenses as CSV';

  @override
  String get tripExportEmpty => 'There are no expenses to export yet.';

  @override
  String tripExportShareText(String trip) {
    return '$trip — expenses';
  }

  @override
  String get tripMuteLabel => 'Mute this trip';

  @override
  String get tripMuteBody => 'Stop getting notified about it';

  @override
  String get tripArchive => 'Archive trip';

  @override
  String get tripArchiveBody =>
      'Moves it out of your list. Everyone keeps reading it, nobody can add to it.';

  @override
  String get tripArchiveTitle => 'Archive this trip?';

  @override
  String get tripUnarchive => 'Bring back from the archive';

  @override
  String get tripArchivedBanner =>
      'This trip is archived. Nothing can be added to it.';

  @override
  String get tripsArchivedTitle => 'Archived';

  @override
  String tripsArchivedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archived trips',
      one: '1 archived trip',
    );
    return '$_temp0';
  }

  @override
  String get tripsArchivedEmpty => 'Nothing archived yet.';

  @override
  String get tripUnsavedChanges => 'You have unsaved changes';

  @override
  String get calendarYesterday => 'Yesterday';

  @override
  String get calendarStartsNow => 'Now';

  @override
  String calendarStartsInMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count min',
      one: 'in 1 min',
    );
    return '$_temp0';
  }

  @override
  String calendarStartsInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count hours',
      one: 'in 1 hour',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsEmptyTitle => 'You\'re all caught up';

  @override
  String get notificationsEmptyBody =>
      'New expenses, plans and people\nwill show up here.';

  @override
  String notificationExpenseAdded(
    String actor,
    String amount,
    String description,
  ) {
    return '$actor added $amount for $description';
  }

  @override
  String notificationExpenseDeleted(String actor, String description) {
    return '$actor deleted the expense for $description';
  }

  @override
  String notificationSettlement(String actor, String amount) {
    return '$actor paid you back $amount';
  }

  @override
  String notificationTaskAssigned(String actor, String title) {
    return '$actor gave you “$title”';
  }

  @override
  String notificationEventAdded(String actor, String title) {
    return '$actor added $title to the plan';
  }

  @override
  String notificationMemberJoined(String actor) {
    return '$actor joined the trip';
  }

  @override
  String notificationSomethingHappened(String actor) {
    return '$actor did something in this trip';
  }

  @override
  String get settingsMuteTrip => 'Mute this trip';

  @override
  String get settingsMuteTripBody => 'Stop being notified about it';

  @override
  String get notificationsClearAll => 'Clear all';

  @override
  String get notificationsClearAllTitle => 'Clear all notifications?';

  @override
  String get notificationsClearAllBody =>
      'They disappear for you only. This cannot be undone.';

  @override
  String get notificationDeleteTitle => 'Delete this notification?';

  @override
  String get notificationDeleteBody =>
      'It disappears for you only. Whatever it was about stays.';
}
