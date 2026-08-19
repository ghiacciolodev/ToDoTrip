"""Request logging.

Not a nicety: without a parseable line per request and an id to join them on,
the only way to investigate a production failure is to guess.
"""

import json
import logging

from httpx import AsyncClient

from app.core.observability import JsonFormatter, RequestLogMiddleware, request_id

TRIPS = "/api/v1/trips"


def _record(level=logging.INFO, **extra) -> logging.LogRecord:
    record = logging.LogRecord("test", level, __file__, 1, "hello %s", ("world",), None)
    for key, value in extra.items():
        setattr(record, key, value)
    return record


class TestJsonFormat:
    def test_a_line_is_one_json_object(self):
        parsed = json.loads(JsonFormatter().format(_record()))

        assert parsed["message"] == "hello world"
        assert parsed["level"] == "INFO"
        assert "time" in parsed

    def test_the_http_fields_become_top_level_keys(self):
        """So a log viewer can filter on status without matching substrings."""
        parsed = json.loads(
            JsonFormatter().format(_record(http_status=500, http_path="/api/v1/trips"))
        )

        assert parsed["status"] == 500
        assert parsed["path"] == "/api/v1/trips"

    def test_a_traceback_travels_with_its_line(self):
        try:
            raise ValueError("boom")
        except ValueError:
            import sys

            record = _record()
            record.exc_info = sys.exc_info()
            parsed = json.loads(JsonFormatter().format(record))

        assert "ValueError: boom" in parsed["exception"]

    def test_the_request_id_defaults_to_a_placeholder(self):
        """A record written outside a request must still be valid JSON."""
        parsed = json.loads(JsonFormatter().format(_record()))
        assert parsed["request_id"] == "-"


class TestRequestId:
    async def test_every_response_carries_one(self, client: AsyncClient):
        response = await client.get("/health")

        assert response.headers["X-Request-ID"]

    async def test_two_requests_get_different_ids(self, client: AsyncClient):
        first = (await client.get("/health")).headers["X-Request-ID"]
        second = (await client.get("/health")).headers["X-Request-ID"]

        assert first != second

    async def test_a_supplied_id_is_kept(self, client: AsyncClient):
        """So a proxy's logs and ours can be joined on the same value."""
        response = await client.get("/health", headers={"X-Request-ID": "abc123"})

        assert response.headers["X-Request-ID"] == "abc123"

    async def test_an_absurdly_long_id_is_replaced(self, client: AsyncClient):
        """A header is caller-controlled, and an unbounded one ends up in every
        log line for that request."""
        response = await client.get("/health", headers={"X-Request-ID": "x" * 500})

        assert response.headers["X-Request-ID"] != "x" * 500

    async def test_the_context_does_not_leak_between_requests(self, client: AsyncClient):
        await client.get("/health")
        assert request_id.get() == "-"


class TestLevels:
    """What deserves attention, and what would only be noise."""

    def _level(self, path: str, status: int, ms: float) -> int:
        class _Url:
            def __init__(self, p):
                self.path = p

        class _Req:
            def __init__(self, p):
                self.url = _Url(p)

        return RequestLogMiddleware._level_for(_Req(path), status, ms)

    def test_a_server_error_is_an_error(self):
        assert self._level("/api/v1/trips", 500, 5) == logging.ERROR

    def test_throttling_is_a_warning(self):
        # Either an attack or a limit set too low. Both are worth seeing.
        assert self._level("/api/v1/auth/login", 429, 5) == logging.WARNING

    def test_a_slow_success_is_a_warning(self):
        # The shape a problem takes before it becomes an error.
        assert self._level("/api/v1/trips", 200, 3000) == logging.WARNING

    def test_an_ordinary_request_is_information(self):
        assert self._level("/api/v1/trips", 200, 5) == logging.INFO

    def test_the_health_probe_is_kept_quiet(self):
        # Answered every few seconds by whatever watches the process; at INFO it
        # would bury everything else.
        assert self._level("/health", 200, 5) == logging.DEBUG

    def test_a_failing_health_probe_is_not_kept_quiet(self):
        assert self._level("/health", 500, 5) == logging.ERROR
