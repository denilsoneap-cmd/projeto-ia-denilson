# Instala/atualiza o FreeLLMAPI via Docker no Windows (PowerShell).
# Requisitos: Docker Desktop em execução.
#   Instalar Docker Desktop: winget install -e --id Docker.DockerDesktop
# Uso: powershell -ExecutionPolicy Bypass -File .\instalar.ps1
$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker não encontrado. Instale com: winget install -e --id Docker.DockerDesktop"
}
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Error "O Docker não está rodando. Abra o Docker Desktop e tente de novo."
}

if (-not (Test-Path .env)) {
    $Bytes = New-Object Byte[] 32
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($Bytes)
    $Key = -join ($Bytes | ForEach-Object { "{0:x2}" -f $_ })
    # UTF-8 sem BOM, para o Docker Compose ler a primeira linha corretamente
    [IO.File]::WriteAllText("$PSScriptRoot\.env", "ENCRYPTION_KEY=$Key`nPORT=3001`n", (New-Object Text.UTF8Encoding $false))
    Write-Host ".env criado com uma nova ENCRYPTION_KEY (guarde um backup deste arquivo)."
} else {
    Write-Host ".env já existe — mantendo a ENCRYPTION_KEY atual."
}

docker compose pull
docker compose up -d

Write-Host "Aguardando o FreeLLMAPI subir..."
for ($i = 0; $i -lt 30; $i++) {
    try {
        Invoke-WebRequest -UseBasicParsing http://localhost:3001/api/ping -TimeoutSec 2 | Out-Null
        Write-Host "FreeLLMAPI rodando: http://localhost:3001"
        Write-Host "API OpenAI-compatível: http://localhost:3001/v1"
        exit 0
    } catch { Start-Sleep -Seconds 2 }
}
Write-Warning "Não respondeu a tempo. Veja os logs: docker compose logs -f freellmapi"
