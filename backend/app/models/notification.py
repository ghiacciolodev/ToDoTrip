"""What happened in a trip, kept for the people who were not looking."""

import enum
from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import DateTime, ForeignKey, Index, String, Uuid, func, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class NotificationKind(enum.StrEnum):
    """The short list of things worth interrupting somebody for.

    Kept deliberately short. Notifying every change turns a weekend away into a
    buzzing phone, and the first thing anybody does with a buzzing phone is
    switch the whole feature off — at which point the two notifications that
    actually mattered are lost with the rest.
    """

    EXPENSE_ADDED = "expense_added"
    EXPENSE_DELETED = "expense_deleted"
    SETTLEMENT_RECEIVED = "settlement_received"
    TASK_ASSIGNED = "task_assigned"
    EVENT_ADDED = "event_added"
    MEMBER_JOINED = "member_joined"


class Notification(Base):
    """One row per recipient, not one per event.

    Four people in a trip and one new expense makes three rows — one each for
    everybody but the person who added it. The alternative, one shared row plus
    a `notification_reads` table beside it, buys nothing at this scale and costs
    a join on the most frequent query in the app.

    A websocket event and a notification look alike and are not. Missing an
    event is harmless: the next fetch shows the current data anyway. Missing a
    notification means it never happened, so this has to survive being offline,
    and that means a table.
    """

    __tablename__ = "notifications"

    __table_args__ = (
        # The feed: one person's rows, newest first. The id is in the index
        # because it is also in the cursor — rows written by the same event
        # share a created_at to the microsecond, so the timestamp alone cannot
        # tell them apart and a page boundary landing inside one of those groups
        # would drop or repeat rows.
        Index(
            "ix_notifications_feed",
            "user_id",
            text("created_at DESC"),
            text("id DESC"),
        ),
        # The badge, which runs on every cold start and every return to the
        # foreground. Partial, so it indexes the handful of rows that are still
        # unread rather than the whole history.
        Index(
            "ix_notifications_unread",
            "user_id",
            postgresql_where=text("read_at IS NULL"),
        ),
    )

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)

    # Who is being told. The row belongs to them: read_at is their state, and
    # nobody else's.
    user_id: Mapped[UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    # Where it happened. Cascades, so deleting a trip takes its notifications
    # with it rather than leaving rows that lead nowhere.
    trip_id: Mapped[UUID] = mapped_column(
        ForeignKey("trips.id", ondelete="CASCADE"), index=True, nullable=False
    )

    kind: Mapped[NotificationKind] = mapped_column(String(40), nullable=False)

    # Who caused it. SET NULL rather than CASCADE: an account closing must not
    # delete the notifications it produced for other people.
    actor_id: Mapped[UUID | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"))

    # The expense, item or member this is about. Not a foreign key: the thing is
    # allowed to be deleted, and the notification is still true.
    entity_id: Mapped[UUID | None] = mapped_column(Uuid)

    # The facts, frozen at the moment it happened.
    #
    # Storing only an expense id and resolving it on read would turn every
    # notification about a deleted expense into "somebody did something". The
    # amount, the description and the names are copied in and never looked up
    # again: a notification is a record of a moment, not a view onto live data.
    #
    # Raw values, never a rendered sentence: the client builds the wording from
    # its own translations, so switching language does not leave a history
    # written in the previous one.
    payload: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)

    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
