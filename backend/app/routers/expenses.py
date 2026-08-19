"""HTTP layer for expenses, balances and settlements."""

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, HTTPException, Query, status

from app.core import pagination
from app.core.events import Notify, emit
from app.dependencies import CurrentUser, DbSession, Membership, Writable
from app.models import Expense, NotificationKind, User
from app.schemas.expense import (
    BalanceReport,
    ExpenseCreate,
    ExpensePage,
    ExpensePublic,
    SettlementCreate,
    SettlementPublic,
)
from app.services import expense_service, trip_service
from app.services.expense_service import (
    ExpenseNotFound,
    NotAllMembers,
    NotTheSender,
    SelfSettlement,
    SettlementNotFound,
)

router = APIRouter(prefix="/trips/{trip_id}", tags=["expenses"])

_NOT_FOUND = HTTPException(status.HTTP_404_NOT_FOUND, "Expense not found")
_NOT_MEMBERS = HTTPException(
    status.HTTP_422_UNPROCESSABLE_CONTENT, "Everyone involved must be a member of this trip"
)

# Below this, a deleted expense is not worth telling four people about. A round
# figure rather than a share of the total: the point is "somebody would notice
# this was gone", and that is about the amount, not the proportion.
_DELETION_WORTH_TELLING_CENTS = 2000


async def _trip_name(db: DbSession, trip_id: UUID) -> str:
    trip = await trip_service.get_trip(db, trip_id)
    return trip.name


async def _money_payload(
    db: DbSession, trip_id: UUID, actor: User | UUID, expense: Expense
) -> dict:
    """The facts a money notification needs, copied rather than referenced.

    The expense may be deleted five minutes from now; the notification about it
    still has to read as a sentence.
    """
    name = actor.display_name if isinstance(actor, User) else None
    if name is None:
        member = await db.get(User, actor)
        name = member.display_name if member else ""
    return {
        "actor_name": name,
        "trip_name": await _trip_name(db, trip_id),
        "description": expense.description,
        "amount_cents": expense.amount_cents,
    }


@router.post("/expenses", response_model=ExpensePublic, status_code=status.HTTP_201_CREATED)
async def create_expense(
    trip_id: UUID, payload: ExpenseCreate, db: DbSession, user: CurrentUser, _: Writable
):
    try:
        expense = await expense_service.create_expense(db, trip_id, user.id, payload.model_dump())
    except NotAllMembers:
        raise _NOT_MEMBERS from None
    await emit(
        trip_id,
        "expenses.changed",
        actor_id=user.id,
        db=db,
        # Everyone, not just the people in the split: an expense moves the
        # trip's total, and the group's money is the group's business.
        notify=Notify(
            kind=NotificationKind.EXPENSE_ADDED,
            entity_id=expense.id,
            payload=await _money_payload(db, trip_id, user, expense),
        ),
    )
    return expense


@router.get("/expenses", response_model=ExpensePage)
async def list_expenses(
    trip_id: UUID,
    db: DbSession,
    _: Membership,
    limit: Annotated[int, Query(ge=1, le=pagination.MAX_PAGE)] = pagination.DEFAULT_PAGE,
    before: str | None = None,
):
    """One page of the trip's expenses, most recent first."""
    page = await expense_service.list_expenses(db, trip_id, limit=limit, before=before)
    return ExpensePage(
        items=[ExpensePublic.model_validate(row) for row in page.items],
        next_cursor=page.next_cursor,
        total=page.total,
    )


@router.get("/expenses/{expense_id}", response_model=ExpensePublic)
async def get_expense(trip_id: UUID, expense_id: UUID, db: DbSession, _: Membership):
    try:
        return await expense_service.get_expense(db, trip_id, expense_id)
    except ExpenseNotFound:
        raise _NOT_FOUND from None


@router.delete("/expenses/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_expense(trip_id: UUID, expense_id: UUID, db: DbSession, membership: Writable):
    try:
        expense = await expense_service.get_expense(db, trip_id, expense_id)
        removed = await _money_payload(db, trip_id, membership.user_id, expense)
        await expense_service.delete_expense(db, expense)
    except ExpenseNotFound:
        raise _NOT_FOUND from None
    await emit(
        trip_id,
        "expenses.changed",
        actor_id=membership.user_id,
        db=db,
        # A deletion moves everybody's balance, so it counts — but announcing
        # every cancelled coffee doubles the noise of the whole feature. Only
        # amounts big enough that somebody would notice them missing.
        notify=Notify(
            kind=NotificationKind.EXPENSE_DELETED,
            entity_id=expense_id,
            payload=removed,
        )
        if expense.amount_cents >= _DELETION_WORTH_TELLING_CENTS
        else None,
    )


@router.get("/balance", response_model=BalanceReport)
async def get_balance(trip_id: UUID, db: DbSession, _: Membership):
    """Who owes what, plus the shortest way to settle up."""
    return await expense_service.get_balance_report(db, trip_id)


@router.post("/settlements", response_model=SettlementPublic, status_code=status.HTTP_201_CREATED)
async def create_settlement(
    trip_id: UUID, payload: SettlementCreate, db: DbSession, user: CurrentUser, _: Writable
):
    """Records a repayment made outside the app. The sender is always the caller,
    so nobody can mark someone else's debt as paid."""
    try:
        settlement = await expense_service.create_settlement(
            db, trip_id, user.id, payload.model_dump()
        )
    except SelfSettlement:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_CONTENT, "Cannot settle with yourself"
        ) from None
    except NotAllMembers:
        raise _NOT_MEMBERS from None
    await emit(
        trip_id,
        "expenses.changed",
        actor_id=user.id,
        db=db,
        # Only the person who was paid. To everybody else this is bookkeeping
        # between two other people.
        notify=Notify(
            kind=NotificationKind.SETTLEMENT_RECEIVED,
            entity_id=settlement.id,
            only=[settlement.to_user_id],
            payload={
                "actor_name": user.display_name,
                "trip_name": await _trip_name(db, trip_id),
                "amount_cents": settlement.amount_cents,
            },
        ),
    )
    return settlement


@router.get("/settlements", response_model=list[SettlementPublic])
async def list_settlements(trip_id: UUID, db: DbSession, _: Membership):
    return await expense_service.list_settlements(db, trip_id)


@router.delete("/settlements/{settlement_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_settlement(
    trip_id: UUID, settlement_id: UUID, db: DbSession, user: CurrentUser, _: Writable
):
    """Undo a repayment. Only the member who recorded it can, since it is their
    own claim to have paid."""
    try:
        settlement = await expense_service.get_settlement(db, trip_id, settlement_id)
        await expense_service.delete_settlement(db, settlement, user.id)
    except SettlementNotFound:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Settlement not found") from None
    except NotTheSender:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, "Only the sender can undo this repayment"
        ) from None
    await emit(trip_id, "expenses.changed", actor_id=user.id)
