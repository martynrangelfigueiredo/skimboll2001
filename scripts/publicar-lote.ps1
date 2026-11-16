$ErrorActionPreference = "Stop"
$script = Join-Path $PSScriptRoot "youtube.ps1"
$vDir   = Join-Path $PSScriptRoot "..\videos"
$tDir   = Join-Path $PSScriptRoot "..\identidade-visual\03-thumbnails-templates"

Write-Host "=== [4/4] AGENDANDO PARA 18/11/2026 06:00: Brasil 99 1 x 0 Franca 98 ===" -ForegroundColor Cyan
& $script -Acao PostarVideo `
    -ArquivoVideo "$vDir\Ronaldinho Soccer 99 - [snes-forever.blogspot.com]-261007-172541 brasil 99 vs frança 98.mkv" `
    -Jogo "ISSD Ronaldinho Soccer" -Ano "99" `
    -Time1 "Brasil 99" -Time2 "França 98" -Gols1 1 -Gols2 0 `
    -ModoJogo "Clássico Mundial" `
    -ArquivoThumb "$tDir\thumb-v4-brasil99-x-franca98.png" `
    -DataPublicacao "2026-11-18T06:00:00-03:00"

Write-Host "`n=== AGENDA COMPLETA ATUALIZADA ===" -ForegroundColor Green
& $script -Acao ListarAgenda
