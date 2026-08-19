"""Authentication endpoint tests, mirroring the manual checks on /docs."""

from pathlib import Path

from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import legal
from app.models import RefreshToken, User

REGISTER = "/api/v1/auth/register"
LOGIN = "/api/v1/auth/login"
REFRESH = "/api/v1/auth/refresh"
LOGOUT = "/api/v1/auth/logout"
ME = "/api/v1/auth/me"


class TestRegister:
    async def test_creates_user(self, client: AsyncClient):
        response = await client.post(
            REGISTER,
            json={
                "email": "new@test.it",
                "password": "password123",
                "display_name": "New",
                "accepted_privacy": True,
            },
        )
        assert response.status_code == 201
        assert response.json()["email"] == "new@test.it"

    async def test_response_never_exposes_the_hash(self, client: AsyncClient):
        response = await client.post(
            REGISTER,
            json={
                "email": "new@test.it",
                "password": "password123",
                "display_name": "New",
                "accepted_privacy": True,
            },
        )
        assert "password_hash" not in response.json()
        assert "password" not in response.json()

    async def test_duplicate_email_is_rejected(self, client: AsyncClient, registered_user: dict):
        response = await client.post(REGISTER, json=registered_user)
        assert response.status_code == 409

    async def test_email_is_case_insensitive(self, client: AsyncClient, registered_user: dict):
        """MARIO@TEST.IT and mario@test.it must be the same account."""
        response = await client.post(
            REGISTER,
            json={**registered_user, "email": registered_user["email"].upper()},
        )
        assert response.status_code == 409

    async def test_short_password_is_rejected(self, client: AsyncClient):
        response = await client.post(
            REGISTER, json={"email": "a@test.it", "password": "short", "display_name": "A"}
        )
        assert response.status_code == 422

    async def test_malformed_email_is_rejected(self, client: AsyncClient):
        response = await client.post(
            REGISTER, json={"email": "not-an-email", "password": "password123", "display_name": "A"}
        )
        assert response.status_code == 422

    async def test_password_is_stored_hashed(
        self, client: AsyncClient, registered_user: dict, db: AsyncSession
    ):
        user = await db.scalar(select(User).where(User.email == registered_user["email"]))
        assert user.password_hash != registered_user["password"]
        assert user.password_hash.startswith("$argon2")


class TestLogin:
    async def test_returns_a_token_pair(self, client: AsyncClient, registered_user: dict):
        response = await client.post(
            LOGIN, json={"email": registered_user["email"], "password": registered_user["password"]}
        )
        assert response.status_code == 200
        assert response.json()["access_token"]
        assert response.json()["refresh_token"]

    async def test_wrong_password_is_rejected(self, client: AsyncClient, registered_user: dict):
        response = await client.post(
            LOGIN, json={"email": registered_user["email"], "password": "wrong-password"}
        )
        assert response.status_code == 401

    async def test_unknown_email_looks_identical_to_a_wrong_password(self, client: AsyncClient):
        """Distinct responses would let an attacker enumerate registered emails."""
        response = await client.post(
            LOGIN, json={"email": "ghost@test.it", "password": "password123"}
        )
        assert response.status_code == 401
        assert response.json()["detail"] == "Invalid credentials"


class TestProtectedRoutes:
    async def test_rejects_missing_token(self, client: AsyncClient):
        assert (await client.get(ME)).status_code == 401

    async def test_rejects_garbage_token(self, client: AsyncClient):
        response = await client.get(ME, headers={"Authorization": "Bearer not.a.jwt"})
        assert response.status_code == 401

    async def test_rejects_a_refresh_token_used_as_access_token(
        self, client: AsyncClient, tokens: dict
    ):
        """The `type` claim is what stops a long-lived token opening the API."""
        response = await client.get(
            ME, headers={"Authorization": f"Bearer {tokens['refresh_token']}"}
        )
        assert response.status_code == 401

    async def test_accepts_a_valid_token(
        self, client: AsyncClient, auth_headers: dict, registered_user: dict
    ):
        response = await client.get(ME, headers=auth_headers)
        assert response.status_code == 200
        assert response.json()["email"] == registered_user["email"]


