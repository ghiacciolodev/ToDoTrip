import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
  ];

  /// Application name, shown as the task title
  ///
  /// In en, this message translates to:
  /// **'TodoTrip'**
  String get appTitle;

  /// Dismisses a dialog without acting
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Confirms a destructive action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Confirms removing one item from a list
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// Confirms taking an action back
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// Retries a request that failed
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// Empties an optional field
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// Copies a value to the clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// Acknowledges a message with nothing to decide
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// The signed-in person, at the start of a sentence
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get commonYou;

  /// The signed-in person, inside a sentence
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get commonYouLower;

  /// A person whose name is not available, sentence start
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get commonSomeone;

  /// A person whose name is not available, mid sentence
  ///
  /// In en, this message translates to:
  /// **'someone'**
  String get commonSomeoneLower;

  /// Placeholder for a name that cannot be resolved
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknown;

  /// The member who administers a trip
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get commonOwner;

  /// A regular member of a trip
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get commonMember;

  /// Marks a settings row that does nothing yet
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get commonComingSoon;

  /// Fallback when a request fails for an unknown reason
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// Shown when a request times out
  ///
  /// In en, this message translates to:
  /// **'Slow connection. Try again.'**
  String get errorSlowConnection;

  /// Shown when the device has no route to the API
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server.'**
  String get errorNoConnection;

  /// Shown when the server rejects a form
  ///
  /// In en, this message translates to:
  /// **'Please check the details you entered'**
  String get errorInvalidData;

  /// Sign-in failure, deliberately not saying which is wrong
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get errorWrongCredentials;

  /// Sign-up failure on a duplicate email
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get errorEmailTaken;

  /// Covers unknown, revoked, expired and exhausted invite codes
  ///
  /// In en, this message translates to:
  /// **'That code is invalid or has expired'**
  String get errorInvalidCode;

  /// Shown when no application can handle a directions link
  ///
  /// In en, this message translates to:
  /// **'No maps app to open this with.'**
  String get errorNoMapsApp;

  /// Shown when the server refuses for lack of permission
  ///
  /// In en, this message translates to:
  /// **'You are not allowed to do that.'**
  String get errorNotAllowed;

  /// Shown when the thing acted on has been deleted
  ///
  /// In en, this message translates to:
  /// **'That is no longer there.'**
  String get errorNotFound;

  /// Sign-up screen heading
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authCreateAccount;

  /// Sign-in screen heading
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// One-line description under the sign-in heading
  ///
  /// In en, this message translates to:
  /// **'Plan trips together with your friends'**
  String get authTagline;

  /// Display name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get authNameLabel;

  /// Validation message for an empty name
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get authNameEmpty;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// Validation message for an empty email
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailEmpty;

  /// Validation message for a malformed email
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authEmailInvalid;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// Validation message for an empty password
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordEmpty;

  /// Minimum password length, matching the API rule
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authPasswordTooShort;

  /// Accessibility label for the reveal button
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// Accessibility label for the hide button
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// Submits the sign-in form
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// Submits the sign-up form
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUp;

  /// Switches from sign-up to sign-in
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authSwitchToSignIn;

  /// Switches from sign-in to sign-up
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get authSwitchToSignUp;

  /// Bottom navigation: the list of trips
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get navTrips;

  /// Bottom navigation: create or join a trip
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get navAdd;

  /// Bottom navigation: app settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Title of the trips list
  ///
  /// In en, this message translates to:
  /// **'My trips'**
  String get tripsTitle;

  /// Heading when the user belongs to no trip
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get tripsEmptyTitle;

  /// Explains the two ways in; the line break is intentional
  ///
  /// In en, this message translates to:
  /// **'Create your first trip, or join one\nwith a code from a friend.'**
  String get tripsEmptyBody;

  /// Opens the create-or-join screen
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get tripsEmptyAction;

  /// Title of the create-or-join screen
  ///
  /// In en, this message translates to:
  /// **'Add a trip'**
  String get addTripTitle;

  /// Starts a new trip
  ///
  /// In en, this message translates to:
  /// **'Create a trip'**
  String get addTripCreate;

  /// Subtitle for creating a trip
  ///
  /// In en, this message translates to:
  /// **'Start planning and invite your friends'**
  String get addTripCreateBody;

  /// Joins an existing trip
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get addTripJoin;

  /// Subtitle for joining a trip
  ///
  /// In en, this message translates to:
  /// **'Someone shared an invite code with you'**
  String get addTripJoinBody;

  /// Heading of the create-trip sheet
  ///
  /// In en, this message translates to:
  /// **'New trip'**
  String get tripNewTitle;

  /// The only required field when creating a trip
  ///
  /// In en, this message translates to:
  /// **'Trip name'**
  String get tripNameLabel;

  /// Validation message for an empty trip name
  ///
  /// In en, this message translates to:
  /// **'Give your trip a name'**
  String get tripNameEmpty;

  /// Opens the date range picker
  ///
  /// In en, this message translates to:
  /// **'Add dates (optional)'**
  String get tripAddDates;

  /// Removes the chosen dates
  ///
  /// In en, this message translates to:
  /// **'Clear dates'**
  String get tripClearDates;

  /// Submits the create-trip form
  ///
  /// In en, this message translates to:
  /// **'Create trip'**
  String get tripCreate;

  /// Heading of the join sheet
  ///
  /// In en, this message translates to:
  /// **'Join a trip'**
  String get tripJoinTitle;

  /// Instruction above the code field
  ///
  /// In en, this message translates to:
  /// **'Enter the code a friend shared with you'**
  String get tripJoinBody;

  /// Validation message for an empty invite code
  ///
  /// In en, this message translates to:
  /// **'Enter the code you were given'**
  String get tripJoinCodeEmpty;

  /// Submits the join form
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get tripJoin;

  /// Shown on a trip with no dates set
  ///
  /// In en, this message translates to:
  /// **'No dates yet'**
  String get tripNoDates;

  /// A trip with a start date but no end date
  ///
  /// In en, this message translates to:
  /// **'From {date}'**
  String tripDatesFrom(String date);

  /// A trip with an end date but no start date
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String tripDatesUntil(String date);

  /// App bar title while the trip is still loading
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get tripFallbackName;

  /// Trip tab: dated events
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get tabCalendar;

  /// Trip tab: to-dos and lists
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tabTasks;

  /// Trip tab: expenses and balances
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get tabMoney;

  /// Trip tab: pins and live locations
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get tabMap;

  /// Trip tab: members and invites
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get tabGroup;

  /// Action button on the calendar tab
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get fabEvent;

  /// Action button on the to-do view
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get fabTask;

  /// Action button on the lists view
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get fabList;

  /// Action button on the money tab
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get fabExpense;

  /// Heading when a trip has no events
  ///
  /// In en, this message translates to:
  /// **'Nothing planned yet'**
  String get calendarEmptyTitle;

  /// Examples of what an event is
  ///
  /// In en, this message translates to:
  /// **'Add flights, check-ins and\nanything with a time on it.'**
  String get calendarEmptyBody;

  /// Badge on an event happening today, uppercase
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get calendarToday;

  /// Badge on an event happening tomorrow, uppercase
  ///
  /// In en, this message translates to:
  /// **'TOMORROW'**
  String get calendarTomorrow;

  /// Segmented control: the trip's tasks
  ///
  /// In en, this message translates to:
  /// **'To-do'**
  String get tasksViewTodo;

  /// Segmented control: named checklists
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get tasksViewLists;

  /// Heading when a trip has no tasks
  ///
  /// In en, this message translates to:
  /// **'Nothing to do yet'**
  String get tasksEmptyTitle;

  /// Examples of what a task is
  ///
  /// In en, this message translates to:
  /// **'Book the hostel, buy sunscreen,\nsplit the driving.'**
  String get tasksEmptyBody;

  /// Header of the collapsed section of finished tasks
  ///
  /// In en, this message translates to:
  /// **'{count} completed'**
  String tasksCompletedCount(int count);

  /// A task past its deadline; the word carries the meaning, not the colour
  ///
  /// In en, this message translates to:
  /// **'Overdue · {date}'**
  String tasksOverdue(String date);

  /// A task due today
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String tasksDueToday(String time);

  /// A task due tomorrow
  ///
  /// In en, this message translates to:
  /// **'Tomorrow, {time}'**
  String tasksDueTomorrow(String time);

  /// Heading when a trip has no checklists
  ///
  /// In en, this message translates to:
  /// **'No lists yet'**
  String get listsEmptyTitle;

  /// Examples of what a list is for
  ///
  /// In en, this message translates to:
  /// **'A shopping list, things to pack,\nplaces you want to try.'**
  String get listsEmptyBody;

  /// A checklist with no entries
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get listEmpty;

  /// Every entry of a checklist is ticked
  ///
  /// In en, this message translates to:
  /// **'All done'**
  String get listAllDone;

  /// Checklist progress; what is missing matters more than what is done
  ///
  /// In en, this message translates to:
  /// **'{left} left of {total}'**
  String listLeftOf(int left, int total);

  /// Checklist progress in the app bar
  ///
  /// In en, this message translates to:
  /// **'{checked} of {total}'**
  String listProgress(int checked, int total);

  /// App bar title while a checklist loads
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listTitle;

  /// The checklist was deleted by someone else
  ///
  /// In en, this message translates to:
  /// **'This list is gone'**
  String get listGoneTitle;

  /// Explains why the list disappeared
  ///
  /// In en, this message translates to:
  /// **'Someone in the group deleted it.'**
  String get listGoneBody;

  /// Heading for an empty checklist
  ///
  /// In en, this message translates to:
  /// **'Nothing on it yet'**
  String get listEntriesEmptyTitle;

  /// Explains the always-ready composer
  ///
  /// In en, this message translates to:
  /// **'Type below and tap +.\nThe field stays ready for the next one.'**
  String get listEntriesEmptyBody;

  /// Placeholder of the checklist composer
  ///
  /// In en, this message translates to:
  /// **'Add an item'**
  String get listAddItem;

  /// Heading of the create-event sheet
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get itemNewEvent;

  /// Heading of the create-task sheet
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get itemNewTask;

  /// Heading of the create-list sheet
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get itemNewList;

  /// Title field for an event
  ///
  /// In en, this message translates to:
  /// **'What is happening?'**
  String get itemEventLabel;

  /// Title field for a task
  ///
  /// In en, this message translates to:
  /// **'What needs doing?'**
  String get itemTaskLabel;

  /// Name field for a checklist
  ///
  /// In en, this message translates to:
  /// **'What is the list for?'**
  String get itemListLabel;

  /// Example checklist name
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get itemListHint;

  /// Opens the picker for an event, which requires a time
  ///
  /// In en, this message translates to:
  /// **'Pick a date and time'**
  String get itemPickDateTime;

  /// Opens the picker for a task, where a time is optional
  ///
  /// In en, this message translates to:
  /// **'Add a deadline (optional)'**
  String get itemAddDeadline;

  /// Location field for an event
  ///
  /// In en, this message translates to:
  /// **'Where? (optional)'**
  String get itemWhereOptional;

  /// Section label above the member chips, uppercase
  ///
  /// In en, this message translates to:
  /// **'ASSIGN TO'**
  String get itemAssignTo;

  /// Explains that assignees are optional
  ///
  /// In en, this message translates to:
  /// **'Leave empty and anyone can pick it up.'**
  String get itemAssignHint;

  /// Submits the event form
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get itemAddEvent;

  /// Submits the task form
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get itemAddTask;

  /// Submits the list form
  ///
  /// In en, this message translates to:
  /// **'Add list'**
  String get itemAddList;

  /// The signed-in user owes nothing and is owed nothing
  ///
  /// In en, this message translates to:
  /// **'All settled'**
  String get moneyAllSettled;

  /// Label above a positive balance
  ///
  /// In en, this message translates to:
  /// **'You are owed'**
  String get moneyYouAreOwed;

  /// Label above a negative balance
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get moneyYouOwe;

  /// Everything the group has spent
  ///
  /// In en, this message translates to:
  /// **'Trip total {amount}'**
  String moneyTripTotal(String amount);

  /// Opens the repayment suggestions
  ///
  /// In en, this message translates to:
  /// **'Settle up'**
  String get moneySettleUp;

  /// Expands the per-member balances
  ///
  /// In en, this message translates to:
  /// **'Everyone\'s balance'**
  String get moneyEveryonesBalance;

  /// Heading when a trip has no expenses
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get moneyEmptyTitle;

  /// Explains what the tab will do
  ///
  /// In en, this message translates to:
  /// **'Add the first one and we’ll keep\ntrack of who owes what.'**
  String get moneyEmptyBody;

  /// Who fronted an expense
  ///
  /// In en, this message translates to:
  /// **'Paid by {name}'**
  String moneyPaidBy(String name);

  /// What an expense costs the signed-in user
  ///
  /// In en, this message translates to:
  /// **'you: {amount}'**
  String moneyYourShare(String amount);

  /// The signed-in user has no share in this expense
  ///
  /// In en, this message translates to:
  /// **'not involved'**
  String get moneyNotInvolved;

  /// Marks a row as money moved between members, not a cost
  ///
  /// In en, this message translates to:
  /// **'Repayment'**
  String get moneyRepayment;

  /// A recorded repayment between two members
  ///
  /// In en, this message translates to:
  /// **'{payer} paid {payee}'**
  String moneyPaidSomeone(String payer, String payee);

  /// Day header for today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get moneyToday;

  /// Day header for yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get moneyYesterday;

  /// Title of the add-expense screen
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get expenseNewTitle;

  /// Description field of an expense
  ///
  /// In en, this message translates to:
  /// **'What for?'**
  String get expenseWhatFor;

  /// Section label above the payer chips, uppercase
  ///
  /// In en, this message translates to:
  /// **'PAID BY'**
  String get expensePaidBy;

  /// Section label above the participant chips, uppercase
  ///
  /// In en, this message translates to:
  /// **'SPLIT BETWEEN'**
  String get expenseSplitBetween;

  /// Divides the amount evenly
  ///
  /// In en, this message translates to:
  /// **'Split equally'**
  String get expenseSplitEqually;

  /// Lets each share be typed in
  ///
  /// In en, this message translates to:
  /// **'Custom amounts'**
  String get expenseCustomAmounts;

  /// What is left to assign in a custom split
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get expenseRemaining;

  /// Submits the expense form
  ///
  /// In en, this message translates to:
  /// **'Save expense'**
  String get expenseSave;

  /// Section label in the expense detail, uppercase
  ///
  /// In en, this message translates to:
  /// **'SPLIT'**
  String get expenseSplitLabel;

  /// Deletes the expense being viewed
  ///
  /// In en, this message translates to:
  /// **'Delete expense'**
  String get expenseDelete;

  /// Shown while the delete request is in flight
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get expenseDeleting;

  /// Quick-fill suggestion: a meal out
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get expenseSuggestionExamples;

  /// Quick-fill suggestion: food shopping
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get expenseSuggestionGroceries;

  /// Quick-fill suggestion: a ride
  ///
  /// In en, this message translates to:
  /// **'Taxi'**
  String get expenseSuggestionTaxi;

  /// Quick-fill suggestion: accommodation
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get expenseSuggestionHotel;

  /// Quick-fill suggestion: a round of drinks
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get expenseSuggestionDrinks;

  /// Heading of the settle-up sheet
  ///
  /// In en, this message translates to:
  /// **'Settle up'**
  String get settleTitle;

  /// Introduces the suggested transfers
  ///
  /// In en, this message translates to:
  /// **'The simplest way to clear everything:'**
  String get settleBody;

  /// Nothing left to repay
  ///
  /// In en, this message translates to:
  /// **'Everyone is square.'**
  String get settleAllSquare;

  /// How much simpler the suggested transfers are than repaying every expense
  ///
  /// In en, this message translates to:
  /// **'{payments, plural, =1{1 payment} other{{payments} payments}} instead of {expenses}'**
  String settleSummary(int payments, int expenses);

  /// Records one suggested transfer as done
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get settleMarkAsPaid;

  /// Confirmation before removing a recorded repayment
  ///
  /// In en, this message translates to:
  /// **'Undo this repayment?'**
  String get settleUndoTitle;

  /// Explains the effect of undoing a repayment
  ///
  /// In en, this message translates to:
  /// **'Everyone\'s balance goes back to what it was before it was recorded.'**
  String get settleUndoBody;

  /// Removes a recorded repayment
  ///
  /// In en, this message translates to:
  /// **'Undo this repayment'**
  String get settleUndoAction;

  /// Shown while the undo request is in flight
  ///
  /// In en, this message translates to:
  /// **'Undoing…'**
  String get settleUndoing;

  /// A repayment can only be taken back by whoever recorded it
  ///
  /// In en, this message translates to:
  /// **'Only {name} can undo this.'**
  String settleOnlySenderCanUndo(String name);

  /// Heading of the repayment detail sheet
  ///
  /// In en, this message translates to:
  /// **'Repayment'**
  String get settleRepaymentTitle;

  /// How many members a trip has
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}}'**
  String groupPeopleCount(int count);

  /// Opens the invite sheet; owner only
  ///
  /// In en, this message translates to:
  /// **'Invite people'**
  String get groupInvitePeople;

  /// Section label above destructive actions
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get groupDangerZone;

  /// Deletes the whole trip; owner only
  ///
  /// In en, this message translates to:
  /// **'Delete trip'**
  String get groupDeleteTrip;

  /// Removes the signed-in user from the trip
  ///
  /// In en, this message translates to:
  /// **'Leave trip'**
  String get groupLeaveTrip;

  /// When a member joined the trip
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String groupJoined(String date);

  /// Heading of the invite sheet
  ///
  /// In en, this message translates to:
  /// **'Invite people'**
  String get inviteTitle;

  /// Explains what an invite code does
  ///
  /// In en, this message translates to:
  /// **'Share a code and anyone can join this trip.'**
  String get inviteBody;

  /// Generates the first code
  ///
  /// In en, this message translates to:
  /// **'Create an invite code'**
  String get inviteCreate;

  /// Generates an additional code
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get inviteNewCode;

  /// A code nobody has redeemed
  ///
  /// In en, this message translates to:
  /// **'Not used yet'**
  String get inviteNotUsedYet;

  /// How many people joined with a code
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Used once} other{Used {count} times}}'**
  String inviteUsedCount(int count);

  /// Confirmation after copying a code
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get inviteCodeCopied;

  /// Stops a code from working
  ///
  /// In en, this message translates to:
  /// **'Revoke this code'**
  String get inviteRevoke;

  /// Example invite code shown as a field hint
  ///
  /// In en, this message translates to:
  /// **'ABCD1234'**
  String get inviteCodeHint;

  /// Shown when the member was removed while the sheet opened
  ///
  /// In en, this message translates to:
  /// **'This person is no longer in the trip.'**
  String get memberNoLongerHere;

  /// Hands the trip to another member
  ///
  /// In en, this message translates to:
  /// **'Make owner'**
  String get memberMakeOwner;

  /// Explains what transferring ownership does
  ///
  /// In en, this message translates to:
  /// **'They take over the trip, you become a member.'**
  String get memberMakeOwnerDetail;

  /// Removes another member; owner only
  ///
  /// In en, this message translates to:
  /// **'Remove from trip'**
  String get memberRemove;

  /// Explains what removing a member does
  ///
  /// In en, this message translates to:
  /// **'They lose access immediately.'**
  String get memberRemoveDetail;

  /// Leaving as the last member deletes the trip
  ///
  /// In en, this message translates to:
  /// **'Leave and delete trip'**
  String get memberLeaveAndDelete;

  /// Why an owner with company cannot leave yet
  ///
  /// In en, this message translates to:
  /// **'You\'re the owner. Make someone else the owner first.'**
  String get memberLeaveBlocked;

  /// Warns that leaving alone deletes the trip
  ///
  /// In en, this message translates to:
  /// **'You\'re the only one left, so the trip goes too.'**
  String get memberLeaveLastOne;

  /// Shown to a member looking at someone else
  ///
  /// In en, this message translates to:
  /// **'Only the owner can manage members.'**
  String get memberOwnerOnly;

  /// Confirmation before transferring ownership
  ///
  /// In en, this message translates to:
  /// **'Make {name} the owner?'**
  String memberMakeOwnerTitle(String name);

  /// Names what is given up, not only what is granted
  ///
  /// In en, this message translates to:
  /// **'{name} will be able to invite people, remove members and delete the trip. You become a regular member, and only {name} can give it back.'**
  String memberMakeOwnerBody(String name);

  /// Confirmation before removing a member
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String memberRemoveTitle(String name);

  /// Explains that removal keeps the shared history
  ///
  /// In en, this message translates to:
  /// **'They lose access to this trip immediately. What they added stays: expenses, tasks and everyone else’s balances are untouched.'**
  String get memberRemoveBody;

  /// Heading when money blocks a departure
  ///
  /// In en, this message translates to:
  /// **'Not settled up'**
  String get memberNotSettledTitle;

  /// A member cannot be removed while they owe money
  ///
  /// In en, this message translates to:
  /// **'{name} owes {amount}. Settle up before removing them.'**
  String memberOwesAmount(String name, String amount);

  /// A member cannot be removed while they are owed money
  ///
  /// In en, this message translates to:
  /// **'{name} is owed {amount}. Settle up before removing them.'**
  String memberIsOwedAmount(String name, String amount);

  /// The signed-in user cannot leave while they owe money
  ///
  /// In en, this message translates to:
  /// **'You owe {amount}. Settle up before leaving.'**
  String memberYouOweAmount(String amount);

  /// The signed-in user cannot leave while they are owed money
  ///
  /// In en, this message translates to:
  /// **'You\'re owed {amount}. Settle up before leaving.'**
  String memberYouAreOwedAmount(String amount);

  /// Heading when ownership blocks leaving
  ///
  /// In en, this message translates to:
  /// **'You\'re the owner'**
  String get memberOwnerTitle;

  /// Explains why an owner must hand over first
  ///
  /// In en, this message translates to:
  /// **'Make someone else the owner before leaving, so the group keeps someone who can manage the trip.'**
  String get memberOwnerBody;

  /// Confirmation before leaving a trip
  ///
  /// In en, this message translates to:
  /// **'Leave {trip}?'**
  String memberLeaveTitle(String trip);

  /// Explains what leaving costs
  ///
  /// In en, this message translates to:
  /// **'You\'ll lose access to the plan and expenses. Anything you already added stays with the group.'**
  String get memberLeaveBody;

  /// Confirmation when leaving would empty the trip
  ///
  /// In en, this message translates to:
  /// **'Leave and delete {trip}?'**
  String memberLeaveDeleteTitle(String trip);

  /// Explains that leaving alone destroys the trip
  ///
  /// In en, this message translates to:
  /// **'You\'re the only one left. Leaving will delete this trip and everything in it: expenses, calendar, tasks and lists. It cannot be undone.'**
  String get memberLeaveDeleteBody;

  /// Confirms leaving and deleting
  ///
  /// In en, this message translates to:
  /// **'Leave and delete'**
  String get memberLeaveDeleteAction;

  /// Confirms leaving a trip
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get memberLeaveAction;

  /// Confirmation before deleting a trip
  ///
  /// In en, this message translates to:
  /// **'Delete {trip}?'**
  String tripDeleteTitle(String trip);

  /// Names what is lost, and for whom
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes the plan, every expense and everyone’s balances. It cannot be undone.'**
  String get tripDeleteBody;

  /// Confirmation before deleting an event or task
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String deleteItemTitle(String title);

  /// Confirmation before deleting a checklist
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteListTitle(String name);

  /// Deleting a checklist with no entries
  ///
  /// In en, this message translates to:
  /// **'The list is removed for everyone.'**
  String get deleteListEmptyBody;

  /// Deleting a checklist takes its entries
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Its 1 item goes with it, for everyone.} other{Its {count} items go with it, for everyone.}}'**
  String deleteListBody(int count);

  /// Confirmation before removing one checklist entry
  ///
  /// In en, this message translates to:
  /// **'Remove \"{text}\"?'**
  String deleteEntryTitle(String text);

  /// Confirmation before deleting an expense
  ///
  /// In en, this message translates to:
  /// **'Delete \"{description}\"?'**
  String deleteExpenseTitle(String description);

  /// Deleting an expense with no repayments recorded
  ///
  /// In en, this message translates to:
  /// **'Everyone\'s balance will be recalculated.'**
  String get deleteExpenseBody;

  /// Warns that repayments outlive the expense they were made against
  ///
  /// In en, this message translates to:
  /// **'This trip has recorded repayments. Deleting this expense will change everyone\'s balance.'**
  String get deleteExpenseWithRepayments;

  /// State of the sharing switch when on; deliberately explicit
  ///
  /// In en, this message translates to:
  /// **'You\'re sharing your location'**
  String get mapShareOn;

  /// State of the sharing switch when off
  ///
  /// In en, this message translates to:
  /// **'Share my location'**
  String get mapShareOff;

  /// Sharing never runs in the background
  ///
  /// In en, this message translates to:
  /// **'Only while this map is open.'**
  String get mapShareForegroundOnly;

  /// The device has location services disabled
  ///
  /// In en, this message translates to:
  /// **'Location is switched off on this device.'**
  String get mapServicesOff;

  /// Permission refused, can be asked again
  ///
  /// In en, this message translates to:
  /// **'Location permission was refused.'**
  String get mapPermissionDenied;

  /// Permission refused permanently; only settings can undo it
  ///
  /// In en, this message translates to:
  /// **'Location is blocked for TodoTrip.'**
  String get mapPermissionBlocked;

  /// Opens the system settings for the app
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get mapOpenSettings;

  /// Frames every member visible on the map
  ///
  /// In en, this message translates to:
  /// **'Fit everyone'**
  String get mapFitEveryone;

  /// Moves the camera to the user's own position
  ///
  /// In en, this message translates to:
  /// **'Centre on me'**
  String get mapCentreOnMe;

  /// Teaches the gesture when the map has nothing on it
  ///
  /// In en, this message translates to:
  /// **'Long-press anywhere to drop a pin.'**
  String get mapEmptyHint;

  /// Required by the OpenStreetMap tile usage policy
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap contributors'**
  String get mapAttribution;

  /// A position reported less than two minutes ago
  ///
  /// In en, this message translates to:
  /// **'Right now'**
  String get mapRightNow;

  /// How old a reported position is
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String mapMinutesAgo(int count);

  /// A position older than an hour
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String mapLastSeen(String time);

  /// Opens the destination in a navigation app
  ///
  /// In en, this message translates to:
  /// **'Get directions'**
  String get mapGetDirections;

  /// Navigation app choice on iOS
  ///
  /// In en, this message translates to:
  /// **'Apple Maps'**
  String get mapAppleMaps;

  /// Navigation app choice
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get mapGoogleMaps;

  /// Heading of the create-pin sheet
  ///
  /// In en, this message translates to:
  /// **'New pin'**
  String get pinNewTitle;

  /// Name field of a pin
  ///
  /// In en, this message translates to:
  /// **'What is here?'**
  String get pinNameLabel;

  /// Example pin name
  ///
  /// In en, this message translates to:
  /// **'Hostel Lisboa'**
  String get pinNameHint;

  /// Section label above the category chips, uppercase
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get pinCategoryLabel;

  /// Description field of a pin
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get pinNotesLabel;

  /// Submits the pin form
  ///
  /// In en, this message translates to:
  /// **'Drop pin'**
  String get pinDrop;

  /// Deletes the pin being viewed
  ///
  /// In en, this message translates to:
  /// **'Delete pin'**
  String get pinDelete;

  /// Confirmation before deleting a pin
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String pinDeleteTitle(String name);

  /// Explains that pins are shared
  ///
  /// In en, this message translates to:
  /// **'It disappears from the map for everyone.'**
  String get pinDeleteBody;

  /// Who dropped a pin and when
  ///
  /// In en, this message translates to:
  /// **'Added by {name} · {date}'**
  String pinAddedBy(String name, String date);

  /// Pin category: where the group sleeps
  ///
  /// In en, this message translates to:
  /// **'Lodging'**
  String get pinCategoryLodging;

  /// Pin category: somewhere to eat
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get pinCategoryFood;

  /// Pin category: where to meet up
  ///
  /// In en, this message translates to:
  /// **'Meeting point'**
  String get pinCategoryMeetingPoint;

  /// Pin category: where the car is
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get pinCategoryParking;

  /// Pin category: something worth seeing
  ///
  /// In en, this message translates to:
  /// **'Sight'**
  String get pinCategorySight;

  /// Pin category: anything else
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get pinCategoryOther;

  /// Title of the settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section for notification switches
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// Master switch for notifications
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get settingsPushNotifications;

  /// What push notifications cover
  ///
  /// In en, this message translates to:
  /// **'Trip updates and new tasks'**
  String get settingsPushNotificationsBody;

  /// Switch for expense notifications
  ///
  /// In en, this message translates to:
  /// **'Expense alerts'**
  String get settingsExpenseAlerts;

  /// What expense alerts cover
  ///
  /// In en, this message translates to:
  /// **'When someone adds an expense'**
  String get settingsExpenseAlertsBody;

  /// Settings section for language and currency
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// Opens the language picker
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Follow the device language instead of choosing one
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// Currency preselected for new trips
  ///
  /// In en, this message translates to:
  /// **'Default currency'**
  String get settingsDefaultCurrency;

  /// Settings section for version and legal links
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Application version row
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// Opens the privacy policy
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// Ends the session
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// Confirmation before signing out
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get settingsSignOutTitle;

  /// Explains what signing out means
  ///
  /// In en, this message translates to:
  /// **'You\'ll need your email and password to get back in.'**
  String get settingsSignOutBody;

  /// Badge on a trip that is happening, with no end date
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get tripStageNow;

  /// How far into a trip today is
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String tripStageDayOf(int day, int total);

  /// Badge on a trip starting today
  ///
  /// In en, this message translates to:
  /// **'Starts today'**
  String get tripStageToday;

  /// Badge on a trip starting tomorrow
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tripStageTomorrow;

  /// How long until a trip starts
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String tripStageInDays(int days);

  /// Badge on a trip that is over
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get tripStageEnded;

  /// Balance chip when the caller owes nothing and is owed nothing
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get moneySettledShort;

  /// Something that happened less than a minute ago
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get commonJustNow;

  /// How long ago something happened, under an hour
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String commonMinutesAgo(int count);

  /// How long ago something happened, under a day
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String commonHoursAgo(int count);

  /// How long ago something happened, under a week
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String commonDaysAgo(int count);

  /// Heading of the icon row when creating a trip
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get tripIconLabel;

  /// Heading of the colour row when creating a trip
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get tripColorLabel;

  /// Reveals the optional description field
  ///
  /// In en, this message translates to:
  /// **'Add a description'**
  String get tripAddDescription;

  /// Label of the optional description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get tripDescriptionLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
