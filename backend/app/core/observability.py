"""Logging that is worth reading when something goes wrong in production.

Two things make logs useful and both were missing: a **format a machine can
parse**, so a hosted log viewer can filter by status or path rather than by
substring, and a **request id**, so the several lines one request produces can
be pulled back together — and so a user reporting a failure has something to
quote.

Standard library only. A tracing stack is the right answer at a size this
project is not, and an unparseable log is not a reason to add one.
"""

import json
import logging
import sys
import time
import uuid
from contextvars import ContextVar

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

# Carries the id of the request being served to every log record written while
# it is served, without threading it through every function that might log.
request_id: ContextVar[str] = ContextVar("request_id", default="-")

# Above this, a request is worth noticing even when it succeeded.
SLOW_REQUEST_MS = 1000

# Answered constantly by whatever is watching the process. Logging each one at
# INFO would bury everything else.
_QUIET_PATHS = {"/health"}


class _RequestIdFilter(logging.Filter):
    def filter(self, record: logging.LogRecord) -> bool:
        record.request_id = request_id.get()
        return True


class JsonFormatter(logging.Formatter):
    """One JSON object per line.

    Chosen over a pretty format because logs are read by a machine first: every
    hosted viewer can filter on a field, and none can reliably parse prose.
    """

    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "time": self.formatTime(record, "%Y-%m-%dT%H:%M:%S%z"),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "request_id": getattr(record, "request_id", "-"),
        }
        # Whatever the call site attached with extra=..., minus the noise
        # logging puts on every record.
        for key, value in record.__dict__.items():
            if key.startswith("http_"):
                payload[key[5:]] = value
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload, default=str)


def configure_logging(*, level: str, human_readable: bool) -> None:
    """Install one handler on the root logger.

    Human-readable while developing, JSON everywhere else: reading JSON in a
    terminal is miserable, and grepping prose in a log viewer is worse.
    """
    handler = logging.StreamHandler(sys.stdout)
    handler.addFilter(_RequestIdFilter())
    handler.setFormatter(
        logging.Formatter("%(asctime)s %(levelname)-7s [%(request_id)s] %(name)s: %(message)s")
        if human_readable
        else JsonFormatter()
    )

    root = logging.getLogger()
    root.handlers = [handler]
    root.setLevel(level.upper())

    # Uvicorn installs its own access log, which would double every line this
    # middleware already writes, in a format nothing else uses.
    logging.getLogger("uvicorn.access").handlers = []
    logging.getLogger("uvicorn.access").propagate = False


class RequestLogMiddleware(BaseHTTPMiddleware):
    """One line per request: who, what, the outcome and how long it took."""

    def __init__(self, app, *, logger_name: str = "todotrip.request") -> None:
        super().__init__(app)
        self._log = logging.getLogger(logger_name)

    async def dispatch(self, request: Request, call_next) -> Response:
        # An inbound id is honoured so a proxy or a client can correlate its own
        # logs with ours; otherwise one is minted here.
        incoming = request.headers.get("X-Request-ID")
        rid = incoming if incoming and len(incoming) <= 64 else uuid.uuid4().hex[:12]
        token = request_id.set(rid)

        started = time.perf_counter()
        try:
            response = await call_next(request)
        except Exception:
            # Logged here as well as by the handler, because this is the only
            # place that knows which request it was and how long it had run.
            self._log.exception(
                "unhandled error",
                extra={
                    "http_method": request.method,
                    "http_path": request.url.path,
                    "http_duration_ms": round((time.perf_counter() - started) * 1000, 1),
                },
            )
            request_id.reset(token)
            raise

        duration_ms = round((time.perf_counter() - started) * 1000, 1)
        response.headers["X-Request-ID"] = rid

        self._log.log(
            self._level_for(request, response.status_code, duration_ms),
            "%s %s -> %s in %sms",
            request.method,
            request.url.path,
            response.status_code,
            duration_ms,
            extra={
                "http_method": request.method,
                "http_path": request.url.path,
                "http_status": response.status_code,
                "http_duration_ms": duration_ms,
            },
        )
        request_id.reset(token)
        return response

    @staticmethod
    def _level_for(request: Request, status: int, duration_ms: float) -> int:
        """What deserves attention.

        Server errors and throttling are the two things worth waking up to: one
        is a bug, the other is either an attack or a limit set too low. A slow
        success is worth a warning too — it is the shape a problem takes before
        it becomes an error.
        """
        if status >= 500:
            return logging.ERROR
        if status == 429 or duration_ms >= SLOW_REQUEST_MS:
            return logging.WARNING
        if request.url.path in _QUIET_PATHS:
            return logging.DEBUG
        return logging.INFO
