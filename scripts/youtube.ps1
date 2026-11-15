<#
.SYNOPSIS
    Publicador Otimizado de Partidas (SEO + Thumbnail Automatica + Extracao de Placar + DPAPI) - Canal Skimboll2001
    - Extrai frames dos ultimos segundos do video via ffmpeg para leitura automatica do placar final
    - Gera sempre uma Thumbnail 1280x720 em PNG no padrao Vermelho & Amarelo Ouro (China/URSS + ISS Deluxe)
    - Coloca a Partida (Time 1 x Time 2) e o Resultado no Titulo e na Descricao
    - Foco total em SEO / Palavras-chave (sem blablabla) + Pedido de Inscricao + Hashtags da partida
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Login", "Status", "ExtrairFrames", "PostarVideo", "AtualizarVideo", "GerarThumb")]
    [string]$Acao,

    [string]$ArquivoVideo,
    [string]$VideoId,
    [Parameter(Mandatory = $false)]
    [string]$Time1 = "Time 1",
    [Parameter(Mandatory = $false)]
    [string]$Time2 = "Time 2",
    [int]$Gols1 = 0,
    [int]$Gols2 = 0,
    [string]$ModoJogo = "Partida Completa",
    [string]$VersaoRom = "International Superstar Soccer Deluxe (USA)",
    [string]$Privacidade = "public",
    [string]$ArquivoThumb,
    [string]$ImagemFundoThumb
)

$ErrorActionPreference = "Stop"
$VaultPath = Join-Path $PSScriptRoot "..\.secrets\youtube-vault.dpapi.xml"
$VideosDir = Join-Path $PSScriptRoot "..\videos"

function Resolve-TargetVideo([string]$InputPath) {
    if ($InputPath -and (Test-Path $InputPath)) {
        return (Get-Item (Resolve-Path $InputPath))
    }
    $Latest = Get-ChildItem -Path "$VideosDir\*", (Join-Path $PSScriptRoot "..\*") -Include "*.mkv", "*.mp4" -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if (-not $Latest) {
        throw "Nenhum arquivo de video (.mkv ou .mp4) encontrado na pasta 'videos/' ou na raiz."
    }
    return $Latest
}

function Find-Ffmpeg {
    $cmd = Get-Command "ffmpeg" -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $wingetPath = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter "ffmpeg.exe" -Recurse -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty FullName -First 1
    if ($wingetPath) { return $wingetPath }
    throw "ffmpeg nao encontrado. Instale com: winget install Gyan.FFmpeg"
}

function ConvertFrom-SecureToPlain([System.Security.SecureString]$Secure) {
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Remove-Accents([string]$Text) {
    if (-not $Text) { return "" }
    $norm = $Text.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($c in $norm.ToCharArray()) {
        if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($c)
        }
    }
    return ($sb.ToString() -replace "[^a-zA-Z0-9]", "")
}

# Mapa de craques classicos e termos em ingles de cada selecao do ISS Deluxe para turbinar o SEO
$IssdTeamKeywords = @{
    "Brasil"     = "Brazil, Allejo, Gomez, Beranco, Pardilla, Ferreira, Cicero, Roca, Santos, Silva"
    "Alemanha"   = "Germany, Kolle, Sieke, Bergmann, Strauss, Becker, Muller, Stein"
    "Japao"      = "Japan, Fujimoto, Paz, Takeda, Moriyama, Sato, Kojima, Blue Samurai"
    "Italia"     = "Italy, Galfano, Carboni, Premoli, Pagani, Rossi, Conti, Azzurra"
    "Argentina"  = "Argentina, Capitale, Redonda, Fuerte, Ayala, Galvez, Albiceleste"
    "Inglaterra" = "England, Milner, Wright, Bruce, Clarke, Baker"
    "Holanda"    = "Netherlands, Holland, Van Wijk, Rijkaard, De Vries, Koppers"
    "Franca"     = "France, Dubois, Moreau, Girard, Blanc, Laurent"
    "Espanha"    = "Spain, Quinteros, Aguilera, Romano, Montoya"
    "URSS"       = "USSR, Russia, Uniao Sovietica, Korneev, Ivanov, Petrov"
    "Russia"     = "Russia, USSR, Uniao Sovietica, Korneev, Ivanov, Petrov"
    "Colombia"   = "Colombia, Murillo, Valderrama, Alvarez, Zapata"
    "Uruguai"    = "Uruguay, Sosa, Morales, Silva, Celeste"
    "Mexico"     = "Mexico, Negrete, Santana, Flores"
    "EUA"        = "USA, Estados Unidos, Lalas, Jones, Ramos"
    "Nigeria"    = "Nigeria, Babangida, Okocha, Amokachi"
    "Camaroes"   = "Cameroon, Milla, Omam, Song"
}

