# Testa o FreeLLMAPI: lista modelos e faz uma pergunta usando a chave unificada.
# Uso: .\testar.ps1 -Key freellmapi-SUA-CHAVE [-Model auto] [-BaseUrl http://localhost:3001/v1]
param(
    [string]$Key = $env:FREELLMAPI_KEY,
    [string]$Model = 'auto',
    [string]$BaseUrl = 'http://localhost:3001/v1'
)
$ErrorActionPreference = 'Stop'
if (-not $Key) { Write-Error "Informe a chave: .\testar.ps1 -Key freellmapi-... (ou defina FREELLMAPI_KEY)" }
$Headers = @{ Authorization = "Bearer $Key" }

$Models = Invoke-RestMethod -Uri "$BaseUrl/models" -Headers $Headers
Write-Host "Modelos disponíveis: $($Models.data.Count)"

$Body = @{
    model    = $Model
    messages = @(@{ role = 'user'; content = 'Responda em uma frase: o que é um gateway de LLM?' })
} | ConvertTo-Json -Depth 5
$Resp = Invoke-WebRequest -UseBasicParsing -Method Post -Uri "$BaseUrl/chat/completions" `
    -Headers $Headers -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($Body))
$Json = [Text.Encoding]::UTF8.GetString($Resp.RawContentStream.ToArray()) | ConvertFrom-Json

Write-Host "Respondido por: $($Resp.Headers['X-Routed-Via'])"
if ($Resp.Headers['X-Fallback-Attempts']) { Write-Host "Fallbacks: $($Resp.Headers['X-Fallback-Attempts'])" }
Write-Host ""
Write-Host $Json.choices[0].message.content
