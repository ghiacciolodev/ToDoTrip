"""Request and response contracts for expenses, balances and settlements."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator


class ShareInput(BaseModel):
    user_id: UUID
    share_cents: int = Field(ge=0)


class ExpenseCreate(BaseModel):
    """Two ways to split, one field decides.

    Omitting `shares` splits evenly across `participants`; providing it allows
    any uneven split. Supporting both from day one avoids a schema change once
    someone inevitably wants to pay a bigger slice.
    """

    description: str = Field(min_length=1, max_length=200)
    amount_cents: int = Field(gt=0)
    paid_by: UUID
    spent_at: datetime | None = None
    participants: list[UUID] | None = None
    shares: list[ShareInput] | None = None

    @model_validator(mode="after")
    def check_split(self):
        if self.shares is None and not self.participants:
            raise ValueError("provide either participants or shares")
        if self.shares is not None:
            if sum(s.share_cents for s in self.shares) != self.amount_cents:
                raise ValueError("shares must sum to amount_cents")
            ids = [s.user_id for s in self.shares]
            if len(ids) != len(set(ids)):
                raise ValueError("duplicate user in shares")
        if self.participants is not None and len(self.participants) != len(set(self.participants)):
            raise ValueError("duplicate participant")
        return self


class SharePublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    user_id: UUID
    share_cents: int


class ExpensePublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    trip_id: UUID
    description: str
    amount_cents: int
    currency: str
    paid_by: UUID
    spent_at: datetime
    created_by: UUID
    created_at: datetime
    shares: list[SharePublic]


class BalanceEntry(BaseModel):
    user_id: UUID
    # Positive: the group owes them. Negative: they owe the group.
    balance_cents: int


class TransferSuggestion(BaseModel):
    from_user_id: UUID
    to_user_id: UUID
    amount_cents: int


class BalanceReport(BaseModel):
    balances: list[BalanceEntry]
    suggested_transfers: list[TransferSuggestion]
    total_spent_cents: int


class SettlementCreate(BaseModel):
    to_user_id: UUID
    amount_cents: int = Field(gt=0)
    note: str | None = Field(default=None, max_length=200)


class SettlementPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    trip_id: UUID
    from_user_id: UUID
    to_user_id: UUID
    amount_cents: int
    note: str | None
    settled_at: datetime