function Build-MatchSeoData {
    param(
        [string]$T1, [string]$T2, [int]$G1, [int]$G2, [string]$Modo, [string]$Rom
    )

    $Titulo = "$T1 $G1 x $G2 $T2 | International Superstar Soccer Deluxe (SNES) | skimboll2001"
    if ($Titulo.Length -gt 100) {
        $Titulo = "$T1 $G1 x $G2 $T2 | ISS Deluxe (SNES) | skimboll2001"
    }

    $TagT1 = Remove-Accents $T1
    $TagT2 = Remove-Accents $T2
    $HashtagsPartida = "#${TagT1}x${TagT2} #$TagT1 #$TagT2 #ISSDeluxe #SNES #InternationalSuperstarSoccerDeluxe #skimboll2001 #FutebolRetro #SuperNintendo #16Bit #Konami"

    $ExtrasT1 = $IssdTeamKeywords[$TagT1]
    $ExtrasT2 = $IssdTeamKeywords[$TagT2]
    $ExtrasLine = (@($ExtrasT1, $ExtrasT2) | Where-Object { $_ }) -join ", "
    if (-not $ExtrasLine) {
        $ExtrasLine = "Allejo, Gomez, Beranco, Galfano, Carboni, Kolle, Capitale, Redonda, Van Wijk, Paz"
    }

    $Star = [char]0x2605
    $LineSep = ([string][char]0x2501) * 34

    $LinhasDesc = @(
        "PARTIDA: $T1 vs $T2 | RESULTADO FINAL: $T1 $G1 x $G2 $T2",
        "INSCREVA-SE NO CANAL SKIMBOLL2001: https://www.youtube.com/@skimboll2001?sub_confirmation=1",
        "Deixe o Like e inscreva-se para acompanhar todas as partidas de International Superstar Soccer Deluxe (SNES)!",
        "",
        $LineSep,
        "$Star FICHA DA PARTIDA & RESULTADO $Star",
        $LineSep,
        "- Confronto: $T1 x $T2",
        "- Placar Final: $T1 $G1 x $G2 $T2",
        "- Jogo / ROM: $Rom",
        "- Console: Super Nintendo (SNES / Super Famicom - 16-Bit)",
        "- Modo: $Modo",
        "- Canal: Skimboll2001",
        "",
        $LineSep,
        "$Star INSCREVA-SE NO CANAL $Star",
        $LineSep,
        "Inscreva-se aqui: https://www.youtube.com/channel/UCR1UuLEs-n55oz85e7Lc5gg?sub_confirmation=1",
        "Gameplays diretos e sem enrolacao de International Superstar Soccer Deluxe (SNES) e suas variacoes classicas (Ronaldinho Soccer 97, Campeonato Brasileiro 96, Forte e Campeao, World Cup e hacks).",
        "",
        $LineSep,
        "$Star PALAVRAS-CHAVE E TERMOS DE BUSCA (SEO) $Star",
        $LineSep,
        "$T1 x $T2, $T1 vs $T2, $T1 $G1 x $G2 $T2, $T1 $G1 a $G2 $T2, $T1 ISS Deluxe, $T2 ISS Deluxe, $T1 International Superstar Soccer Deluxe, $T2 International Superstar Soccer Deluxe, International Superstar Soccer Deluxe SNES, ISS Deluxe SNES, ISSD SNES, Super Nintendo Futebol, Konami 1995, Futebol 16-bit, Retro Gaming, Gameplay SNES 60fps, $ExtrasLine, Campeonato Brasileiro 96 SNES, Ronaldinho Soccer SNES, Skimboll2001, skimboll 2001.",
        "",
        $HashtagsPartida
    )
    $Descricao = $LinhasDesc -join "`r`n"

    $Tags = @(
        "$T1 x $T2",
        "$T1 vs $T2",
        "$T1 $G1 x $G2 $T2",
        "$T1 ISS Deluxe",
        "$T2 ISS Deluxe",
        "International Superstar Soccer Deluxe",
        "ISS Deluxe",
        "ISSD",
        "SNES",
        "Super Nintendo",
        "skimboll2001",
        "Futebol Retro",
        "Konami",
        "16-bit",
        "Gameplay SNES"
    )

    return @{
        Titulo    = $Titulo
        Descricao = $Descricao
        Tags      = $Tags
    }
}

