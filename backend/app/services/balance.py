"""Pure balance arithmetic: no database, no HTTP, no I/O.

Isolating this makes the interesting part of the app testable in microseconds,
and keeps the money rules readable in one screen. Every amount is an integer
number of cents; floats never appear.
"""

from dataclasses import dataclass
from uuid import UUID


@dataclass(frozen=True)
class Transfer:
    """One payment that would move the group closer to settled."""

    from_user_id: UUID
    to_user_id: UUID
    amount_cents: int


def split_evenly(total_cents: int, user_ids: list[UUID], payer_id: UUID) -> dict[UUID, int]:
    """Divide an amount so the shares always sum back to the total.

    10.00 EUR across three people is 3.34 + 3.33 + 3.33, never 3.33 x 3, which
    would lose a cent. The remainder goes to the payer: they are out of pocket
    already, so absorbing the extra cent is the fair default.
    """
    if not user_ids:
        raise ValueError("cannot split between zero people")

    base, remainder = divmod(total_cents, len(user_ids))
    shares = {user_id: base for user_id in user_ids}

    # Hand out the leftover cents one by one, starting with the payer.
    ordered = sorted(user_ids, key=lambda uid: uid != payer_id)
    for user_id in ordered[:remainder]:
        shares[user_id] += 1
    return shares


def compute_balances(
    expenses: list[tuple[UUID, dict[UUID, int]]],
    settlements: list[tuple[UUID, UUID, int]],
) -> dict[UUID, int]:
    """Net position per person: positive means owed money, negative means owing.

    Balances are always derived, never stored. Persisting them would create a
    second source of truth that drifts the moment an expense is edited.

    expenses:    (payer_id, {user_id: share_cents})
    settlements: (from_user_id, to_user_id, amount_cents)
    """
    balances: dict[UUID, int] = {}

    for payer_id, shares in expenses:
        total = sum(shares.values())
        # The payer fronted the whole amount and owes only their own share.
        balances[payer_id] = balances.get(payer_id, 0) + total
        for user_id, share in shares.items():
            balances[user_id] = balances.get(user_id, 0) - share

    # A repayment cancels debt: the sender's deficit shrinks, so does the
    # receiver's credit.
    for from_user_id, to_user_id, amount in settlements:
        balances[from_user_id] = balances.get(from_user_id, 0) + amount
        balances[to_user_id] = balances.get(to_user_id, 0) - amount

    return balances


def simplify_debts(balances: dict[UUID, int]) -> list[Transfer]:
    """Turn net balances into the fewest transfers that clear them.

    Six friends with twenty crossed expenses usually settle in three payments
    rather than twenty reversals. The greedy pairing of the largest debtor with
    the largest creditor is not provably minimal in every case (that problem is
    NP-hard), but it is optimal whenever no subset happens to cancel out, and it
    never produces more than n-1 transfers.
    """
    debtors = sorted(
        ((uid, -amount) for uid, amount in balances.items() if amount < 0),
        key=lambda pair: (-pair[1], pair[0].bytes),
    )
    creditors = sorted(
        ((uid, amount) for uid, amount in balances.items() if amount > 0),
        key=lambda pair: (-pair[1], pair[0].bytes),
    )

    transfers: list[Transfer] = []
    i = j = 0
    while i < len(debtors) and j < len(creditors):
        debtor_id, owed = debtors[i]
        creditor_id, due = creditors[j]
        amount = min(owed, due)

        transfers.append(
            Transfer(from_user_id=debtor_id, to_user_id=creditor_id, amount_cents=amount)
        )

        # Whoever is fully settled advances; a partial match keeps the remainder
        # in play for the next pairing.
        owed -= amount
        due -= amount
        debtors[i] = (debtor_id, owed)
        creditors[j] = (creditor_id, due)
        if owed == 0:
            i += 1
        if due == 0:
            j += 1

    return transfers
