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

# Python packages (pin or float as you prefer)
RUN pip install --upgrade pip setuptools wheel

# IMPORTANT: install garminconnect again
# Pin to a recent, working version if you like:
# RUN pip install garminconnect==0.2.28
RUN pip install garminconnect

# Optional helpers used elsewhere
RUN pip install requests python-dateutil

# (Optional) Install Hevy client here if/when you have the real package
# RUN pip install underthebar
# or from GitHub
# RUN pip install "git+https://github.com/<owner>/<repo>.git#egg=underthebar"

# Ensure n8n data dir exists and is owned by node
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node/.n8n

# Hevy export directory (on the mounted disk)
RUN mkdir -p /home/node/.n8n/hevy && chown -R node:node /home/node/.n8n/hevy

# Hevy shim (still placeholder until you wire the client)
RUN tee /opt/hevy_pull.py > /dev/null <<'PY'
import os, json, time
from pathlib import Path

EMAIL = os.environ.get("HEVY_EMAIL", "")
PASSWORD = os.environ.get("HEVY_PASSWORD", "")
OUT_DIR = Path(os.environ.get("HEVY_OUT", "/home/node/.n8n/hevy"))
OUT_DIR.mkdir(parents=True, exist_ok=True)

# TODO: replace with real client calls
workouts = []

out = {
    "exported_at": int(time.time()),
    "count": len(workouts),
    "workouts": workouts,
}
out_path = OUT_DIR / "workouts.json"
out_path.write_text(json.dumps(out), encoding="utf-8")
print(str(out_path))
PY

RUN chmod +x /opt/hevy_pull.py

USER node

# Allow Code nodes to import modules if needed
ENV NODE_FUNCTION_ALLOW_BUILTIN=*
ENV NODE_FUNCTION_ALLOW_EXTERNAL=*

# Defaults for the shim
ENV HEVY_OUT=/home/node/.n8n/hevy
