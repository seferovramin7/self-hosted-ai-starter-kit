#!/bin/sh
# Reads the current https://<random>.trycloudflare.com URL from the
# cloudflared Quick Tunnel container's logs, and if it changed since the
# last deploy, updates n8n's WEBHOOK_URL/N8N_HOST in .env, restarts n8n,
# and (if TELEGRAM_BOT_TOKEN/TELEGRAM_WEBHOOK_PATH are set) re-registers
# the Telegram webhook against the new URL.
set -e

cd "$(dirname "$0")/.."

echo "Waiting for Cloudflare Quick Tunnel URL..."
TUNNEL_URL=""
i=0
while [ "$i" -lt 30 ]; do
  TUNNEL_URL=$(docker logs cloudflared 2>&1 | grep -oE 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' | tail -1)
  [ -n "$TUNNEL_URL" ] && break
  i=$((i + 1))
  sleep 2
done

if [ -z "$TUNNEL_URL" ]; then
  echo "ERROR: could not read a trycloudflare.com URL from 'docker logs cloudflared'" >&2
  exit 1
fi

CURRENT_WEBHOOK_URL=$(grep -E '^WEBHOOK_URL=' .env 2>/dev/null | cut -d= -f2-)

if [ "$CURRENT_WEBHOOK_URL" = "$TUNNEL_URL" ]; then
  echo "Quick Tunnel URL unchanged ($TUNNEL_URL), nothing to do."
  exit 0
fi

echo "New Quick Tunnel URL: $TUNNEL_URL"
TUNNEL_HOST=$(echo "$TUNNEL_URL" | sed -e 's#https://##')

for KV in "WEBHOOK_URL=$TUNNEL_URL" "N8N_HOST=$TUNNEL_HOST" "N8N_PROTOCOL=https"; do
  KEY=$(echo "$KV" | cut -d= -f1)
  if grep -q "^${KEY}=" .env 2>/dev/null; then
    sed -i.bak "s#^${KEY}=.*#${KV}#" .env
  else
    echo "$KV" >>.env
  fi
done
rm -f .env.bak

echo "Restarting n8n with the new webhook host..."
docker compose up -d n8n

TELEGRAM_BOT_TOKEN=$(grep -E '^TELEGRAM_BOT_TOKEN=' .env 2>/dev/null | cut -d= -f2-)
TELEGRAM_WEBHOOK_PATH=$(grep -E '^TELEGRAM_WEBHOOK_PATH=' .env 2>/dev/null | cut -d= -f2-)

if [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_WEBHOOK_PATH" ]; then
  echo "Registering Telegram webhook..."
  curl -sf -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setWebhook" \
    -d "url=${TUNNEL_URL}/${TELEGRAM_WEBHOOK_PATH}" \
    && echo "Telegram webhook set to ${TUNNEL_URL}/${TELEGRAM_WEBHOOK_PATH}"
else
  echo "TELEGRAM_BOT_TOKEN / TELEGRAM_WEBHOOK_PATH not set in .env - set the Telegram webhook manually to:"
  echo "  ${TUNNEL_URL}/webhook/<your-webhook-path>"
fi
