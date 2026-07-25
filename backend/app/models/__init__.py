"""Model package.

Every model must be imported here: Alembic's autogenerate only sees tables that
are registered on Base.metadata at import time, so a missing import silently
produces an incomplete migration.
"""

from app.models.base import Base
from app.models.user import User
from app.models.auth import RefreshToken
from app.models.trip import Trip, TripMember, MemberRole
from app.models.invite import Invite
from app.models.item import Item, ItemType
from app.models.expense import Expense, ExpenseShare, Settlement

__all__ = [
    "Base", "User", "RefreshToken", "Trip", "TripMember", "MemberRole",
    "Invite", "Item", "ItemType", "Expense", "ExpenseShare", "Settlement",
]