function Get-FittedFont {
    param(
        [System.Drawing.Graphics]$Gfx,
        [string]$Text,
        [string]$FontFamily,
        [float]$MaxSize,
        [float]$MinSize,
        [float]$MaxWidth
    )
    for ($sz = $MaxSize; $sz -ge $MinSize; $sz -= 2) {
        $f = New-Object System.Drawing.Font($FontFamily, $sz, [System.Drawing.FontStyle]::Bold)
        $measured = $Gfx.MeasureString($Text, $f)
        if ($measured.Width -le $MaxWidth) {
            return $f
        }
        $f.Dispose()
    }
    return (New-Object System.Drawing.Font($FontFamily, $MinSize, [System.Drawing.FontStyle]::Bold))
}

function New-MatchThumbnail {
    param(
        [string]$T1, [string]$T2, [int]$G1, [int]$G2, [string]$Modo, [string]$OutPath, [string]$BgImagePath
    )

    Add-Type -AssemblyName System.Drawing
    $Bmp = New-Object System.Drawing.Bitmap(1280, 720)
    $Gfx = [System.Drawing.Graphics]::FromImage($Bmp)
    $Gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $Gfx.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    $ColorRedDark   = [System.Drawing.Color]::FromArgb(255, 106, 11, 11)   # #6A0B0B
    $ColorRedMain   = [System.Drawing.Color]::FromArgb(255, 183, 28, 28)   # #B71C1C
    $ColorGold      = [System.Drawing.Color]::FromArgb(255, 255, 214, 0)   # #FFD600
    $ColorAmber     = [System.Drawing.Color]::FromArgb(255, 255, 171, 0)   # #FFAB00
    $ColorWhite     = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)

    if ($BgImagePath -and (Test-Path $BgImagePath)) {
        $BgImg = [System.Drawing.Image]::FromFile((Resolve-Path $BgImagePath).Path)
        $Gfx.DrawImage($BgImg, 0, 0, 1280, 720)
        $BgImg.Dispose()
        $OverlayBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(145, 106, 11, 11))
        $Gfx.FillRectangle($OverlayBrush, 0, 0, 1280, 720)
    } else {
        $GradBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            (New-Object System.Drawing.Point(0, 0)),
            (New-Object System.Drawing.Point(1280, 720)),
            $ColorRedDark,
            $ColorRedMain
        )
        $Gfx.FillRectangle($GradBrush, 0, 0, 1280, 720)

        $PitchPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(65, 255, 214, 0), 5)
        $Gfx.DrawRectangle($PitchPen, 70, 50, 1140, 620)
        $Gfx.DrawLine($PitchPen, 640, 50, 640, 670)
        $Gfx.DrawEllipse($PitchPen, 490, 210, 300, 300)
    }

    $PenRedOuter = New-Object System.Drawing.Pen($ColorRedMain, 16)
    $PenGoldOuter = New-Object System.Drawing.Pen($ColorGold, 6)
    $Gfx.DrawRectangle($PenRedOuter, 8, 8, 1264, 704)
    $Gfx.DrawRectangle($PenGoldOuter, 18, 18, 1244, 684)

    $BrushBoxDark = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(242, 106, 11, 11))
    $BrushRedMain = New-Object System.Drawing.SolidBrush($ColorRedMain)
    $BrushGold    = New-Object System.Drawing.SolidBrush($ColorGold)
    $BrushWhite   = New-Object System.Drawing.SolidBrush($ColorWhite)
    $PenGoldBox   = New-Object System.Drawing.Pen($ColorGold, 5)
    $PenAmberThin = New-Object System.Drawing.Pen($ColorAmber, 2)

    $FormatCenter = New-Object System.Drawing.StringFormat
    $FormatCenter.Alignment = [System.Drawing.StringAlignment]::Center
    $FormatCenter.LineAlignment = [System.Drawing.StringAlignment]::Center
    $FormatCenter.FormatFlags = [System.Drawing.StringFormatFlags]::NoWrap

    $Star = [char]0x2605
    $Dot  = [char]0x2022

    # Topo Esquerdo: Selo do Jogo
    $Gfx.FillRectangle($BrushRedMain, 42, 42, 440, 68)
    $Gfx.DrawRectangle($PenGoldBox, 42, 42, 440, 68)
    $FontBadge = New-Object System.Drawing.Font("Consolas", 23, [System.Drawing.FontStyle]::Bold)
    $Gfx.DrawString("$Star ISS DELUXE $Dot SNES $Star", $FontBadge, $BrushGold, (New-Object System.Drawing.RectangleF(42, 42, 440, 68)), $FormatCenter)

    # Topo Direito: Assinatura SKIMBOLL2001
    $Gfx.FillRectangle($BrushBoxDark, 900, 42, 338, 68)
    $Gfx.DrawRectangle($PenGoldBox, 900, 42, 338, 68)
    $FontBrand = New-Object System.Drawing.Font("Arial Black", 22, [System.Drawing.FontStyle]::Bold)
    $Gfx.DrawString("SKIMBOLL2001", $FontBrand, $BrushGold, (New-Object System.Drawing.RectangleF(900, 42, 338, 68)), $FormatCenter)

    # Painel Central Estilo Placar Konami ISS Deluxe
    $Gfx.FillRectangle($BrushBoxDark, 54, 155, 1172, 355)
    $Gfx.DrawRectangle($PenGoldBox, 54, 155, 1172, 355)
    $Gfx.DrawRectangle($PenAmberThin, 64, 165, 1152, 335)

    $T1Upper = $T1.ToUpper()
    $T2Upper = $T2.ToUpper()

    $FontT1 = Get-FittedFont -Gfx $Gfx -Text $T1Upper -FontFamily "Arial Black" -MaxSize 48 -MinSize 24 -MaxWidth 395
    $Gfx.DrawString($T1Upper, $FontT1, $BrushWhite, (New-Object System.Drawing.RectangleF(75, 195, 410, 150)), $FormatCenter)

    $Gfx.FillRectangle($BrushRedMain, 500, 200, 280, 140)
    $Gfx.DrawRectangle($PenGoldBox, 500, 200, 280, 140)
    $ScoreText = "$G1 x $G2"
    $FontScore = Get-FittedFont -Gfx $Gfx -Text $ScoreText -FontFamily "Consolas" -MaxSize 56 -MinSize 32 -MaxWidth 260
    $Gfx.DrawString($ScoreText, $FontScore, $BrushGold, (New-Object System.Drawing.RectangleF(500, 200, 280, 140)), $FormatCenter)

    $FontT2 = Get-FittedFont -Gfx $Gfx -Text $T2Upper -FontFamily "Arial Black" -MaxSize 48 -MinSize 24 -MaxWidth 395
    $Gfx.DrawString($T2Upper, $FontT2, $BrushWhite, (New-Object System.Drawing.RectangleF(795, 195, 410, 150)), $FormatCenter)

    $Gfx.FillRectangle($BrushGold, 110, 385, 1060, 82)
    $VsText = "$T1Upper  vs  $T2Upper"
    $FontSub = Get-FittedFont -Gfx $Gfx -Text $VsText -FontFamily "Arial Black" -MaxSize 34 -MinSize 20 -MaxWidth 1020
    $BrushDarkText = New-Object System.Drawing.SolidBrush($ColorRedDark)
    $Gfx.DrawString($VsText, $FontSub, $BrushDarkText, (New-Object System.Drawing.RectangleF(110, 385, 1060, 82)), $FormatCenter)

    $Gfx.FillRectangle($BrushRedMain, 54, 545, 1172, 115)
    $Gfx.DrawRectangle($PenGoldBox, 54, 545, 1172, 115)
    $Gfx.FillRectangle($BrushGold, 54, 545, 24, 115)

    $FooterText = "INTERNATIONAL SUPERSTAR SOCCER DELUXE"
    $FontFooter = Get-FittedFont -Gfx $Gfx -Text $FooterText -FontFamily "Arial Black" -MaxSize 32 -MinSize 20 -MaxWidth 1100
    $Gfx.DrawString($FooterText, $FontFooter, $BrushGold, (New-Object System.Drawing.RectangleF(85, 545, 1125, 115)), $FormatCenter)

    $Bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $Gfx.Dispose()
    $Bmp.Dispose()
}

