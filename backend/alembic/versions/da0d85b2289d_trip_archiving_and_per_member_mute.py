"""trip archiving and per-member mute

Revision ID: da0d85b2289d
Revises: 04834a6da96f
Create Date: 2026-07-27 10:16:21.639657

"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "da0d85b2289d"
down_revision: str | Sequence[str] | None = "04834a6da96f"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema."""
    # server_default is required, not cosmetic: the column is NOT NULL and the
    # table already has rows, so without it the ALTER fails on any database
    # that is not empty. Nobody has muted anything yet, so false is the truth.
    op.add_column(
        "trip_members",
        sa.Column("muted", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.add_column("trips", sa.Column("archived_at", sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column("trips", "archived_at")
    op.drop_column("trip_members", "muted")
