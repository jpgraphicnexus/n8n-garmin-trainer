FROM n8nio/n8n

USER root

# Install Python and build dependencies (if you already had these, leaving them is fine)
RUN apk add --no-cache \
    python3 \
    py3-pip \
    build-base \
    python3-dev \
    libffi-dev \
    openssl-dev \
    gcc \
    musl-dev

# Create virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip and install Python packages
RUN pip install --upgrade pip setuptools wheel

# Install Hevy client (choose ONE line)
# 1) If the client is on PyPI (example name "underthebar"):
# RUN pip install underthebar

# 2) Or install from GitHub:
# RUN pip install "git+https://github.com/<owner>/<repo>.git#egg=underthebar"

# OPTIONAL: If you need any auth helpers (e.g. requests)
RUN pip install requests python-dateutil

# Ensure persistent n8n data folder exists and is owned by node
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node/.n8n

# Create a persistent Hevy export folder inside the mounted disk
RUN mkdir -p /home/node/.n8n/hevy && chown -R node:node /home/node/.n8n/hevy

# Add the Hevy shim (writes a single JSON file and prints its path)
# Replace pseudocode with real client calls when ready.
RUN tee /opt/hevy_pull.py > /dev/null <<'PY'
import os, json, time
from pathlib import Path

EMAIL = os.environ.get("HEVY_EMAIL", "")
PASSWORD = os.environ.get("HEVY_PASSWORD", "")
OUT_DIR = Path(os.environ.get("HEVY_OUT", "/home/node/.n8n/hevy"))
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Pseudocode - replace with real client usage
# from underthebar import Client
# c = Client().login(EMAIL, PASSWORD)
# workouts = c.fetch_all_workouts()  # list[dict]

workouts = []  # TODO: replace with actual workouts list

out = {
    "exported_at": int(time.time()),
    "count": len(workouts),
    "workouts": workouts,
}
out_path = OUT_DIR / "workouts.json"
out_path.write_text(json.dumps(out), encoding="utf-8")

# Print absolute path for n8n to capture via stdout
print(str(out_path))
PY

RUN chmod +x /opt/hevy_pull.py

# Switch back to node
USER node

# Let Code nodes import modules if needed
ENV NODE_FUNCTION_ALLOW_BUILTIN=*
ENV NODE_FUNCTION_ALLOW_EXTERNAL=*

# Set defaults for the shim
ENV HEVY_OUT=/home/node/.n8n/hevy