class TestRefreshRotation:
    async def test_returns_a_new_pair(self, client: AsyncClient, tokens: dict):
        response = await client.post(REFRESH, json={"refresh_token": tokens["refresh_token"]})
        assert response.status_code == 200
        assert response.json()["refresh_token"] != tokens["refresh_token"]

    async def test_old_token_dies_on_use(self, client: AsyncClient, tokens: dict):
        """Single-use refresh tokens make a stolen token detectable."""
        await client.post(REFRESH, json={"refresh_token": tokens["refresh_token"]})
        replay = await client.post(REFRESH, json={"refresh_token": tokens["refresh_token"]})
        assert replay.status_code == 401

    async def test_unknown_token_is_rejected(self, client: AsyncClient):
        response = await client.post(REFRESH, json={"refresh_token": "made-up-token"})
        assert response.status_code == 401


class TestLogout:
    async def test_revokes_the_token(self, client: AsyncClient, tokens: dict):
        assert (
            await client.post(LOGOUT, json={"refresh_token": tokens["refresh_token"]})
        ).status_code == 204
        replay = await client.post(REFRESH, json={"refresh_token": tokens["refresh_token"]})
        assert replay.status_code == 401

    async def test_marks_the_row_revoked(self, client: AsyncClient, tokens: dict, db: AsyncSession):
        await client.post(LOGOUT, json={"refresh_token": tokens["refresh_token"]})
        stored = await db.scalar(select(RefreshToken))
        assert stored.revoked_at is not None

    async def test_is_idempotent(self, client: AsyncClient):
        """Logging out twice, or with a bogus token, must not error."""
        response = await client.post(LOGOUT, json={"refresh_token": "never-existed"})
        assert response.status_code == 204


class TestPrivacyConsent:
    """The tick box is enforced here, not only on the sign-up screen.

    A rule that lives in the UI is not a rule: this endpoint can be called
    without the app, and then nobody agreed to anything.
    """

    async def test_refusing_blocks_the_account(self, client: AsyncClient):
        response = await client.post(
            REGISTER,
            json={
                "email": "refuser@test.it",
                "password": "password123",
                "display_name": "Refuser",
                "accepted_privacy": False,
            },
        )

        assert response.status_code == 422

    async def test_omitting_the_field_blocks_the_account(self, client: AsyncClient):
        """Not defaulted to true, so a client that forgets it is refused rather
        than consenting on the user's behalf."""
        response = await client.post(
            REGISTER,
            json={
                "email": "forgetful@test.it",
                "password": "password123",
                "display_name": "Forgetful",
            },
        )

        assert response.status_code == 422

    async def test_a_refused_signup_creates_nothing(self, client: AsyncClient):
        """Otherwise the second attempt would hit "email already registered"."""
        payload = {
            "email": "twice@test.it",
            "password": "password123",
            "display_name": "Twice",
        }
        await client.post(REGISTER, json={**payload, "accepted_privacy": False})

        accepted = await client.post(REGISTER, json={**payload, "accepted_privacy": True})
        assert accepted.status_code == 201

    async def test_accepting_is_recorded_with_its_version(
        self, client: AsyncClient, db: AsyncSession
    ):
        """A boolean would prove nothing once the document has been edited: the
        version says what the person was actually shown."""
        await client.post(
            REGISTER,
            json={
                "email": "consenting@test.it",
                "password": "password123",
                "display_name": "Consenting",
                "accepted_privacy": True,
            },
        )

        user = await db.scalar(select(User).where(User.email == "consenting@test.it"))
        assert user.privacy_accepted_at is not None
        assert user.privacy_version == legal.PRIVACY_POLICY_VERSION

    async def test_the_consent_never_leaves_the_server(self, client: AsyncClient):
        """It is a record about the user, not a field the client gets to read
        back or set."""
        response = await client.post(
            REGISTER,
            json={
                "email": "quiet@test.it",
                "password": "password123",
                "display_name": "Quiet",
                "accepted_privacy": True,
            },
        )

        assert "privacy_accepted_at" not in response.json()
        assert "privacy_version" not in response.json()

    async def test_the_version_matches_the_document(self):
        """The constant and the date printed at the top of the policy have to
        agree, or the record points at a version nobody can find."""
        policy = Path("../mobile/assets/legal/privacy-policy.md").read_text(encoding="utf-8")
        assert legal.PRIVACY_POLICY_VERSION == "2026-08-19"
        assert "19 August 2026" in policy
