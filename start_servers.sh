#!/usr/bin/env bash
# Helper script to restart FastAPI (uvicorn) and ngrok tunnel for LetsLinkLite backend
echo "Starting uvicorn server on http://0.0.0.0:8000..."
echo "Starting ngrok tunnel on port 8000..."
#!/usr/bin/env bash
# Helper to start Uvicorn and/or ngrok tunnel
set -e

usage() {
  echo "Usage: $0 {uvicorn|ngrok|all}" >&2
  exit 1
}

case "$1" in
  uvicorn)
    pkill -f "ScraperAgent.server:app" || true
    echo "Starting uvicorn on http://0.0.0.0:8000..."
    uvicorn ScraperAgent.server:app --reload --host 0.0.0.0 --port 8000
    ;;
  ngrok)
    echo "Starting ngrok tunnel on port 8000..."
    ngrok http 8000
    ;;
  all)
    pkill -f "ScraperAgent.server:app" || true
    echo "Starting uvicorn in background on http://0.0.0.0:8000..."
    uvicorn ScraperAgent.server:app --reload --host 0.0.0.0 --port 8000 &
    sleep 1
    echo "Starting ngrok tunnel on port 8000..."
    ngrok http 8000
    ;;
  *)
    usage
    ;;
esac