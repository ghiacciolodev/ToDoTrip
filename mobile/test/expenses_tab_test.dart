import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todotrip/l10n/app_localizations.dart';
import 'package:todotrip/core/providers.dart';
import 'package:todotrip/features/auth/data/user.dart';
import 'package:todotrip/features/trips/data/expense.dart';
import 'package:todotrip/features/trips/data/settlement.dart';
import 'package:todotrip/features/trips/data/trip_member.dart';
import 'package:todotrip/features/trips/presentation/tabs/expenses_tab.dart';
import 'package:todotrip/features/trips/providers.dart';

/// Repayments have to be on screen: they move the balances as much as expenses
/// do, and one left over after its expense was deleted is the whole reason the
/// figures looked wrong with nothing to explain them.
class _FakeAuth extends AuthNotifier {
  _FakeAuth(this.user);

  final User user;

  @override
  Future<User?> build() async => user;
}

void main() {
  final me = User(
    id: 'mario',
    email: 'mario@test.it',
    displayName: 'Mario',
    createdAt: DateTime(2026),
  );

  TripMember member(String id, String name) => TripMember(
    user: User(
      id: id,
      email: '$id@test.it',
      displayName: name,
      createdAt: DateTime(2026),
    ),
    role: MemberRole.member,
    joinedAt: DateTime(2026),
  );

  final expense = Expense(
    id: 'e1',
    tripId: 't',
    description: 'Cena',
    amountCents: 6000,
    currency: 'EUR',
    paidBy: 'mario',
    spentAt: DateTime(2026, 7, 20, 20),
    createdBy: 'mario',
    createdAt: DateTime(2026, 7, 20, 20),
    shares: const [
      ExpenseShare(userId: 'mario', shareCents: 3000),
      ExpenseShare(userId: 'luca', shareCents: 3000),
    ],
  );

  final repayment = Settlement(
    id: 's1',
    tripId: 't',
    fromUserId: 'luca',
    toUserId: 'mario',
    amountCents: 3000,
    settledAt: DateTime(2026, 7, 21, 9),
  );

  Future<void> pump(
    WidgetTester tester, {
    required List<Expense> expenses,
    required List<Settlement> settlements,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => _FakeAuth(me)),
          expensesProvider('t').overrideWith((ref) async => expenses),
          settlementsProvider('t').overrideWith((ref) async => settlements),
          balanceProvider('t').overrideWith(
            (ref) async => const BalanceReport(
              balances: [],
              suggestedTransfers: [],
              totalSpentCents: 0,
            ),
          ),
          tripMembersProvider('t').overrideWith(
            (ref) async => [member('mario', 'Mario'), member('luca', 'Luca')],
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ExpensesTab(tripId: 't')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a repayment is listed next to the expenses', (tester) async {
    await pump(tester, expenses: [expense], settlements: [repayment]);

    expect(tester.takeException(), isNull);
    expect(find.text('Cena'), findsOne);
    expect(find.text('Luca paid you'), findsOne);
    expect(find.text('Repayment'), findsOne);
  });

  testWidgets('a repayment left without its expense is still visible', (
    tester,
  ) async {
    /// The reported bug: the expense is gone, the repayment is not, and the
    /// balances move with nothing on screen behind them.
    await pump(tester, expenses: [], settlements: [repayment]);

    expect(tester.takeException(), isNull);
    expect(find.text('Luca paid you'), findsOne);
    expect(find.text('No expenses yet'), findsNothing);
  });

  testWidgets('nothing at all still shows the empty state', (tester) async {
    await pump(tester, expenses: [], settlements: []);

    expect(tester.takeException(), isNull);
    expect(find.text('No expenses yet'), findsOne);
  });
}
