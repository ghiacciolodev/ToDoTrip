"""Balance arithmetic tests.

No database, no HTTP: these run in milliseconds and cover the only part of the
app where a bug silently costs people money.
"""

from uuid import UUID

import pytest

from app.services.balance import compute_balances, simplify_debts, split_evenly

A = UUID("00000000-0000-0000-0000-00000000000a")
B = UUID("00000000-0000-0000-0000-00000000000b")
C = UUID("00000000-0000-0000-0000-00000000000c")
D = UUID("00000000-0000-0000-0000-00000000000d")


class TestSplit:
    def test_exact_division(self):
        assert split_evenly(3000, [A, B, C], payer_id=A) == {A: 1000, B: 1000, C: 1000}

    def test_shares_always_sum_to_the_total(self):
        """The invariant that matters: no cent is created or destroyed."""
        for total in range(1, 500):
            shares = split_evenly(total, [A, B, C], payer_id=A)
            assert sum(shares.values()) == total

    def test_remainder_goes_to_the_payer(self):
        # 10.00 across three: 3.34 + 3.33 + 3.33
        assert split_evenly(1000, [A, B, C], payer_id=A) == {A: 334, B: 333, C: 333}

    def test_remainder_follows_whoever_paid(self):
        assert split_evenly(1000, [A, B, C], payer_id=B)[B] == 334

    def test_single_person_takes_everything(self):
        assert split_evenly(999, [A], payer_id=A) == {A: 999}

    def test_empty_group_is_rejected(self):
        with pytest.raises(ValueError):
            split_evenly(100, [], payer_id=A)


class TestBalances:
    def test_payer_is_owed_the_others_shares(self):
        # A pays 30.00 for three people.
        balances = compute_balances([(A, {A: 1000, B: 1000, C: 1000})], [])
        assert balances == {A: 2000, B: -1000, C: -1000}

    def test_balances_always_sum_to_zero(self):
        """Money is conserved: every credit has a matching debit."""
        balances = compute_balances(
            [(A, {A: 334, B: 333, C: 333}), (B, {A: 750, B: 750})],
            [],
        )
        assert sum(balances.values()) == 0

    def test_paying_only_for_yourself_is_neutral(self):
        assert compute_balances([(A, {A: 500})], []) == {A: 0}

    def test_an_expense_you_are_not_part_of_still_counts(self):
        """A pays for B and C only: A is owed the full amount."""
        balances = compute_balances([(A, {B: 500, C: 500})], [])
        assert balances == {A: 1000, B: -500, C: -500}

    def test_settlement_reduces_debt(self):
        balances = compute_balances(
            [(A, {A: 1000, B: 1000})],
            [(B, A, 1000)],
        )
        assert balances == {A: 0, B: 0}

    def test_partial_settlement(self):
        balances = compute_balances([(A, {A: 1000, B: 1000})], [(B, A, 400)])
        assert balances == {A: 600, B: -600}

    def test_nothing_spent_means_nothing_owed(self):
        assert compute_balances([], []) == {}

    def test_a_settlement_with_no_expense_left_reverses_it(self):
        """What "the balances went wrong after I deleted an expense" really is.

        Deleting an expense removes its shares but not the repayment made against
        it: B genuinely handed A 10.00 for something that no longer exists, so B
        is owed it back. Pinned here because the arithmetic is right and the
        result looks inexplicable unless the repayment is visible.
        """
        assert compute_balances([], [(B, A, 1000)]) == {A: -1000, B: 1000}

    def test_opposite_settlements_cancel_out(self):
        """Two repayments in opposite directions leave no trace, which is why an
        orphaned pair can hide in plain sight."""
        assert compute_balances([], [(B, A, 1000), (A, B, 1000)]) == {A: 0, B: 0}


class TestSimplify:
    def test_single_debt(self):
        transfers = simplify_debts({A: 1000, B: -1000})
        assert len(transfers) == 1
        assert transfers[0].from_user_id == B
        assert transfers[0].to_user_id == A
        assert transfers[0].amount_cents == 1000

    def test_transfers_clear_every_balance(self):
        """The property that matters: applying the transfers settles everyone."""
        balances = {A: 2500, B: -1000, C: -1500, D: 0}
        residual = dict(balances)
        for transfer in simplify_debts(balances):
            residual[transfer.from_user_id] += transfer.amount_cents
            residual[transfer.to_user_id] -= transfer.amount_cents
        assert all(value == 0 for value in residual.values())

    def test_settled_group_needs_no_transfers(self):
        assert simplify_debts({A: 0, B: 0, C: 0}) == []

    def test_never_exceeds_n_minus_one_transfers(self):
        balances = {A: 3000, B: -1000, C: -1000, D: -1000}
        assert len(simplify_debts(balances)) <= len(balances) - 1

    def test_circular_debt_collapses(self):
        """A owes B, B owes C, C owes A, all 10.00: nobody needs to pay anyone."""
        assert simplify_debts({A: 0, B: 0, C: 0}) == []

    def test_no_transfer_is_a_self_payment(self):
        for transfer in simplify_debts({A: 1500, B: -500, C: -1000}):
            assert transfer.from_user_id != transfer.to_user_id

    def test_every_transfer_is_positive(self):
        for transfer in simplify_debts({A: 700, B: -300, C: -400}):
            assert transfer.amount_cents > 0

    def test_is_deterministic(self):
        """Equal amounts must not reorder between runs, or the UI flickers."""
        balances = {A: 1000, B: 1000, C: -1000, D: -1000}
        first = simplify_debts(balances)
        second = simplify_debts(balances)
        assert first == second
