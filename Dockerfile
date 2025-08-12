FROM n8nio/n8n

USER root

# Python + build deps
RUN apk add --no-cache \
    python3 \
    py3-pip \
    build-base \
    python3-dev \
    libffi-dev \
    openssl-dev \
    gcc \
    musl-dev

# Virtualenv
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Python packages
RUN pip install --upgrade pip setuptools wheel

# Keep Garmin working
# (Pin if you prefer: pip install garminconnect==0.2.28)
RUN pip install garminconnect

# Helpers (used by various scripts/workflows)
RUN pip install requests python-dateutil

# n8n persistent data and a place for optional Hevy exports
RUN mkdir -p /home/node/.n8n/hevy && chown -R node:node /home/node/.n8n

# Hevy shim: prints JSON to stdout; optionally writes a file if HEVY_WRITE_FILE=true
RUN tee /opt/hevy_pull.py > /dev/null <<'PY'
#!/usr/bin/env python3
import os, json, time, datetime
from pathlib import Path

EMAIL = os.environ.get("HEVY_EMAIL", "")
PASSWORD = os.environ.get("HEVY_PASSWORD", "")

# Window to fetch (future client use)
DAYS = int(os.environ.get("HEVY_DAYS", "7"))
end = datetime.date.today()
start = end - datetime.timedelta(days=DAYS)

# Optional disk write
OUT_DIR = Path(os.environ.get("HEVY_OUT", "/home/node/.n8n/hevy"))
WRITE_FILE = os.environ.get("HEVY_WRITE_FILE", "false").lower() in ("1", "true", "yes")

# TODO: replace the stub below with a real Hevy client call when you pick one:
# from underthebar import Client
# c = Client()
# c.login(EMAIL, PASSWORD)
# workouts = c.fetch_workouts(start=start.isoformat(), end=end.isoformat())  # list[dict]
workouts = []  # <-- stub so the pipeline runs; will be populated once a client is wired

payload = {
    "success": True,
    "exported_at": int(time.time()),
    "window_start": start.isoformat(),
    "window_end": end.isoformat(),
    "count": len(workouts),
    "workouts": workouts,
}

if WRITE_FILE:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (OUT_DIR / "workouts.json").write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")

# IMPORTANT: print a single JSON object to stdout (for n8n to parse)
print(json.dumps(payload, ensure_ascii=False))
PY

RUN chmod +x /opt/hevy_pull.py

USER node

# Allow Code nodes to import modules if needed
ENV NODE_FUNCTION_ALLOW_BUILTIN=*
ENV NODE_FUNCTION_ALLOW_EXTERNAL=*

# Defaults for the shim (disk copy disabled by default)
ENV HEVY_OUT=/home/node/.n8n/hevy
ENV HEVY_DAYS=7
ENV HEVY_WRITE_FILE=false
