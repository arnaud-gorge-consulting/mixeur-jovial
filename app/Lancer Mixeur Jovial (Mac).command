#!/bin/bash
# Mixeur Jovial sur Mac : petit serveur local (accessible uniquement depuis cet ordinateur).
# Premier lancement : clic droit sur ce fichier > Ouvrir (macOS bloque les scripts téléchargés).
cd "$(dirname "$0")" || exit 1
PORT=8765
while lsof -nP -iTCP:$PORT -sTCP:LISTEN >/dev/null 2>&1; do PORT=$((PORT + 1)); done
URL="http://localhost:$PORT/"
echo ""
echo "  Mixeur Jovial s'ouvre dans votre navigateur : $URL"
echo "  Laissez cette fenêtre ouverte pendant l'utilisation. Fermez-la pour arrêter l'outil."
echo ""
(sleep 1.5; open "$URL") &
if python3 -c "" >/dev/null 2>&1; then
  exec python3 -m http.server "$PORT" --bind 127.0.0.1
elif command -v ruby >/dev/null 2>&1; then
  exec ruby -run -e httpd . -p "$PORT" -b 127.0.0.1
else
  echo "  Python 3 est nécessaire. macOS propose de l'installer (outils de développement) :"
  echo "  acceptez, puis relancez ce fichier."
  read -r -p "  Entrée pour fermer…"
fi
