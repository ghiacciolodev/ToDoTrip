"""The notification feed.

Two things carry the weight here. Who gets a row — being told about your own
action, or about a repayment between two other people, is how a bell learns to
mean nothing — and that a notification survives the thing it is about, because a
record of a moment that turns into "somebody did something" once the expense is
deleted was not worth writing down.
"""

import asyncio
from contextlib import suppress
from datetime import UTC, datetime, timedelta
from unittest.mock import patch

from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import housekeeping
from app.database import SessionLocal
from app.models import Notification
from app.services import notification_service

AUTH = "/api/v1/auth"
TRIPS = "/api/v1/trips"
NOTIFS = "/api/v1/notifications"


async def _id(client: AsyncClient, headers: dict) -> str:
    return (await client.get(f"{AUTH}/me", headers=headers)).json()["id"]


async def _feed(client: AsyncClient, headers: dict, **params) -> dict:
    return (await client.get(NOTIFS, headers=headers, params=params)).json()


async def _unread(client: AsyncClient, headers: dict) -> int:
    return (await client.get(f"{NOTIFS}/unread-count", headers=headers)).json()["count"]


async def _join(client: AsyncClient, code: str, headers: dict) -> None:
    await client.post(f"{TRIPS}/join", json={"code": code}, headers=headers)


async def _expense(
    client: AsyncClient,
    trip_id: str,
    headers: dict,
    *,
    paid_by: str,
    participants: list[str],
    amount_cents: int = 6000,
    description: str = "Cena",
) -> dict:
    response = await client.post(
        f"{TRIPS}/{trip_id}/expenses",
        json={
            "description": description,
            "amount_cents": amount_cents,
            "paid_by": paid_by,
            "participants": participants,
        },
        headers=headers,
    )
    return response.json()


