"""Expense use cases. The arithmetic lives in balance.py; this layer persists."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Expense, ExpenseShare, Settlement, TripMember
from app.services.balance import compute_balances, simplify_debts, split_evenly


class ExpenseNotFound(Exception):
    """No such expense inside this trip."""


class NotAllMembers(Exception):
    """Someone in the split does not belong to the trip."""


class SelfSettlement(Exception):
    """A member cannot repay themselves."""


class SettlementNotFound(Exception):
    """No such settlement inside this trip."""


class NotTheSender(Exception):
    """Only the member who recorded a repayment may take it back."""


async def _member_ids(db: AsyncSession, trip_id: UUID) -> set[UUID]:
    result = await db.execute(select(TripMember.user_id).where(TripMember.trip_id == trip_id))
    return set(result.scalars().all())


async def create_expense(db: AsyncSession, trip_id: UUID, user_id: UUID, data: dict) -> Expense:
    members = await _member_ids(db, trip_id)

    if data.get("shares") is not None:
        shares = {s["user_id"]: s["share_cents"] for s in data["shares"]}
    else:
        shares = split_evenly(data["amount_cents"], data["participants"], data["paid_by"])

    # Checked in one place, covering payer and every participant: an expense
    # involving an outsider would corrupt the whole trip's balances.
    if not ({data["paid_by"], *shares} <= members):
        raise NotAllMembers

    expense = Expense(
        trip_id=trip_id,
        created_by=user_id,
        description=data["description"],
        amount_cents=data["amount_cents"],
        paid_by=data["paid_by"],
        **({"spent_at": data["spent_at"]} if data.get("spent_at") else {}),
    )
    expense.shares = [ExpenseShare(user_id=uid, share_cents=cents) for uid, cents in shares.items()]
    db.add(expense)
    await db.commit()
    await db.refresh(expense)
    return expense


async def list_expenses(db: AsyncSession, trip_id: UUID) -> list[Expense]:
    result = await db.execute(
        select(Expense).where(Expense.trip_id == trip_id).order_by(Expense.spent_at.desc())
    )
    return list(result.scalars().all())


async def get_expense(db: AsyncSession, trip_id: UUID, expense_id: UUID) -> Expense:
    expense = await db.scalar(
        select(Expense).where(Expense.id == expense_id, Expense.trip_id == trip_id)
    )
    if expense is None:
        raise ExpenseNotFound
    return expense


async def delete_expense(db: AsyncSession, expense: Expense) -> None:
    """Shares go with it through cascade; balances recompute on the next read."""
    await db.delete(expense)
    await db.commit()


async def create_settlement(
    db: AsyncSession, trip_id: UUID, from_user_id: UUID, data: dict
) -> Settlement:
    if from_user_id == data["to_user_id"]:
        raise SelfSettlement
    members = await _member_ids(db, trip_id)
    if not ({from_user_id, data["to_user_id"]} <= members):
        raise NotAllMembers

    settlement = Settlement(
        trip_id=trip_id,
        from_user_id=from_user_id,
        to_user_id=data["to_user_id"],
        amount_cents=data["amount_cents"],
        note=data.get("note"),
    )
    db.add(settlement)
    await db.commit()
    await db.refresh(settlement)
    return settlement


async def get_settlement(db: AsyncSession, trip_id: UUID, settlement_id: UUID) -> Settlement:
    """Both ids are matched: a settlement id alone must never cross trip boundaries."""
    settlement = await db.scalar(
        select(Settlement).where(Settlement.id == settlement_id, Settlement.trip_id == trip_id)
    )
    if settlement is None:
        raise SettlementNotFound
    return settlement


async def delete_settlement(db: AsyncSession, settlement: Settlement, user_id: UUID) -> None:
    """Take back a repayment, restoring the balances to what they were.

    Only its sender may: the row is that person's claim to have paid, and the
    same rule that stops anyone marking someone else's debt as settled has to
    stop them unmarking it. Unlike expenses, which anyone can tidy, this is a
    statement about one member's own money.
    """
    if settlement.from_user_id != user_id:
        raise NotTheSender
    await db.delete(settlement)
    await db.commit()


async def list_settlements(db: AsyncSession, trip_id: UUID) -> list[Settlement]:
    result = await db.execute(
        select(Settlement)
        .where(Settlement.trip_id == trip_id)
        .order_by(Settlement.settled_at.desc())
    )
    return list(result.scalars().all())


async def balance_for(db: AsyncSession, trip_id: UUID, user_id: UUID) -> int:
    """One member's net position: positive means owed, negative means owing.

    Derived from the same report the app reads, so "settled" can never mean one
    thing to the membership rules and another on screen.
    """
    report = await get_balance_report(db, trip_id)
    for entry in report["balances"]:
        if entry["user_id"] == user_id:
            return entry["balance_cents"]
    return 0


async def get_balance_report(db: AsyncSession, trip_id: UUID) -> dict:
    """Recomputed from raw rows on every call.

    Cheap at trip scale, and it makes stale balances structurally impossible:
    editing or deleting an expense needs no cache invalidation anywhere.
    """
    expenses = await list_expenses(db, trip_id)
    settlements = await list_settlements(db, trip_id)

    expense_input = [(e.paid_by, {s.user_id: s.share_cents for s in e.shares}) for e in expenses]
    settlement_input = [(s.from_user_id, s.to_user_id, s.amount_cents) for s in settlements]

    balances = compute_balances(expense_input, settlement_input)

    # Members with no activity still belong in the report, showing zero.
    for member_id in await _member_ids(db, trip_id):
        balances.setdefault(member_id, 0)

    return {
        "balances": [
            {"user_id": uid, "balance_cents": cents}
            for uid, cents in sorted(balances.items(), key=lambda pair: (-pair[1], pair[0].bytes))
        ],
        "suggested_transfers": [
            {
                "from_user_id": t.from_user_id,
                "to_user_id": t.to_user_id,
                "amount_cents": t.amount_cents,
            }
            for t in simplify_debts(balances)
        ],
        "total_spent_cents": sum(e.amount_cents for e in expenses),
    }
