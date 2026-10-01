# Configurar provedores, fallback e agentes

Próximo passo depois do `instalar.ps1`. O FreeLLMAPI **não cria contas nem gera keys**:
você cria a key em cada provedor e cola no painel, e o router junta tudo e faz o fallback.

Baseado no *Guía práctica FreeLLMAPI* (Alejavi Rivera, set/2026).

## 1. Ordem recomendada

| # | Provedor | Para quê | Onde gerar a key |
|---|----------|----------|------------------|
| 1 | **Google AI Studio** | equilíbrio, visão, contexto longo | <https://aistudio.google.com/apikey> |
| 2 | **Groq** | velocidade, Whisper/transcrição | <https://console.groq.com/keys> |
| 3 | **NVIDIA NIM** | modelos open potentes | <https://build.nvidia.com> |
| 4 | **Mistral** | coding (Codestral/Devstral) | <https://console.mistral.ai/api-keys> |
| 5 | **OpenRouter** | rede de segurança (modelos `:free`) | <https://openrouter.ai/keys> |

Opcionais, só quando houver motivo: Kilo Gateway (mais fallback), Cohere (RAG/embeddings),
Cloudflare (imagem, pede também o *Account ID*), Hugging Face, Cerebras, Z.ai e ModelScope.

## 2. Como adicionar cada provedor

1. Crie a conta no provedor. Se quiser separar testes de produção, use um e-mail dedicado.
2. Gere a key no menu *API Keys*, *Tokens* ou *Credentials*.
3. No painel (<http://localhost:3001>), abra **Keys**, escolha o provedor e cole a key.
4. Clique em testar e confira em **Models** quais modelos ficaram disponíveis.

> Teste cada provedor antes de adicionar o próximo. E use sempre a Base URL que a sua
> instalação mostra (`http://localhost:3001/v1`), não a porta de algum tutorial.

## 3. Cadeias de fallback (página **Fallback Chain** / perfis)

| Objetivo | Ordem |
|----------|-------|
| Coding / agentes | NVIDIA → Mistral → Google → OpenRouter → Kilo |
| Velocidade máxima | Groq → Mistral → Google |
| Raciocínio geral | Google → NVIDIA → OpenRouter → Cohere |
| RAG / documentos | Google → Cohere → Cloudflare |
| Tudo grátis e fácil | Google → Groq → Mistral → OpenRouter → Kilo |

Também dá para escolher a estratégia em cada requisição: `auto` segue a cadeia ativa, e
`auto:fast`, `auto:smart` e `auto:reliable` ignoram a ordem e ranqueiam os modelos.
O modelo virtual `fusion` consulta vários modelos e sintetiza uma resposta só.

## 4. Testar

```powershell
.\testar.ps1 -Key freellmapi-SUA-CHAVE
```

(`./testar.sh freellmapi-SUA-CHAVE` no Linux/WSL.) O script lista os modelos, faz uma
pergunta e mostra no cabeçalho `X-Routed-Via` qual provedor respondeu.

## 5. Conectar agentes de código

```bash
npx freellmapi setup-claude     # Claude Code
npx freellmapi setup-codex      # Codex CLI
npx freellmapi setup-dsh        # DeepSeek Harness
npx freellmapi setup-opencode   # OpenCode
npx freellmapi setup-aider      # Aider
```

Esses comandos fazem backup da configuração atual antes de alterar.
Fluxo: seu agente → FreeLLMAPI → provedor disponível → resposta.

## 6. Problemas comuns

| Sintoma | O que fazer |
|---------|-------------|
| Modelo aparece como "sem key" | O provedor dele ainda não está conectado. |
| Teste da key falha | Gere a key de novo, remova espaços e veja se o provedor pede um dado extra (como o Account ID). |
| Modelo não aparece | Ele pode estar fora do snapshot gratuito, que chega ~30 dias depois do Premium. |
| Erro 429 / rate limit | A cota acabou. Ative o fallback ou conecte outro provedor. |
| Agente não gera imagem/vídeo | Chat e multimídia são endpoints diferentes, e nem todo cliente chama os de multimídia. |

## 7. Segurança

- Trate cada key como uma senha e não deixe nenhuma aparecer em print, terminal ou gravação.
- O router roda local, mas a inferência acontece no provedor. Leia a política de dados dele antes de mandar informação sensível.
- Não exponha o FreeLLMAPI na internet. Por padrão ele só escuta em `127.0.0.1`.

## Checklist final

- [ ] Google conectado e testado
- [ ] Groq conectado e testado
- [ ] NVIDIA ou Mistral como segundo provedor forte
- [ ] OpenRouter ou Kilo como rede de segurança
- [ ] Um caso real rodando a partir de um agente (Claude Code, Codex ou DeepSeek Harness)
- [ ] A página **Analytics** mostrando qual rota respondeu
- [ ] Nenhuma API key visível em tela ou commitada no git
