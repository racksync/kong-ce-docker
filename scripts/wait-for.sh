#!/bin/bash
# wait-for.sh - Wait for a service to be ready
# Usage: ./scripts/wait-for.sh <host> <port> [service_name] [timeout]

set -e

HOST="$1"
PORT="$2"
SERVICE_NAME="${3:-service}"
TIMEOUT="${4:-120}"

if [ -z "$HOST" ] || [ -z "$PORT" ]; then
    echo "Usage: $0 <host> <port> [service_name] [timeout]"
    exit 1
fi

echo "Waiting for $SERVICE_NAME at $HOST:$PORT to be ready..."
echo "Timeout: ${TIMEOUT}s"

start_time=$(date +%s)

while true; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))

    if [ "$elapsed" -ge "$TIMEOUT" ]; then
        echo "ERROR: Timeout waiting for $SERVICE_NAME after ${TIMEOUT}s"
        exit 1
    fi

    if nc -z "$HOST" "$PORT" 2>/dev/null; then
        echo "$SERVICE_NAME is ready! (${elapsed}s)"
        exit 0
    fi

    echo "  $SERVICE_NAME not ready yet... (${elapsed}s elapsed)"
    sleep 2
done
