"""Model package.

Every model must be imported here: Alembic's autogenerate only sees tables that
are registered on Base.metadata at import time, so a missing import silently
produces an incomplete migration.
"""

from app.models.auth import RefreshToken
from app.models.base import Base
from app.models.checklist import Checklist, ChecklistEntry
from app.models.expense import Expense, ExpenseShare, Settlement
from app.models.invite import Invite
from app.models.item import Item, ItemAssignee, ItemType
from app.models.trip import MemberRole, Trip, TripMember, TripPastMember
from app.models.user import User

__all__ = [
    "Base",
    "Checklist",
    "ChecklistEntry",
    "Expense",
    "ExpenseShare",
    "Invite",
    "Item",
    "ItemAssignee",
    "ItemType",
    "MemberRole",
    "RefreshToken",
    "Settlement",
    "Trip",
    "TripMember",
    "TripPastMember",
    "User",
]
