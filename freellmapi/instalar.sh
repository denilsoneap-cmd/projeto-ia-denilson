#!/usr/bin/env bash
# Instala/atualiza o FreeLLMAPI via Docker (Linux, macOS ou WSL).
set -euo pipefail
cd "$(dirname "$0")"

command -v docker >/dev/null || { echo "Docker não encontrado." >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "O Docker não está rodando." >&2; exit 1; }

if [ ! -f .env ]; then
  KEY="$(openssl rand -hex 32 2>/dev/null || node -e 'console.log(require("crypto").randomBytes(32).toString("hex"))')"
  printf "ENCRYPTION_KEY=%s\nPORT=3001\n" "$KEY" > .env
  chmod 600 .env
  echo ".env criado com uma nova ENCRYPTION_KEY (guarde um backup deste arquivo)."
else
  echo ".env já existe — mantendo a ENCRYPTION_KEY atual."
fi

docker compose pull
docker compose up -d

echo "Aguardando o FreeLLMAPI subir..."
for _ in $(seq 1 30); do
  if curl -fsS http://localhost:3001/api/ping >/dev/null 2>&1; then
    echo "FreeLLMAPI rodando: http://localhost:3001"
    echo "API OpenAI-compatível: http://localhost:3001/v1"
    exit 0
  fi
  sleep 2
done
echo "Não respondeu a tempo. Veja os logs: docker compose logs -f freellmapi" >&2
exit 1
