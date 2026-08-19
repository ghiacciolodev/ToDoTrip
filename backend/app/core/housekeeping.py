"""Background maintenance that has to keep happening while the process runs.

Kept out of the request path: nobody's HTTP call should pay for a DELETE that
exists only to stop a table growing.
"""

import asyncio
import logging

from app.database import SessionLocal
from app.services import notification_service

_log = logging.getLogger(__name__)


async def purge_notifications_forever(interval_seconds: float, *, session_factory=SessionLocal):
    """Purge expired notifications now, then every `interval_seconds`.

    A loop rather than a cron container: this is one DELETE on an indexed
    column, and a scheduler to run it would be more moving parts than the
    problem deserves. Running it at startup alone was the bug — a server that
    stays up for a month never cleaned anything.

    Safe to run in several workers at once. The DELETE only removes rows that
    are already past their keep-until, so a second worker finds nothing rather
    than fighting the first.
    """
    while True:
        try:
            async with session_factory() as session:
                removed = await notification_service.purge(session)
            if removed:
                _log.info("purged %s expired notifications", removed)
        except asyncio.CancelledError:
            raise
        except Exception:  # noqa: BLE001
            # Never fatal. A failed purge leaves rows that will be tried again
            # on the next pass, and nobody is blocked by them in the meantime.
            _log.exception("notification purge failed")
        await asyncio.sleep(interval_seconds)
