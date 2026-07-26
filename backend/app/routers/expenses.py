"""HTTP layer for expenses, balances and settlements."""

from uuid import UUID

from fastapi import APIRouter, HTTPException, status

from app.core.events import emit
from app.dependencies import CurrentUser, DbSession, Membership
from app.schemas.expense import (
    BalanceReport,
    ExpenseCreate,
    ExpensePublic,
    SettlementCreate,
    SettlementPublic,
)
from app.services import expense_service
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


@router.post("/expenses", response_model=ExpensePublic, status_code=status.HTTP_201_CREATED)
async def create_expense(
    trip_id: UUID, payload: ExpenseCreate, db: DbSession, user: CurrentUser, _: Membership
):
    try:
        expense = await expense_service.create_expense(db, trip_id, user.id, payload.model_dump())
    except NotAllMembers:
        raise _NOT_MEMBERS from None
    await emit(trip_id, "expenses.changed", actor_id=user.id)
    return expense


@router.get("/expenses", response_model=list[ExpensePublic])
async def list_expenses(trip_id: UUID, db: DbSession, _: Membership):
    return await expense_service.list_expenses(db, trip_id)


@router.get("/expenses/{expense_id}", response_model=ExpensePublic)
async def get_expense(trip_id: UUID, expense_id: UUID, db: DbSession, _: Membership):
    try:
        return await expense_service.get_expense(db, trip_id, expense_id)
    except ExpenseNotFound:
        raise _NOT_FOUND from None


@router.delete("/expenses/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_expense(trip_id: UUID, expense_id: UUID, db: DbSession, membership: Membership):
    try:
        expense = await expense_service.get_expense(db, trip_id, expense_id)
        await expense_service.delete_expense(db, expense)
    except ExpenseNotFound:
        raise _NOT_FOUND from None
    await emit(trip_id, "expenses.changed", actor_id=membership.user_id)


@router.get("/balance", response_model=BalanceReport)
async def get_balance(trip_id: UUID, db: DbSession, _: Membership):
    """Who owes what, plus the shortest way to settle up."""
    return await expense_service.get_balance_report(db, trip_id)


@router.post("/settlements", response_model=SettlementPublic, status_code=status.HTTP_201_CREATED)
async def create_settlement(
    trip_id: UUID, payload: SettlementCreate, db: DbSession, user: CurrentUser, _: Membership
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
    await emit(trip_id, "expenses.changed", actor_id=user.id)
    return settlement


@router.get("/settlements", response_model=list[SettlementPublic])
async def list_settlements(trip_id: UUID, db: DbSession, _: Membership):
    return await expense_service.list_settlements(db, trip_id)


@router.delete("/settlements/{settlement_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_settlement(
    trip_id: UUID, settlement_id: UUID, db: DbSession, user: CurrentUser, _: Membership
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
