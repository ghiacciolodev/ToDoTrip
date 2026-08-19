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

from app.config import get_settings

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


def client_address(request: Request) -> str:
    """Who to count this request against.

    The peer address, unless the deployment has named a header it trusts.

    Both halves matter. Trusting a forwarded header by default would let anyone
    send one and get a fresh allowance per request, which is worse than no limit
    because it looks like a limit. Ignoring it behind a proxy is the opposite
    failure and the one that bites in production: every request then arrives
    from the proxy's own address, so all users share a single bucket and ten
    people signing in exhaust everybody's allowance.

    Where the header holds a list — X-Forwarded-For is `client, proxy1, proxy2`
    — the **last** entry is used. That is the one appended by the nearest proxy,
    the only party in the chain we have decided to trust; everything to its left
    was supplied by whoever called it and can be invented.
    """
    header = get_settings().trusted_proxy_header
    if header:
        forwarded = request.headers.get(header)
        if forwarded:
            return forwarded.rsplit(",", 1)[-1].strip()
    return request.client.host if request.client else "unknown"


def build_limiter(*, limit: int, window_seconds: float, scope: str) -> RateLimiter:
    """A limiter registered for test resets. Callers supply their own key."""
    limiter = RateLimiter(limit=limit, window_seconds=window_seconds, scope=scope)
    _limiters.append(limiter)
    return limiter


def throttle(*, limit: int, window_seconds: float, scope: str):
    """Build a dependency that limits one endpoint by client address.

    The right key for the endpoints nobody has signed in to yet: there is no
    account to count against, so the address is all there is.
    """
    limiter = build_limiter(limit=limit, window_seconds=window_seconds, scope=scope)

    async def dependency(request: Request) -> None:
        limiter.check(f"{scope}:{client_address(request)}")

    return dependency
