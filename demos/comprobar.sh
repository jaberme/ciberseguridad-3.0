#!/usr/bin/env bash
# Comprueba una demo: sin red ni almacenamiento, carga en Chrome headless sin errores
# y marca data-ready="1". Uso: demos/comprobar.sh demos/phishing.html
set -euo pipefail
f="$1"
[ -f "$f" ] || { echo "no existe: $f"; exit 1; }
if grep -n -E 'fetch\(|XMLHttpRequest|<script[^>]+src=|href="https?://[^"]*\.css|localStorage|sessionStorage|indexedDB|document\.cookie|navigator\.sendBeacon|WebSocket' "$f"; then
  echo "FALLO: $f usa red o almacenamiento"; exit 1
fi
grep -q 'id="reiniciar"' "$f" || { echo "FALLO: falta el botón reiniciar"; exit 1; }
grep -q 'class="aviso"' "$f" || { echo "FALLO: falta el aviso de simulación"; exit 1; }
log="$(mktemp)"
google-chrome --headless=new --disable-gpu --no-sandbox --allow-file-access-from-files \
  --virtual-time-budget=4000 --enable-logging=stderr --v=0 \
  --dump-dom "file://$(realpath "$f")" 2>"$log" | grep -q 'data-ready="1"' || { echo "FALLO: la demo no marcó data-ready"; grep -i "console" "$log" | head; exit 1; }
if grep -i -E 'CONSOLE.*(error|uncaught)' "$log" | grep -v -i "favicon"; then echo "FALLO: errores de consola"; exit 1; fi
rm -f "$log"
echo "OK: $f"
