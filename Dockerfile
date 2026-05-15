FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/
RUN python -m pip install --upgrade pip && pip install --no-cache-dir -r requirements.txt

COPY . /app
RUN chmod +x /app/docker-entrypoint.sh

ENV PYTHONUNBUFFERED=1
ENTRYPOINT ["/app/docker-entrypoint.sh"]