switch ($Acao) {
    "ExtrairFrames" {
        $VideoFile = Resolve-TargetVideo $ArquivoVideo
        $FfmpegExe = Find-Ffmpeg
        $FramesDir = Join-Path $PSScriptRoot "..\.secrets\frames"
        New-Item -ItemType Directory -Force -Path $FramesDir | Out-Null
        Get-ChildItem $FramesDir -File -ErrorAction SilentlyContinue | Remove-Item -Force

        Write-Host "Extraindo frames finais de '$($VideoFile.Name)' com ffmpeg..." -ForegroundColor Cyan
        foreach ($offset in @(25, 15, 10, 6, 3, 1)) {
            $outImg = Join-Path $FramesDir "final_menos_${offset}s.png"
            & $FfmpegExe -y -loglevel error -sseof "-$offset" -i $VideoFile.FullName -frames:v 1 $outImg
        }
        $meioImg = Join-Path $FramesDir "lance_partida.png"
        & $FfmpegExe -y -loglevel error -ss 300 -i $VideoFile.FullName -frames:v 1 $meioImg

        Write-Host "Frames extraidos em: $FramesDir" -ForegroundColor Green
        Get-ChildItem $FramesDir | Select-Object Name, Length
        return
    }

    "GerarThumb" {
        if (-not $ArquivoThumb) {
            $ArquivoThumb = Join-Path $PSScriptRoot "..\identidade-visual\03-thumbnails-templates\thumb-ultima-partida.png"
        }
        New-MatchThumbnail -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -OutPath $ArquivoThumb -BgImagePath $ImagemFundoThumb
        $Seo = Build-MatchSeoData -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -Rom $VersaoRom
        $DescPath = Join-Path $PSScriptRoot "..\descricao-video.txt"
        [System.IO.File]::WriteAllText($DescPath, $Seo.Descricao, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "Thumbnail gerada em: $ArquivoThumb" -ForegroundColor Green
        Write-Host "Titulo SEO: $($Seo.Titulo)" -ForegroundColor Cyan
        return
    }
}

if (-not (Test-Path $VaultPath)) {
    throw "Cofre DPAPI nao encontrado em: $VaultPath"
}

$Vault = Import-Clixml -Path $VaultPath
$ClientId = $Vault.ClientId
$ClientSecret = ConvertFrom-SecureToPlain $Vault.ClientSecret

function Get-AccessToken {
    if (-not $Vault.RefreshToken) {
        throw "RefreshToken nao encontrado."
    }
    $RefreshToken = ConvertFrom-SecureToPlain $Vault.RefreshToken
    $body = @{
        client_id     = $ClientId
        client_secret = $ClientSecret
        refresh_token = $RefreshToken
        grant_type    = "refresh_token"
    }
    $resp = Invoke-RestMethod -Method Post -Uri "https://oauth2.googleapis.com/token" -Body $body
    return $resp.access_token
}

function Invoke-OAuthLogin {
    $RedirectUri = "http://localhost:8085/"
    $Scopes = "https://www.googleapis.com/auth/youtube.upload https://www.googleapis.com/auth/youtube"
    $AuthUrl = "https://accounts.google.com/o/oauth2/v2/auth?client_id=$ClientId&redirect_uri=$([uri]::EscapeDataString($RedirectUri))&response_type=code&scope=$([uri]::EscapeDataString($Scopes))&access_type=offline&prompt=select_account%20consent"

    $Listener = [System.Net.HttpListener]::new()
    $Listener.Prefixes.Add($RedirectUri)
    $Listener.Start()

    Write-Host "Aguardando autorizacao no navegador em: $AuthUrl" -ForegroundColor Yellow
    Start-Process $AuthUrl

    $Context = $Listener.GetContext()
    $Code = $Context.Request.QueryString["code"]

    $Html = [System.Text.Encoding]::UTF8.GetBytes("<html><body style='background:#6A0B0B;color:#FFD600;font-family:sans-serif;text-align:center;padding-top:80px;'><h1>SKIMBOLL2001 AUTORIZADO!</h1><p style='color:#fff;'>Pode fechar esta aba e voltar ao VS Code.</p></body></html>")
    $Context.Response.ContentLength64 = $Html.Length
    $Context.Response.OutputStream.Write($Html, 0, $Html.Length)
    $Context.Response.OutputStream.Close()
    $Listener.Stop()

    $TokenResp = Invoke-RestMethod -Method Post -Uri "https://oauth2.googleapis.com/token" -Body @{
        code          = $Code
        client_id     = $ClientId
        client_secret = $ClientSecret
        redirect_uri  = $RedirectUri
        grant_type    = "authorization_code"
    }

    $script:Vault["RefreshToken"] = ($TokenResp.refresh_token | ConvertTo-SecureString -AsPlainText -Force)
    $script:Vault | Export-Clixml -Path $VaultPath
    Write-Host "Novo RefreshToken criptografado via DPAPI!" -ForegroundColor Green
}

switch ($Acao) {
    "Login" {
        Invoke-OAuthLogin
    }

    "Status" {
        $Token = Get-AccessToken
        $Canal = Invoke-RestMethod -Uri "https://www.googleapis.com/youtube/v3/channels?part=snippet,statistics&mine=true" -Headers @{ Authorization = "Bearer $Token" }
        $Info = $Canal.items[0]
        Write-Host "Canal conectado: $($Info.snippet.title) (ID: $($Info.id))" -ForegroundColor Cyan
        Write-Host "Inscritos: $($Info.statistics.subscriberCount) | Videos: $($Info.statistics.videoCount)" -ForegroundColor Yellow
    }

    "AtualizarVideo" {
        if (-not $VideoId) { throw "Informe -VideoId para atualizar." }
        $Token = Get-AccessToken
        $Seo = Build-MatchSeoData -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -Rom $VersaoRom

        $DescPath = Join-Path $PSScriptRoot "..\descricao-video.txt"
        [System.IO.File]::WriteAllText($DescPath, $Seo.Descricao, (New-Object System.Text.UTF8Encoding($false)))

        $UpdateObj = @{
            id      = $VideoId
            snippet = @{
                title                = $Seo.Titulo
                description          = $Seo.Descricao
                tags                 = $Seo.Tags
                categoryId           = "20"
                defaultLanguage      = "pt-BR"
                defaultAudioLanguage = "pt-BR"
            }
        }
        $UpdateJson = $UpdateObj | ConvertTo-Json -Depth 6 -Compress
        $TempUpdateFile = Join-Path $PSScriptRoot "..\.secrets\temp-update.json"
        [System.IO.File]::WriteAllText($TempUpdateFile, $UpdateJson, (New-Object System.Text.UTF8Encoding($false)))

        Write-Host "Atualizando titulo, descricao SEO e tags do video $VideoId..." -ForegroundColor Cyan
        $UpdateResultFile = Join-Path $PSScriptRoot "..\.secrets\temp-update-res.json"
        & curl.exe -s -S -X PUT "https://www.googleapis.com/youtube/v3/videos?part=snippet" `
            -H "Authorization: Bearer $Token" `
            -H "Content-Type: application/json; charset=UTF-8" `
            --data-binary "@$TempUpdateFile" `
            -o $UpdateResultFile
        Remove-Item $TempUpdateFile, $UpdateResultFile -Force -ErrorAction SilentlyContinue

        if (-not $ArquivoThumb -or -not (Test-Path $ArquivoThumb)) {
            $ArquivoThumb = Join-Path $PSScriptRoot "..\identidade-visual\03-thumbnails-templates\thumb-ultima-partida.png"
            Write-Host "Gerando thumbnail 1280x720 da partida ($Time1 $Gols1 x $Gols2 $Time2)..." -ForegroundColor Yellow
            New-MatchThumbnail -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -OutPath $ArquivoThumb -BgImagePath $ImagemFundoThumb
        }

        Write-Host "Aplicando thumbnail no video $VideoId..." -ForegroundColor Cyan
        $ThumbResFile = Join-Path $PSScriptRoot "..\.secrets\temp-thumb-res.json"
        & curl.exe -s -S -X POST "https://www.googleapis.com/upload/youtube/v3/thumbnails/set?videoId=$VideoId&uploadType=media" `
            -H "Authorization: Bearer $Token" `
            -H "Content-Type: image/png" `
            --data-binary "@$((Resolve-Path $ArquivoThumb).Path)" `
            -o $ThumbResFile
        $ThumbResRaw = Get-Content $ThumbResFile -Raw -ErrorAction SilentlyContinue
        Remove-Item $ThumbResFile -Force -ErrorAction SilentlyContinue
        if ($ThumbResRaw -match '"error"') {
            Write-Warning "Aviso da API de Thumbnail do YouTube: $ThumbResRaw"
        } else {
            Write-Host "Thumbnail aplicada com sucesso!" -ForegroundColor Green
        }

        Write-Host "Video atualizado: https://youtu.be/$VideoId" -ForegroundColor Green
    }

    "PostarVideo" {
        $VideoFile = Resolve-TargetVideo $ArquivoVideo

        $Token = Get-AccessToken
        $Canal = Invoke-RestMethod -Uri "https://www.googleapis.com/youtube/v3/channels?part=snippet&mine=true" -Headers @{ Authorization = "Bearer $Token" }
        Write-Host "Publicando no canal: $($Canal.items[0].snippet.title) ($($Canal.items[0].id))" -ForegroundColor Cyan

        $Seo = Build-MatchSeoData -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -Rom $VersaoRom

        $DescPath = Join-Path $PSScriptRoot "..\descricao-video.txt"
        [System.IO.File]::WriteAllText($DescPath, $Seo.Descricao, (New-Object System.Text.UTF8Encoding($false)))

        $MetadataObj = @{
            snippet = @{
                title                = $Seo.Titulo
                description          = $Seo.Descricao
                tags                 = $Seo.Tags
                categoryId           = "20"
                defaultLanguage      = "pt-BR"
                defaultAudioLanguage = "pt-BR"
            }
            status  = @{
                privacyStatus           = $Privacidade
                selfDeclaredMadeForKids = $false
            }
        }

        $MetadataJson = $MetadataObj | ConvertTo-Json -Depth 6 -Compress
        $TempMetaFile = Join-Path $PSScriptRoot "..\.secrets\temp-metadata.json"
        [System.IO.File]::WriteAllText($TempMetaFile, $MetadataJson, (New-Object System.Text.UTF8Encoding($false)))

        Write-Host "1/3 Iniciando sessao de upload resumivel no YouTube..." -ForegroundColor Cyan
        $HeadersFile = Join-Path $PSScriptRoot "..\.secrets\temp-headers.txt"
        $InitBodyFile = Join-Path $PSScriptRoot "..\.secrets\temp-init-body.txt"

        & curl.exe -s -S -D $HeadersFile -o $InitBodyFile -X POST `
            "https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status" `
            -H "Authorization: Bearer $Token" `
            -H "Content-Type: application/json; charset=UTF-8" `
            -H "X-Upload-Content-Length: $($VideoFile.Length)" `
            -H "X-Upload-Content-Type: video/x-matroska" `
            --data-binary "@$TempMetaFile"

        Remove-Item $TempMetaFile -Force -ErrorAction SilentlyContinue

        $HeadersLines = Get-Content $HeadersFile
        $LocationLine = $HeadersLines | Where-Object { $_ -match "^(?i)Location:\s*(.+)$" } | Select-Object -Last 1
        if (-not $LocationLine) {
            $ErrBody = Get-Content $InitBodyFile -Raw -ErrorAction SilentlyContinue
            throw "Falha ao obter URL de upload. Resposta: $ErrBody"
        }
        $UploadUrl = ($LocationLine -replace "^(?i)Location:\s*", "").Trim()
        Remove-Item $HeadersFile, $InitBodyFile -Force -ErrorAction SilentlyContinue

        $SizeMB = [math]::Round($VideoFile.Length / 1MB, 2)
        Write-Host "2/3 Enviando video '$($VideoFile.Name)' ($SizeMB MB) via curl.exe streaming..." -ForegroundColor Yellow

        $ResultFile = Join-Path $PSScriptRoot "..\.secrets\temp-result.json"
        & curl.exe -s -S -X PUT $UploadUrl `
            -H "Authorization: Bearer $Token" `
            -H "Content-Type: video/x-matroska" `
            -T $VideoFile.FullName `
            -o $ResultFile

        $ResultRaw = [System.IO.File]::ReadAllText($ResultFile, [System.Text.Encoding]::UTF8)
        Remove-Item $ResultFile -Force -ErrorAction SilentlyContinue

        $VideoResp = $ResultRaw | ConvertFrom-Json
        if (-not $VideoResp.id) {
            throw "Erro no upload do video: $ResultRaw"
        }

        if (-not $ArquivoThumb -or -not (Test-Path $ArquivoThumb)) {
            $ArquivoThumb = Join-Path $PSScriptRoot "..\identidade-visual\03-thumbnails-templates\thumb-ultima-partida.png"
            Write-Host "3/3 Gerando thumbnail automatica ($Time1 $Gols1 x $Gols2 $Time2)..." -ForegroundColor Yellow
            New-MatchThumbnail -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -OutPath $ArquivoThumb -BgImagePath $ImagemFundoThumb
        }

        Write-Host "Aplicando thumbnail no video $($VideoResp.id)..." -ForegroundColor Cyan
        $ThumbResFile = Join-Path $PSScriptRoot "..\.secrets\temp-thumb-res.json"
        & curl.exe -s -S -X POST "https://www.googleapis.com/upload/youtube/v3/thumbnails/set?videoId=$($VideoResp.id)&uploadType=media" `
            -H "Authorization: Bearer $Token" `
            -H "Content-Type: image/png" `
            --data-binary "@$((Resolve-Path $ArquivoThumb).Path)" `
            -o $ThumbResFile
        $ThumbResRaw = Get-Content $ThumbResFile -Raw -ErrorAction SilentlyContinue
        Remove-Item $ThumbResFile -Force -ErrorAction SilentlyContinue

        Write-Host "======================================================" -ForegroundColor Green
        Write-Host "VIDEO PUBLICADO COM SUCESSO!" -ForegroundColor Green
        Write-Host "Canal    : $($Canal.items[0].snippet.title)" -ForegroundColor Cyan
        Write-Host "Partida  : $Time1 $Gols1 x $Gols2 $Time2" -ForegroundColor Yellow
        Write-Host "ID       : $($VideoResp.id)" -ForegroundColor White
        Write-Host "Link     : https://youtu.be/$($VideoResp.id)" -ForegroundColor Cyan
        Write-Host "Studio   : https://studio.youtube.com/video/$($VideoResp.id)/edit" -ForegroundColor Yellow
        Write-Host "======================================================" -ForegroundColor Green
    }
}
