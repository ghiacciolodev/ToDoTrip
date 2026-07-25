"""Shared expenses, their per-member split, and recorded repayments.

Design rule: the database stores only raw facts (who paid, who owes a share,
who reimbursed whom). Balances and "who owes what to whom" are never persisted,
they are computed from these rows. Storing them would create a second source of
truth that eventually drifts from the first.
"""

from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    DateTime,
    ForeignKey,
    String,
    UniqueConstraint,
    Uuid,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin


class Expense(Base, TimestampMixin):
    """A single payment made by one member on behalf of some or all of the group."""

    __tablename__ = "expenses"
    __table_args__ = (CheckConstraint("amount_cents > 0", name="ck_expense_amount_positive"),)

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    trip_id: Mapped[UUID] = mapped_column(
        ForeignKey("trips.id", ondelete="CASCADE"), index=True, nullable=False
    )
    paid_by: Mapped[UUID] = mapped_column(ForeignKey("users.id"), index=True, nullable=False)

    # Integer cents, never a float: binary floating point cannot represent 0.01
    # exactly, and the rounding error is visible after a handful of splits.
    amount_cents: Mapped[int] = mapped_column(BigInteger, nullable=False)

    currency: Mapped[str] = mapped_column(String(3), default="EUR", nullable=False)
    description: Mapped[str] = mapped_column(String(200), nullable=False)

    # When the money was spent, which is not necessarily when the row was created.
    spent_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    created_by: Mapped[UUID] = mapped_column(ForeignKey("users.id"), nullable=False)

    # selectin loading fetches all shares in one extra query instead of one per
    # expense (the classic N+1 when listing a trip's expenses).
    shares: Mapped[list["ExpenseShare"]] = relationship(
        back_populates="expense", cascade="all, delete-orphan", lazy="selectin"
    )


class ExpenseShare(Base):
    """How much of one expense a given member is responsible for.

    The sum of shares must equal the parent expense amount; that invariant is
    enforced in the service layer, since SQL cannot express it as a constraint.
    Uneven splits are supported from day one, so percentages and custom amounts
    do not require a schema change later.
    """

    __tablename__ = "expense_shares"
    __table_args__ = (UniqueConstraint("expense_id", "user_id", name="uq_expense_share"),)

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    expense_id: Mapped[UUID] = mapped_column(
        ForeignKey("expenses.id", ondelete="CASCADE"), index=True, nullable=False
    )
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    share_cents: Mapped[int] = mapped_column(BigInteger, nullable=False)

    expense: Mapped["Expense"] = relationship(back_populates="shares")


class Settlement(Base):
    """A reimbursement actually paid between two members, outside the app.

    Settlements offset computed balances; they are not expenses and must not
    appear in the trip's total cost.
    """

    __tablename__ = "settlements"
    __table_args__ = (
        CheckConstraint("amount_cents > 0", name="ck_settlement_amount_positive"),
        # Direction is expressed by from/to, never by the sign of the amount,
        # and nobody can settle a debt with themselves.
        CheckConstraint("from_user_id <> to_user_id", name="ck_settlement_distinct_users"),
    )

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    trip_id: Mapped[UUID] = mapped_column(
        ForeignKey("trips.id", ondelete="CASCADE"), index=True, nullable=False
    )
    from_user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    to_user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"), nullable=False)
    amount_cents: Mapped[int] = mapped_column(BigInteger, nullable=False)
    note: Mapped[str | None] = mapped_column(String(200))
    settled_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
