# Corrige "Ollama nao esta conectado": instala, inicia o servidor e baixa o modelo.
# Uso:  powershell -ExecutionPolicy Bypass -File .\ollama\corrigir_ollama.ps1 [-Modelo llama3.2]
param(
    [string]$Modelo = "llama3.2",
    [int]$TimeoutSegundos = 60
)

$ErrorActionPreference = "Stop"

function Escrever($msg, $cor = "White") { Write-Host $msg -ForegroundColor $cor }

function Atualizar-Path {
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [Environment]::GetEnvironmentVariable("Path", "User") + ";" +
                "$env:LOCALAPPDATA\Programs\Ollama"
}

function Obter-Url {
    $h = $env:OLLAMA_HOST
    if ([string]::IsNullOrWhiteSpace($h) -or $h -match '^0\.0\.0\.0') { return "http://localhost:11434" }
    if ($h -notmatch '^https?://') { $h = "http://$h" }
    if ($h -notmatch ':\d+$') { $h = "$h`:11434" }
    return $h.TrimEnd('/')
}

function Testar-Servidor($url) {
    try { return Invoke-RestMethod -Uri "$url/api/tags" -TimeoutSec 3 } catch { return $null }
}

# 1. Instalacao
Escrever "[1/4] Verificando instalacao do Ollama..." Cyan
Atualizar-Path
if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
    Escrever "  Ollama nao encontrado. Instalando via winget..." Yellow
    winget install --id Ollama.Ollama -e --accept-source-agreements --accept-package-agreements
    Atualizar-Path
    if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
        Escrever "  ERRO: instalacao falhou. Baixe manualmente em https://ollama.com/download" Red
        exit 1
    }
}
Escrever "  OK: $(ollama --version)" Green

# 2. Servidor
$url = Obter-Url
Escrever "[2/4] Verificando servidor em $url ..." Cyan
if (-not (Testar-Servidor $url)) {
    Escrever "  Servidor parado. Iniciando 'ollama serve' em segundo plano..." Yellow
    Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
    $inicio = Get-Date
    while (-not (Testar-Servidor $url)) {
        if (((Get-Date) - $inicio).TotalSeconds -gt $TimeoutSegundos) {
            Escrever "  ERRO: servidor nao respondeu em $TimeoutSegundos s." Red
            Escrever "  Verifique se outro programa usa a porta 11434:  netstat -ano | findstr 11434" Red
            Escrever "  Ou se o firewall/antivirus bloqueia o ollama.exe." Red
            exit 1
        }
        Start-Sleep -Seconds 2
    }
}
Escrever "  OK: servidor respondendo." Green

# 3. Modelo
Escrever "[3/4] Verificando modelo '$Modelo'..." Cyan
$tags = Testar-Servidor $url
$nomes = @($tags.models | ForEach-Object { $_.name })
if (-not ($nomes | Where-Object { $_ -eq $Modelo -or $_ -like "$Modelo`:*" })) {
    Escrever "  Modelo ausente. Baixando (pode demorar)..." Yellow
    ollama pull $Modelo
    if ($LASTEXITCODE -ne 0) { Escrever "  ERRO ao baixar '$Modelo'." Red; exit 1 }
}
Escrever "  OK: modelo disponivel." Green

# 4. Teste de geracao
Escrever "[4/4] Testando geracao..." Cyan
try {
    $body = @{ model = $Modelo; prompt = "Responda apenas: ok"; stream = $false } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$url/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 300
    Escrever "  Resposta: $($r.response.Trim())" Green
} catch {
    Escrever "  ERRO no teste de geracao: $($_.Exception.Message)" Red
    exit 1
}

Escrever "`nPronto! Ollama conectado em $url. Seu script deve conectar na proxima iteracao (ate 1 min)." Green
Escrever "Dica: se seu script roda em Docker/WSL, use http://host.docker.internal:11434 em vez de localhost." Gray