class TestWhoGetsTold:
    async def test_an_expense_reaches_the_others(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        mine = await _id(client, auth_headers)
        await _expense(client, trip["id"], auth_headers, paid_by=mine, participants=[mine])

        feed = await _feed(client, other_headers)
        # Just the expense: they are the actor of their own arrival, so the
        # member_joined row went to the people already in the trip.
        assert [row["kind"] for row in feed["items"]] == ["expense_added"]

    async def test_never_the_person_who_did_it(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """Being notified of your own action is the fastest way to teach
        somebody that the bell means nothing."""
        await _join(client, invite_code, other_headers)
        mine = await _id(client, auth_headers)
        await _expense(client, trip["id"], auth_headers, paid_by=mine, participants=[mine])

        kinds = [row["kind"] for row in (await _feed(client, auth_headers))["items"]]
        assert "expense_added" not in kinds

    async def test_a_repayment_reaches_only_the_person_paid(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """To everybody else it is bookkeeping between two other people."""
        await _join(client, invite_code, other_headers)
        third = {
            "email": "gio@test.it",
            "password": "password123",
            "display_name": "Gio",
            "accepted_privacy": True,
        }
        await client.post(f"{AUTH}/register", json=third)
        login = await client.post(
            f"{AUTH}/login", json={"email": third["email"], "password": third["password"]}
        )
        third_headers = {"Authorization": f"Bearer {login.json()['access_token']}"}
        await _join(client, invite_code, third_headers)

        mine = await _id(client, auth_headers)
        await client.post(
            f"{TRIPS}/{trip['id']}/settlements",
            json={"to_user_id": mine, "amount_cents": 3000},
            headers=other_headers,
        )

        mine_kinds = [row["kind"] for row in (await _feed(client, auth_headers))["items"]]
        assert mine_kinds.count("settlement_received") == 1
        # The third member hears nothing about it.
        third_feed = await _feed(client, third_headers)
        assert "settlement_received" not in [row["kind"] for row in third_feed["items"]]

    async def test_a_task_reaches_only_its_assignees(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        theirs = await _id(client, other_headers)
        await client.post(
            f"{TRIPS}/{trip['id']}/items",
            json={"type": "task", "title": "Prenotare", "assigned_to": [theirs]},
            headers=auth_headers,
        )

        feed = await _feed(client, other_headers)
        assert feed["items"][0]["kind"] == "task_assigned"
        assert feed["items"][0]["payload"]["title"] == "Prenotare"

    async def test_an_unassigned_task_tells_nobody(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """A to-do nobody was given is a note to the group, not news."""
        await _join(client, invite_code, other_headers)
        before = await _unread(client, other_headers)
        await client.post(
            f"{TRIPS}/{trip['id']}/items",
            json={"type": "task", "title": "Prenotare"},
            headers=auth_headers,
        )
        assert await _unread(client, other_headers) == before

    async def test_a_calendar_event_reaches_the_whole_trip(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        await client.post(
            f"{TRIPS}/{trip['id']}/items",
            json={"type": "event", "title": "Volo", "starts_at": "2026-08-12T14:30:00Z"},
            headers=auth_headers,
        )

        feed = await _feed(client, other_headers)
        assert feed["items"][0]["kind"] == "event_added"

    async def test_joining_tells_the_people_already_there(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)

        feed = await _feed(client, auth_headers)
        assert feed["items"][0]["kind"] == "member_joined"
        assert feed["items"][0]["payload"]["actor_name"] == "Luca"

    async def test_ticking_a_task_off_tells_nobody(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """The list of what deserves a notification is short on purpose."""
        await _join(client, invite_code, other_headers)
        item = await client.post(
            f"{TRIPS}/{trip['id']}/items",
            json={"type": "task", "title": "Prenotare"},
            headers=auth_headers,
        )
        before = await _unread(client, other_headers)

        await client.post(
            f"{TRIPS}/{trip['id']}/items/{item.json()['id']}/complete", headers=auth_headers
        )
        assert await _unread(client, other_headers) == before

    async def test_a_muted_trip_stays_quiet(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """What the switch in trip settings is for."""
        await _join(client, invite_code, other_headers)
        await client.patch(
            f"{TRIPS}/{trip['id']}/members/me/settings",
            json={"muted": True},
            headers=other_headers,
        )
        before = await _unread(client, other_headers)

        mine = await _id(client, auth_headers)
        await _expense(client, trip["id"], auth_headers, paid_by=mine, participants=[mine])
        assert await _unread(client, other_headers) == before


class TestDeletedExpenses:
    async def test_a_large_one_is_announced(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        mine = await _id(client, auth_headers)
        expense = await _expense(
            client, trip["id"], auth_headers, paid_by=mine, participants=[mine]
        )
        await client.delete(f"{TRIPS}/{trip['id']}/expenses/{expense['id']}", headers=auth_headers)

        kinds = [row["kind"] for row in (await _feed(client, other_headers))["items"]]
        assert "expense_deleted" in kinds

    async def test_a_small_one_is_not(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """A deletion moves balances, so it counts — but announcing every
        cancelled coffee doubles the noise of the whole feature."""
        await _join(client, invite_code, other_headers)
        mine = await _id(client, auth_headers)
        expense = await _expense(
            client,
            trip["id"],
            auth_headers,
            paid_by=mine,
            participants=[mine],
            amount_cents=300,
        )
        await client.delete(f"{TRIPS}/{trip['id']}/expenses/{expense['id']}", headers=auth_headers)

        kinds = [row["kind"] for row in (await _feed(client, other_headers))["items"]]
        assert "expense_deleted" not in kinds


class TestFrozenPayload:
    async def test_it_outlives_what_it_is_about(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """The reason the payload is copied rather than referenced: resolving an
        expense id at read time turns this into "somebody did something"."""
        await _join(client, invite_code, other_headers)
        mine = await _id(client, auth_headers)
        expense = await _expense(
            client,
            trip["id"],
            auth_headers,
            paid_by=mine,
            participants=[mine],
            description="Cena al Time Out",
        )
        await client.delete(f"{TRIPS}/{trip['id']}/expenses/{expense['id']}", headers=auth_headers)

        added = next(
            row
            for row in (await _feed(client, other_headers))["items"]
            if row["kind"] == "expense_added"
        )
        assert added["payload"]["description"] == "Cena al Time Out"
        assert added["payload"]["amount_cents"] == 6000
        assert added["payload"]["actor_name"] == "Mario"
        assert added["payload"]["trip_name"] == "Lisbona 2026"

    async def test_it_holds_no_rendered_sentence(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """English stored in the database would leave anyone who switches
        language reading their history in the old one."""
        await _join(client, invite_code, other_headers)

        # The owner's row about the arrival: two names, no sentence.
        payload = (await _feed(client, auth_headers))["items"][0]["payload"]
        assert set(payload) == {"actor_name", "trip_name"}


class TestReadState:
    async def test_it_starts_unread_and_can_be_marked(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        assert await _unread(client, auth_headers) == 1

        row = (await _feed(client, auth_headers))["items"][0]
        await client.post(f"{NOTIFS}/read", json={"ids": [row["id"]]}, headers=auth_headers)

        assert await _unread(client, auth_headers) == 0
        assert (await _feed(client, auth_headers))["items"][0]["read_at"] is not None

    async def test_read_all_clears_the_badge(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        mine = await _id(client, auth_headers)
        await _expense(client, trip["id"], other_headers, paid_by=mine, participants=[mine])
        assert await _unread(client, auth_headers) == 2

        await client.post(f"{NOTIFS}/read-all", headers=auth_headers)
        assert await _unread(client, auth_headers) == 0

    async def test_read_state_is_personal(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """The reason there is a row per recipient rather than one shared one."""
        await _join(client, invite_code, other_headers)
        mine = await _id(client, auth_headers)
        await _expense(client, trip["id"], auth_headers, paid_by=mine, participants=[mine])

        await client.post(f"{NOTIFS}/read-all", headers=auth_headers)
        assert await _unread(client, other_headers) == 1

    async def test_marking_somebody_elses_id_does_nothing(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """No way to read, or to probe for, another person's feed one id at a
        time."""
        await _join(client, invite_code, other_headers)
        mine = await _id(client, auth_headers)
        await _expense(client, trip["id"], auth_headers, paid_by=mine, participants=[mine])
        theirs = (await _feed(client, other_headers))["items"][0]["id"]

        response = await client.post(f"{NOTIFS}/read", json={"ids": [theirs]}, headers=auth_headers)
        assert response.status_code == 204
        assert await _unread(client, other_headers) == 1


class TestFeed:
    async def test_it_only_ever_shows_your_own(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        mine = await _id(client, auth_headers)
        await _expense(client, trip["id"], auth_headers, paid_by=mine, participants=[mine])

        # One about the join, and nothing about the expense they added
        # themselves.
        assert len((await _feed(client, auth_headers))["items"]) == 1

    async def test_newest_first(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        mine = await _id(client, auth_headers)
        # Added by the other member, so this one lands on the owner, who also
        # holds the older row about that member arriving.
        await _expense(client, trip["id"], other_headers, paid_by=mine, participants=[mine])

        kinds = [row["kind"] for row in (await _feed(client, auth_headers))["items"]]
        assert kinds == ["expense_added", "member_joined"]

    async def test_the_cursor_walks_the_whole_feed_without_repeating(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """Rows written by one event share a created_at to the microsecond, so
        a cursor on the timestamp alone would drop or repeat some of them."""
        await _join(client, invite_code, other_headers)
        mine = await _id(client, auth_headers)
        for index in range(5):
            await _expense(
                client,
                trip["id"],
                auth_headers,
                paid_by=mine,
                participants=[mine],
                description=f"Spesa {index}",
            )

        seen: list[str] = []
        cursor = None
        for _ in range(10):
            page = await _feed(
                client, other_headers, limit=2, **({"before": cursor} if cursor else {})
            )
            seen.extend(row["id"] for row in page["items"])
            cursor = page["next_cursor"]
            if cursor is None:
                break

        assert len(seen) == 5
        assert len(set(seen)) == 5

    async def test_a_nonsense_cursor_gives_the_first_page(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        page = await _feed(client, auth_headers, before="not-a-cursor")
        assert len(page["items"]) == 1

    async def test_a_stranger_gets_nothing(self, client: AsyncClient, other_headers: dict):
        assert (await _feed(client, other_headers))["items"] == []

    async def test_it_needs_a_token(self, client: AsyncClient):
        assert (await client.get(NOTIFS)).status_code == 401


class TestDeleting:
    async def test_one_can_be_removed(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        row = (await _feed(client, auth_headers))["items"][0]

        response = await client.delete(f"{NOTIFS}/{row['id']}", headers=auth_headers)
        assert response.status_code == 204
        assert (await _feed(client, auth_headers))["items"] == []

    async def test_removing_an_unread_one_drops_the_count(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        assert await _unread(client, auth_headers) == 1

        row = (await _feed(client, auth_headers))["items"][0]
        await client.delete(f"{NOTIFS}/{row['id']}", headers=auth_headers)
        assert await _unread(client, auth_headers) == 0

    async def test_somebody_elses_id_deletes_nothing(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        """Answering 404 for another person's id would confirm it exists."""
        await _join(client, invite_code, other_headers)
        mine = await _id(client, auth_headers)
        await _expense(client, trip["id"], auth_headers, paid_by=mine, participants=[mine])
        theirs = (await _feed(client, other_headers))["items"][0]["id"]

        response = await client.delete(f"{NOTIFS}/{theirs}", headers=auth_headers)
        assert response.status_code == 204
        assert len((await _feed(client, other_headers))["items"]) == 1

    async def test_clearing_empties_only_your_own_feed(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
    ):
        await _join(client, invite_code, other_headers)
        mine = await _id(client, auth_headers)
        await _expense(client, trip["id"], auth_headers, paid_by=mine, participants=[mine])

        assert (await client.delete(NOTIFS, headers=auth_headers)).status_code == 204
        assert (await _feed(client, auth_headers))["items"] == []
        assert await _unread(client, auth_headers) == 0
        # The other member's feed is untouched.
        assert len((await _feed(client, other_headers))["items"]) == 1


class TestLifecycle:
    async def test_deleting_a_trip_takes_its_notifications(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        auth_headers: dict,
        other_headers: dict,
        db: AsyncSession,
    ):
        """Otherwise the feed fills with rows that lead nowhere."""
        await _join(client, invite_code, other_headers)
        await client.delete(f"{TRIPS}/{trip['id']}", headers=auth_headers)

        assert (await db.execute(select(Notification))).scalars().all() == []

    async def test_purge_drops_the_old_and_keeps_the_recent(
        self,
        client: AsyncClient,
        trip: dict,
        invite_code: str,
        other_headers: dict,
        db: AsyncSession,
    ):
        await _join(client, invite_code, other_headers)
        row = (await db.execute(select(Notification))).scalars().one()

        # Old but unread: still inside the ninety days it is kept for.
        row.created_at = datetime.now(UTC) - timedelta(days=45)
        await db.commit()
        assert await notification_service.purge(db) == 0

        row.created_at = datetime.now(UTC) - timedelta(days=120)
        await db.commit()
        assert await notification_service.purge(db) == 1


class TestPurgeLoop:
    """The sweep has to keep happening, not happen once.

    The bug this covers: purging only at startup meant a server that stayed up
    for a month never cleaned anything.
    """

    async def test_it_purges_more_than_once(self, db: AsyncSession):
        calls = 0

        async def counting_purge(session):
            nonlocal calls
            calls += 1
            return 0

        with patch.object(notification_service, "purge", counting_purge):
            task = asyncio.create_task(
                housekeeping.purge_notifications_forever(0.01, session_factory=SessionLocal)
            )
            await asyncio.sleep(0.08)
            task.cancel()
            with suppress(asyncio.CancelledError):
                await task

        assert calls > 1

    async def test_a_failure_does_not_stop_the_loop(self, db: AsyncSession):
        """A database hiccup must not silently end the sweep for the lifetime of
        the process."""
        calls = 0

        async def failing_once(session):
            nonlocal calls
            calls += 1
            if calls == 1:
                raise RuntimeError("database went away")
            return 0

        with patch.object(notification_service, "purge", failing_once):
            task = asyncio.create_task(
                housekeeping.purge_notifications_forever(0.01, session_factory=SessionLocal)
            )
            await asyncio.sleep(0.08)
            task.cancel()
            with suppress(asyncio.CancelledError):
                await task

        assert calls > 1

    async def test_cancelling_stops_it(self, db: AsyncSession):
        """Otherwise a reload leaves a second loop running against the same
        database."""
        task = asyncio.create_task(housekeeping.purge_notifications_forever(0.01))
        await asyncio.sleep(0.02)
        task.cancel()
        with suppress(asyncio.CancelledError):
            await task

        assert task.cancelled()
