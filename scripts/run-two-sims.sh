#!/usr/bin/env bash
# Launch Replicaz on two iOS sims sequentially (avoids parallel Xcode/SPM races).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEFINES=(
  --dart-define=API_HOST=http://127.0.0.1:9010
  --dart-define=CMF_WS_URL=ws://127.0.0.1:8088
  --dart-define=USE_REMOTE_BACKEND=true
)

# Prefer already-booted devices; else boot Pro + Pro Max by name match.
mapfile -t BOOTED < <(xcrun simctl list devices booted | sed -n 's/.*(\([A-F0-9-]\{36\}\)).*/\1/p')
if [[ ${#BOOTED[@]} -lt 2 ]]; then
  echo "Boot two iPhone sims first (Simulator app), need ≥2 booted." >&2
  xcrun simctl list devices available | rg -i 'iphone' | head -20 || true
  exit 1
fi

A="${BOOTED[0]}"
B="${BOOTED[1]}"
echo "Device A=$A"
echo "Device B=$B"

echo "→ Building once on A…"
flutter run -d "$A" "${DEFINES[@]}" &
PID_A=$!
# Wait until first run is past first frame is hard; user keeps both running.
echo "PID_A=$PID_A — start B after A shows Flutter run key commands, or wait ~60s"
sleep 55
echo "→ Starting B…"
flutter run -d "$B" "${DEFINES[@]}" &
PID_B=$!
echo "PID_B=$PID_B"
echo "Both flutter run in background of this shell — Ctrl+C does not kill children; use pkill flutter if needed."
wait
