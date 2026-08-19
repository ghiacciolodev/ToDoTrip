"""What can go wrong around a trip, in one place.

Their own module because all three trip services raise them and every router
catches them. Leaving them inside one of the services would make the other two
import it for its exceptions alone.
"""

from uuid import UUID


class TripNotFound(Exception):
    """The trip does not exist, or the caller is not allowed to know it does."""


class NotAMember(Exception):
    """Caller has no membership row for this trip."""


class OwnerMustTransfer(Exception):
    """An owner cannot step out while other members remain.

    A trip always has exactly one owner: leaving without handing it over would
    leave a group nobody can invite to, rename or delete.
    """


class OutstandingBalance(Exception):
    """This member still owes money, or is still owed some.

    Departure is blocked rather than resolved afterwards. Their expenses cannot
    be deleted — that would silently change what everyone else owes — and a
    former member has no name in the app and no way to be paid back, so the
    balance would sit there unresolvable. Settling first is one rule that
    removes the whole problem.
    """

    def __init__(self, user_id: UUID, balance_cents: int) -> None:
        self.user_id = user_id
        self.balance_cents = balance_cents
        super().__init__(f"{user_id} has a balance of {balance_cents} cents")


class NoLongerOwner(Exception):
    """Somebody else handed the trip on first.

    Raised when a transfer finds the caller is no longer the owner — which only
    happens if two transfers were in flight at once.
    """


class InvalidInvite(Exception):
    """Code is unknown, revoked, expired or exhausted."""
