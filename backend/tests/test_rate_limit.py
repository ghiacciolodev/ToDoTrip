"""Throttling of the endpoints worth brute-forcing."""

from httpx import AsyncClient

from app.core.rate_limit import RateLimiter

LOGIN = "/api/v1/auth/login"
REGISTER = "/api/v1/auth/register"
WRONG = {"email": "mario@test.it", "password": "wrong-password"}


class TestLogin:
    async def test_repeated_failures_are_blocked(self, client: AsyncClient, registered_user: dict):
        # The limit is 10 per window; the first ten are answered normally.
        for _ in range(10):
            assert (await client.post(LOGIN, json=WRONG)).status_code == 401

        blocked = await client.post(LOGIN, json=WRONG)
        assert blocked.status_code == 429
        # Tells the client when to come back instead of leaving it to guess.
        assert int(blocked.headers["Retry-After"]) > 0

    async def test_a_blocked_address_cannot_log_in_correctly_either(
        self, client: AsyncClient, registered_user: dict
    ):
        """Otherwise the limit would only slow down the attacker's misses."""
        for _ in range(10):
            await client.post(LOGIN, json=WRONG)

        response = await client.post(
            LOGIN,
            json={"email": registered_user["email"], "password": registered_user["password"]},
        )
        assert response.status_code == 429

    async def test_normal_use_is_untouched(self, client: AsyncClient, registered_user: dict):
        """Mistyping a password a few times must not lock anyone out."""
        for _ in range(3):
            assert (await client.post(LOGIN, json=WRONG)).status_code == 401

        response = await client.post(
            LOGIN,
            json={"email": registered_user["email"], "password": registered_user["password"]},
        )
        assert response.status_code == 200


class TestRegister:
    async def test_account_creation_is_capped(self, client: AsyncClient):
        for index in range(5):
            response = await client.post(
                REGISTER,
                json={
                    "email": f"user{index}@test.it",
                    "password": "password123",
                    "display_name": f"User {index}",
                },
            )
            assert response.status_code == 201

        blocked = await client.post(
            REGISTER,
            json={"email": "extra@test.it", "password": "password123", "display_name": "Extra"},
        )
        assert blocked.status_code == 429


class TestWindow:
    def test_hits_expire(self):
        """The window slides: an old attempt must not count forever."""
        limiter = RateLimiter(limit=1, window_seconds=60, scope="unit")
        limiter.check("k")

        # Backdate the recorded attempt instead of sleeping through the window.
        limiter._hits["k"][0] -= 61
        limiter.check("k")

    def test_keys_do_not_share_a_budget(self):
        limiter = RateLimiter(limit=1, window_seconds=60, scope="unit")
        limiter.check("a")
        limiter.check("b")


class TestBehindAProxy:
    """The bug that only exists in production.

    Locally every request really does come from a different peer address, so the
    limiter works. Behind a load balancer they all arrive from the proxy, and
    without a trusted header ten people signing in would exhaust the allowance
    for everybody at once.
    """

    def _request(self, headers: dict[str, str], peer: str = "10.0.0.1"):
        from starlette.datastructures import Headers
        from starlette.requests import Request

        scope = {
            "type": "http",
            "headers": Headers(headers).raw,
            "client": (peer, 1234),
        }
        return Request(scope)

    def test_the_header_is_ignored_unless_it_is_trusted(self, monkeypatch):
        """Anybody can send X-Forwarded-For. Believing it by default would hand
        every caller a fresh allowance per request."""
        from app.core import rate_limit

        monkeypatch.setattr(rate_limit.get_settings(), "trusted_proxy_header", "", raising=False)
        address = rate_limit.client_address(self._request({"X-Forwarded-For": "1.2.3.4"}))
        assert address == "10.0.0.1"

    def test_a_trusted_header_is_used(self, monkeypatch):
        from app.core import rate_limit

        monkeypatch.setattr(
            rate_limit.get_settings(),
            "trusted_proxy_header",
            "Fly-Client-IP",
            raising=False,
        )
        address = rate_limit.client_address(self._request({"Fly-Client-IP": "203.0.113.7"}))
        assert address == "203.0.113.7"

    def test_a_list_uses_the_entry_the_nearest_proxy_added(self, monkeypatch):
        """X-Forwarded-For is `client, proxy1, proxy2`. Everything left of the
        last entry was supplied by whoever called the proxy, so it can be
        invented; only the rightmost was written by the party we trust."""
        from app.core import rate_limit

        monkeypatch.setattr(
            rate_limit.get_settings(),
            "trusted_proxy_header",
            "X-Forwarded-For",
            raising=False,
        )
        address = rate_limit.client_address(
            self._request({"X-Forwarded-For": "9.9.9.9, 203.0.113.7"})
        )
        assert address == "203.0.113.7"

    def test_a_missing_header_falls_back_to_the_peer(self, monkeypatch):
        from app.core import rate_limit

        monkeypatch.setattr(
            rate_limit.get_settings(),
            "trusted_proxy_header",
            "Fly-Client-IP",
            raising=False,
        )
        assert rate_limit.client_address(self._request({})) == "10.0.0.1"
