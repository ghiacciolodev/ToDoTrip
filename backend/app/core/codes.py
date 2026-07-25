"""Human-friendly random codes for invites."""

import secrets

# 0/O and 1/I are excluded: these codes get dictated out loud and typed by hand.
_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
_LENGTH = 8


def generate_invite_code() -> str:
    """~32^8 = 10^12 combinations, drawn from a CSPRNG so codes are unguessable."""
    return "".join(secrets.choice(_ALPHABET) for _ in range(_LENGTH))
