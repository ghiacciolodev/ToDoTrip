"""record privacy policy acceptance

Revision ID: a1c7e93b40f5
Revises: 4e89faa55a64
Create Date: 2026-08-19 22:40:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "a1c7e93b40f5"
down_revision: str | Sequence[str] | None = "4e89faa55a64"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Add the consent record.

    Nullable, and left null for accounts that already exist. Backfilling a
    timestamp for people who were never shown the box would turn a missing
    record into a false one, which is worse than the gap it hides.
    """
    op.add_column(
        "users",
        sa.Column("privacy_accepted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column("users", sa.Column("privacy_version", sa.String(length=20), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column("users", "privacy_version")
    op.drop_column("users", "privacy_accepted_at")
