FROM n8nio/n8n

USER root

# Install Python and build dependencies
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
RUN pip install --no-cache-dir \
    garminconnect \
    requests \
    python-dateutil

# Switch back to node user for security
USER node

# Allow N8N to use external modules
ENV NODE_FUNCTION_ALLOW_BUILTIN=*
ENV NODE_FUNCTION_ALLOW_EXTERNAL=*

# Use the same entrypoint as the base n8n image
ENTRYPOINT ["tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
CMD ["n8n"]
