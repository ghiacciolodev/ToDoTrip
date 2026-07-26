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
