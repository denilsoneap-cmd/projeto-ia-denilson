# FreeLLMAPI

Gateway **OpenAI-compatível** que junta os planos gratuitos de dezenas de provedores de LLM
(Google Gemini, Groq, Cerebras, Mistral, OpenRouter, NVIDIA, Cloudflare etc.) atrás de um único endpoint `/v1`.
Ele também expõe `/v1/messages` (formato Anthropic), então Claude Code e os SDKs da Anthropic funcionam com ele.

Projeto original: <https://github.com/tashfeenahmed/freellmapi> (licença MIT).

## Opção 1 — Windows, app desktop (mais simples)

Baixe o instalador `.exe` em <https://github.com/tashfeenahmed/freellmapi/releases/latest>.
Esse app não pede login. A chave unificada fica no ícone da bandeja (**Copy Key**).

## Opção 2 — Docker (esta pasta)

Requisito: Docker Desktop instalado e aberto.

```powershell
winget install -e --id Docker.DockerDesktop   # se ainda não tiver
cd freellmapi
powershell -ExecutionPolicy Bypass -File .\instalar.ps1
```

No Linux, macOS ou WSL use `./instalar.sh`.

O script faz o seguinte:

1. Cria o `.env` com uma `ENCRYPTION_KEY` aleatória. Esse arquivo não vai para o git. **Faça um backup dele**, porque sem ele as keys cadastradas ficam ilegíveis.
2. Baixa a imagem `ghcr.io/tashfeenahmed/freellmapi` e sobe o container na porta 3001 (só em `localhost`).
3. Espera o serviço responder em `/api/ping`.

Rodar o script de novo atualiza o FreeLLMAPI e mantém o `.env` que já existe.

## Primeiros passos

1. Abra <http://localhost:3001> e crie a conta de administrador.
2. Na página **Keys**, adicione as API keys gratuitas dos provedores (por exemplo Google AI Studio, Groq, Cerebras e OpenRouter).
3. Copie a **chave unificada** (`freellmapi-…`) que aparece no topo da página **Keys**.
4. Teste com `.\testar.ps1 -Key freellmapi-...` (ou `./testar.sh freellmapi-...`).

O guia completo (quais provedores conectar, onde gerar as keys, cadeias de fallback, agentes e checklist) está em **[PROVEDORES.md](PROVEDORES.md)**.

## Usando a API

```python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:3001/v1", api_key="freellmapi-...")
resp = client.chat.completions.create(
    model="auto",
    messages=[{"role": "user", "content": "Olá!"}],
)
print(resp.choices[0].message.content)
```

Para configurar agentes de código automaticamente: `npx freellmapi setup-claude`, `setup-codex`, `setup-aider`…

## Comandos úteis

| Ação | Comando |
|------|---------|
| Ver logs | `docker compose logs -f freellmapi` |
| Parar | `docker compose down` |
| Atualizar | rodar `instalar.ps1` / `instalar.sh` de novo |
| Acessar pela rede local | `HOST_BIND=0.0.0.0 docker compose up -d` (só em rede confiável) |
| Desinstalar e apagar dados | `docker compose down -v` |

Esqueceu a senha do painel? Clique em **Forgot password?** e procure o código de reset nos logs.
