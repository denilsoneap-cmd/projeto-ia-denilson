#!/usr/bin/env bash
# Testa o FreeLLMAPI: lista modelos e faz uma pergunta usando a chave unificada.
# Uso: ./testar.sh freellmapi-SUA-CHAVE [modelo]   (ou defina FREELLMAPI_KEY)
set -euo pipefail
KEY="${1:-${FREELLMAPI_KEY:-}}"
MODEL="${2:-auto}"
BASE_URL="${BASE_URL:-http://localhost:3001/v1}"
[ -n "$KEY" ] || { echo "Uso: $0 freellmapi-SUA-CHAVE [modelo]" >&2; exit 1; }

COUNT="$(curl -fsS "$BASE_URL/models" -H "Authorization: Bearer $KEY" | grep -o '"id"' | wc -l)"
echo "Modelos disponíveis: $COUNT"

HDRS="$(mktemp)"; trap 'rm -f "$HDRS"' EXIT
BODY="$(curl -fsS -D "$HDRS" "$BASE_URL/chat/completions" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Responda em uma frase: o que é um gateway de LLM?\"}]}")"

grep -i '^x-routed-via:' "$HDRS" | sed 's/^[^:]*: */Respondido por: /' || true
grep -i '^x-fallback-attempts:' "$HDRS" | sed 's/^[^:]*: */Fallbacks: /' || true
echo
if command -v python3 >/dev/null; then
  printf '%s' "$BODY" | python3 -c 'import sys,json; print(json.load(sys.stdin)["choices"][0]["message"]["content"])'
else
  printf '%s\n' "$BODY"
fi
