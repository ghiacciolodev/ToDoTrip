"""Request throttling for the handful of endpoints worth attacking.

A sliding window held in memory, deliberately not a general-purpose solution:
it protects one process. Behind several workers or instances each has its own
counters, so the effective limit is the configured one multiplied by the number
of processes; a shared store (or a limit at the reverse proxy) is what a real
deployment needs. It is still worth having, because the alternative here is no
limit at all.
"""

from collections import deque
from time import monotonic

from fastapi import HTTPException, Request, status

# Bounds the memory a flood from many addresses can occupy. Beyond this the
# oldest idle keys are dropped, which at worst forgives an attacker their
# history — the alternative is unbounded growth, which is a denial of service in
# itself.
_MAX_KEYS = 4096


class RateLimiter:
    """Allows [limit] requests per key within [window_seconds]."""

    def __init__(self, *, limit: int, window_seconds: float, scope: str) -> None:
        self.limit = limit
        self.window_seconds = window_seconds
        self.scope = scope
        self._hits: dict[str, deque[float]] = {}

    def check(self, key: str) -> None:
        now = monotonic()
        hits = self._hits.setdefault(key, deque())

        # Drop the timestamps that have aged out of the window.
        cutoff = now - self.window_seconds
        while hits and hits[0] <= cutoff:
            hits.popleft()

        if len(hits) >= self.limit:
            retry_after = max(1, int(hits[0] + self.window_seconds - now))
            raise HTTPException(
                status.HTTP_429_TOO_MANY_REQUESTS,
                "Too many attempts. Try again later.",
                headers={"Retry-After": str(retry_after)},
            )

        hits.append(now)
        if len(self._hits) > _MAX_KEYS:
            self._prune(cutoff)

    def _prune(self, cutoff: float) -> None:
        for key in [k for k, hits in self._hits.items() if not hits or hits[-1] <= cutoff]:
            del self._hits[key]

    def reset(self) -> None:
        self._hits.clear()


# Registered so tests can start from a clean window: they all reach the API from
# the same client address and would otherwise throttle each other.
_limiters: list[RateLimiter] = []


def reset_all() -> None:
    for limiter in _limiters:
        limiter.reset()


def throttle(*, limit: int, window_seconds: float, scope: str):
    """Build a dependency that limits one endpoint by client address.

    Keyed on the peer address, which behind a proxy is the proxy itself: the
    forwarded headers are not trusted here because anyone can send them, so a
    deployment terminating TLS elsewhere must do its own limiting.
    """
    limiter = RateLimiter(limit=limit, window_seconds=window_seconds, scope=scope)
    _limiters.append(limiter)

    async def dependency(request: Request) -> None:
        client = request.client.host if request.client else "unknown"
        limiter.check(f"{scope}:{client}")

    return dependency
