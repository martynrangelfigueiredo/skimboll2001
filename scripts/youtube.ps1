<#
.SYNOPSIS
    Publicador Oficial Multi-Jogos & ROMHACKs - Canal Skimboll2001
    - PROIBIDO referenciar "Nintendo", "Super Nintendo", "SNES", "Super Famicom" ou "Konami"
    - Suporta automaticamente todo o catalogo de ISSD + ROMHACKs (Gauchao, Deutscher Fussball,
      Champions League, Mundial de Clubes, Campeonato Brasileiro 95-99, Futebol Brasileiro 95-99,
      Ronaldinho Soccer, ISSD Extended / Brasil Popular) alem de eFootball, EAFC e FIFA.
    - Usa imagens reais da partida (lance em campo + placar final dos ultimos segundos) + Logo Oficial SKIMBOLL (20 ▽S 01)
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Login", "Status", "ExtrairFrames", "PostarVideo", "AtualizarVideo", "GerarThumb", "GerarModelosJogos")]
    [string]$Acao,

    [string]$Jogo = "Auto",
    [string]$Ano = "",

    [string]$ArquivoVideo,
    [string]$VideoId,
    [Parameter(Mandatory = $false)]
    [string]$Time1 = "Alemanha",
    [Parameter(Mandatory = $false)]
    [string]$Time2 = "Japão",
    [int]$Gols1 = 3,
    [int]$Gols2 = 0,
    [string]$ModoJogo = "International Cup Deluxe",
    [string]$VersaoRom = "",
    [string]$Privacidade = "public",
    [string]$ArquivoThumb,
    [string]$ImagemLance,
    [string]$ImagemPlacar
)

$ErrorActionPreference = "Stop"
$VaultPath  = Join-Path $PSScriptRoot "..\.secrets\youtube-vault.dpapi.xml"
$VideosDir  = Join-Path $PSScriptRoot "..\videos"
$FramesDir  = Join-Path $PSScriptRoot "..\.secrets\frames"
$LogoPath   = Join-Path $PSScriptRoot "..\identidade-visual\01-logos-e-avatar\logo-oficial-skimboll2001.png"
$ThumbsDir  = Join-Path $PSScriptRoot "..\identidade-visual\03-thumbnails-templates"

# Funcao que resolve o perfil exato do jogo ou ROMHACK (SEM mencionar Nintendo/SNES/Konami)
function Get-GameProfile {
    param([string]$InputJogo, [string]$InputAno, [string]$InputRom, [string]$VideoFileName)

    $Combined = "$InputJogo $InputRom $VideoFileName".Trim()
    $AnoFinal = $InputAno
    if (-not $AnoFinal -and $Combined -match "\b(199[5-9]|20[0-2][0-9]|9[5-9])\b") {
        $AnoFinal = $Matches[1]
    }
    $SufixoAno = if ($AnoFinal) { " $AnoFinal" } else { "" }

    # 1. eFootball
    if ($InputJogo -eq "eFootball" -or $Combined -match "(?i)\befootball\b") {
        return @{
            Key            = "eFootball"
            NomeCurto      = "eFOOTBALL$SufixoAno"
            NomeCompleto   = "eFootball$SufixoAno"
            SubtituloThumb = "eFOOTBALL • MATCHPLAY & TOURNAMENTS"
            CorBadge       = @(0, 56, 168)
            CorDestaque    = @(244, 230, 0)
            PixelArt       = $false
            SeoKeywords    = "eFootball, eFootball Gameplay, Dream Team, Partida Completa eFootball, Futebol Virtual, eFootball Torneio, Skimboll2001"
            HashtagsBase   = "#eFootball #eFootballGameplay #skimboll2001 #FutebolVirtual #DreamTeam"
            TagsBase       = @("eFootball", "eFootball Gameplay", "Dream Team", "skimboll2001", "Futebol Virtual")
        }
    }

    # 2. EAFC
    if ($InputJogo -eq "EAFC" -or $Combined -match "(?i)\beafc\b|ea\s*sports\s*fc|\bfc\s*2[456]\b") {
        return @{
            Key            = "EAFC"
            NomeCurto      = "EA SPORTS FC$SufixoAno"
            NomeCompleto   = "EA Sports FC$SufixoAno"
            SubtituloThumb = "EA SPORTS FC • MATCHPLAY & TOURNAMENTS"
            CorBadge       = @(18, 22, 28)
            CorDestaque    = @(0, 255, 135)
            PixelArt       = $false
            SeoKeywords    = "EA Sports FC, EAFC, EA FC 25, EA FC 26, EA FC 24, EA Sports FC Gameplay, Ultimate Team, Career Mode, Champions League, Partida Completa EAFC, Skimboll2001"
            HashtagsBase   = "#EASportsFC #EAFC #UltimateTeam #skimboll2001 #FutebolVirtual #GameplayEAFC"
            TagsBase       = @("EA Sports FC", "EAFC", "EA FC", "EA Sports FC Gameplay", "Ultimate Team", "skimboll2001", "Futebol")
        }
    }

    # 3. FIFA
    if ($InputJogo -eq "FIFA" -or $Combined -match "(?i)\bfifa\b") {
        return @{
            Key            = "FIFA"
            NomeCurto      = "FIFA$SufixoAno"
            NomeCompleto   = "FIFA$SufixoAno"
            SubtituloThumb = "FIFA • CLASSIC & MODERN TOURNAMENTS"
            CorBadge       = @(18, 42, 94)
            CorDestaque    = @(244, 230, 0)
            PixelArt       = $false
            SeoKeywords    = "FIFA, FIFA Gameplay, FIFA World Cup, FIFA Classic, Partida Completa FIFA, Torneio FIFA, Futebol Gameplay, Skimboll2001"
            HashtagsBase   = "#FIFA #FIFAGameplay #WorldCup #skimboll2001 #FutebolVirtual"
            TagsBase       = @("FIFA", "FIFA Gameplay", "FIFA World Cup", "skimboll2001", "Futebol")
        }
    }

    # 4. Variacoes e ROMHACKs de ISSD (International Superstar Soccer Deluxe)
    $NomeCurto    = "ISS DELUXE • 16-BIT"
    $NomeCompleto = "International Superstar Soccer Deluxe"
    $SubThumb     = "INTERNATIONAL CUP DELUXE • 16-BIT"
    $ExtraSeo     = "International Superstar Soccer Deluxe, ISS Deluxe, ISSD, ninjaissd, angelo salles, international cup deluxe tournaments, Futebol 16-bit, Retro Gaming"
    $ExtraHash    = "#ISSDeluxe #ISSD #InternationalSuperstarSoccerDeluxe #ninjaissd #InternationalCupDeluxe #skimboll2001 #FutebolRetro #16Bit"
    $ExtraTags    = @("International Superstar Soccer Deluxe", "ISS Deluxe", "ISSD", "ninjaissd", "angelo salles", "international cup deluxe", "skimboll2001", "Futebol Retro", "16-bit")

    if ($Combined -match "(?i)gauch[aã]o|charmoso") {
        $NomeCurto    = "ISSD CHARMOSO GAUCHAO$SufixoAno"
        $NomeCompleto = "ISSD Charmoso Gauchão$SufixoAno"
        $SubThumb     = "CAMPEONATO GAUCHO ROMHACK$SufixoAno • ISSD"
        $ExtraSeo    += ", ISSD Charmoso Gaucho, Campeonato Gaucho ISSD, Gauchao ROMHACK, Gremio, Internacional, Juventude, Caxias, Pelotas, Brasil de Pelotas"
        $ExtraHash   += " #CampeonatoGaucho #Gauchao #CharmosoGauchao #ROMHACK"
        $ExtraTags   += @("ISSD Charmoso Gaucho", "Campeonato Gaucho ISSD", "Gauchao ROMHACK")
    }
    elseif ($Combined -match "(?i)deutscher|fussball|alem[aã]o|bundesliga") {
        $NomeCurto    = "ISSD DEUTSCHER FUSSBALL$SufixoAno"
        $NomeCompleto = "ISSD Deutscher Fussball$SufixoAno"
        $SubThumb     = "DEUTSCHER FUSSBALL ROMHACK$SufixoAno • ISSD"
        $ExtraSeo    += ", ISSD Deutscher Fussball, Campeonato Alemao ISSD, Bundesliga ISSD, Deutscher Fussball ROMHACK"
        $ExtraHash   += " #DeutscherFussball #Bundesliga #CampeonatoAlemao #ROMHACK"
        $ExtraTags   += @("ISSD Deutscher Fussball", "Bundesliga ISSD", "Campeonato Alemao ISSD")
    }
    elseif ($Combined -match "(?i)champions\s*league") {
        $NomeCurto    = "ISSD CHAMPIONS LEAGUE$SufixoAno"
        $NomeCompleto = "ISSD Champions League$SufixoAno"
        $SubThumb     = "CHAMPIONS LEAGUE ROMHACK$SufixoAno • ISSD"
        $ExtraSeo    += ", ISSD Champions League, Champions League ISSD, UEFA Champions League 16-bit, Champions League ROMHACK"
        $ExtraHash   += " #ChampionsLeague #ISSDChampionsLeague #ROMHACK"
        $ExtraTags   += @("ISSD Champions League", "Champions League ISSD", "Champions League ROMHACK")
    }
    elseif ($Combined -match "(?i)mundial\s*de\s*clubes|club\s*world\s*cup") {
        $NomeCurto    = "ISSD MUNDIAL DE CLUBES$SufixoAno"
        $NomeCompleto = "ISSD Mundial de Clubes$SufixoAno"
        $SubThumb     = "MUNDIAL DE CLUBES ROMHACK$SufixoAno • ISSD"
        $ExtraSeo    += ", ISSD Mundial de Clubes, Club World Cup Deluxe, Mundial de Clubes ISSD, Angelo Salles Mundial, ROMHACK"
        $ExtraHash   += " #MundialDeClubes #ClubWorldCupDeluxe #ISSDMundial #ROMHACK"
        $ExtraTags   += @("ISSD Mundial de Clubes", "Club World Cup Deluxe", "Mundial de Clubes ISSD")
    }
    elseif ($Combined -match "(?i)extended\s*brasil\s*popular|brasil\s*popular") {
        $NomeCurto    = "ISSD EXTENDED BRASIL$SufixoAno"
        $NomeCompleto = "ISSD Extended Brasil Popular$SufixoAno"
        $SubThumb     = "EXTENDED BRASIL POPULAR$SufixoAno • ROMHACK"
        $ExtraSeo    += ", ISSD Extended Brasil Popular, Campeonato Brasileiro ISSD Extended, Brasil Popular ROMHACK"
        $ExtraHash   += " #ISSDExtended #BrasilPopular #CampeonatoBrasileiro #ROMHACK"
        $ExtraTags   += @("ISSD Extended Brasil Popular", "ISSD Extended", "Brasil Popular ROMHACK")
    }
    elseif ($Combined -match "(?i)\bextended\b") {
        $NomeCurto    = "ISSD EXTENDED$SufixoAno"
        $NomeCompleto = "ISSD Extended$SufixoAno"
        $SubThumb     = "ISSD EXTENDED$SufixoAno • SELECOES ATUALIZADAS"
        $ExtraSeo    += ", ISSD Extended, International Superstar Soccer Deluxe Extended, ISSD Escalacoes Atualizadas, ISSD Selecoes Atualizadas"
        $ExtraHash   += " #ISSDExtended #InternationalSuperstarSoccerExtended #ROMHACK"
        $ExtraTags   += @("ISSD Extended", "ISS Deluxe Extended", "ISSD Atualizado")
    }
    elseif ($Combined -match "(?i)campeonato\s*brasileiro") {
        $NomeCurto    = "CAMPEONATO BRASILEIRO$SufixoAno"
        $NomeCompleto = "ISSD Campeonato Brasileiro$SufixoAno"
        $SubThumb     = "ISSD CAMPEONATO BRASILEIRO$SufixoAno • 16-BIT"
        $ExtraSeo    += ", ISSD Campeonato Brasileiro$SufixoAno, Campeonato Brasileiro $AnoFinal, Forte e Campeao, Futebol Brasileiro 16-bit, Brasileirao Anos 90"
        $ExtraHash   += " #CampeonatoBrasileiro #Brasileirao$AnoFinal #ForteECampeao #ROMHACK"
        $ExtraTags   += @("ISSD Campeonato Brasileiro$SufixoAno", "Campeonato Brasileiro $AnoFinal", "Forte e Campeao")
    }
    elseif ($Combined -match "(?i)futebol\s*brasileiro") {
        $NomeCurto    = "FUTEBOL BRASILEIRO$SufixoAno"
        $NomeCompleto = "ISSD Futebol Brasileiro$SufixoAno"
        $SubThumb     = "ISSD FUTEBOL BRASILEIRO$SufixoAno • 16-BIT"
        $ExtraSeo    += ", ISSD Futebol Brasileiro$SufixoAno, Futebol Brasileiro $AnoFinal, Campeonato Brasileiro ISSD, Brasileirao Anos 90"
        $ExtraHash   += " #FutebolBrasileiro #FutebolBrasileiro$AnoFinal #Brasileirao #ROMHACK"
        $ExtraTags   += @("ISSD Futebol Brasileiro$SufixoAno", "Futebol Brasileiro $AnoFinal", "Campeonato Brasileiro ISSD")
    }
    elseif ($Combined -match "(?i)ronaldinho") {
        $NomeCurto    = "RONALDINHO SOCCER$SufixoAno"
        $NomeCompleto = "ISSD Ronaldinho Soccer$SufixoAno"
        $SubThumb     = "ISSD RONALDINHO SOCCER$SufixoAno • 16-BIT"
        $ExtraSeo    += ", ISSD Ronaldinho Soccer$SufixoAno, Ronaldinho Soccer $AnoFinal, Ronaldinho Campeonato Brasileiro, Futebol 16-bit"
        $ExtraHash   += " #RonaldinhoSoccer #RonaldinhoSoccer$AnoFinal #ISSD #ROMHACK"
        $ExtraTags   += @("ISSD Ronaldinho Soccer$SufixoAno", "Ronaldinho Soccer $AnoFinal", "Ronaldinho Soccer")
    }

    return @{
        Key            = "ISSD"
        NomeCurto      = $NomeCurto
        NomeCompleto   = $NomeCompleto
        SubtituloThumb = $SubThumb
        CorBadge       = @(210, 29, 29)
        CorDestaque    = @(244, 230, 0)
        PixelArt       = $true
        SeoKeywords    = $ExtraSeo
        HashtagsBase   = $ExtraHash
        TagsBase       = $ExtraTags
    }
}

$IssdTeamKeywords = @{
    "Brasil"     = "Brazil, Allejo, Gomez, Beranco, Pardilla, Ferreira, Cicero, Roca, Santos, Silva"
    "Alemanha"   = "Germany, Kolle, Sieke, Kuhnert, Bergmann, Strauss, Becker, Muller, Stein"
    "Japao"      = "Japan, Fujimoto, Paz, Hasebe, Takeda, Moriyama, Sato, Kojima, Blue Samurai"
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

function Invoke-ExtractMatchFrames([System.IO.FileInfo]$VideoFile) {
    $FfmpegExe = Find-Ffmpeg
    New-Item -ItemType Directory -Force -Path $FramesDir | Out-Null
    Get-ChildItem $FramesDir -File -ErrorAction SilentlyContinue | Remove-Item -Force

    Write-Host "Extraindo quadros da partida e placar final de '$($VideoFile.Name)'..." -ForegroundColor Cyan
    foreach ($offset in @(25, 15, 10, 6, 3, 1)) {
        $outImg = Join-Path $FramesDir "final_menos_${offset}s.png"
        & $FfmpegExe -y -loglevel error -sseof "-$offset" -i $VideoFile.FullName -frames:v 1 $outImg
    }
    foreach ($sec in @(120, 300, 540)) {
        $actImg = Join-Path $FramesDir "lance_${sec}s.png"
        & $FfmpegExe -y -loglevel error -ss $sec -i $VideoFile.FullName -frames:v 1 $actImg
    }
    $mainLance = Join-Path $FramesDir "lance_300s.png"
    $destLance = Join-Path $FramesDir "lance_partida.png"
    if (Test-Path $mainLance) { Copy-Item $mainLance $destLance -Force }
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

function Build-MatchSeoData {
    param(
        [hashtable]$Profile, [string]$T1, [string]$T2, [int]$G1, [int]$G2, [string]$Modo, [string]$Rom
    )

    $NomeJogo = if ($Rom) { $Rom } else { $Profile.NomeCompleto }

    # Titulo otimizado com Partida + Placar + Jogo + Canal (MAX 100 chars, SEM Nintendo/SNES/Konami)
    $Titulo = "$T1 $G1 x $G2 $T2 | $($Profile.NomeCompleto) | skimboll2001"
    if ($Titulo.Length -gt 100) {
        $Titulo = "$T1 $G1 x $G2 $T2 | $($Profile.NomeCurto) | skimboll2001"
    }

    $TagT1 = Remove-Accents $T1
    $TagT2 = Remove-Accents $T2
    $HashtagsPartida = "#${TagT1}x${TagT2} #$TagT1 #$TagT2 $($Profile.HashtagsBase)"

    $ExtrasLine = ""
    if ($Profile.Key -eq "ISSD") {
        $ExtrasT1 = $IssdTeamKeywords[$TagT1]
        $ExtrasT2 = $IssdTeamKeywords[$TagT2]
        $ExtrasLine = (@($ExtrasT1, $ExtrasT2) | Where-Object { $_ }) -join ", "
    }

    $Star = [char]0x2605
    $LineSep = ([string][char]0x2501) * 34

    $LinhasDesc = @(
        "PARTIDA: $T1 vs $T2 | RESULTADO FINAL: $T1 $G1 x $G2 $T2",
        "INSCREVA-SE NO CANAL SKIMBOLL2001: https://www.youtube.com/@skimboll2001?sub_confirmation=1",
        "Deixe o Like e inscreva-se para acompanhar todas as partidas e torneios no canal Skimboll2001!",
        "",
        $LineSep,
        "$Star FICHA DA PARTIDA & RESULTADO $Star",
        $LineSep,
        "- Confronto: $T1 x $T2",
        "- Placar Final: $T1 $G1 x $G2 $T2",
        "- Jogo / Versao: $NomeJogo",
        "- Torneio / Modo: $Modo",
        "- Canal: Skimboll2001 (Skimboll desde 2001 | seit 2001 | since 2001)",
        "",
        $LineSep,
        "$Star INSCREVA-SE NO CANAL $Star",
        $LineSep,
        "Inscreva-se aqui: https://www.youtube.com/channel/UCR1UuLEs-n55oz85e7Lc5gg?sub_confirmation=1",
        "Gameplays e torneios de International Superstar Soccer Deluxe (ISSD, Charmoso Gaucho, Deutscher Fussball, Champions League, Mundial de Clubes, Campeonato Brasileiro 95-99, Futebol Brasileiro 95-99, Ronaldinho Soccer, ISSD Extended), eFootball, EA Sports FC e FIFA.",
        "",
        $LineSep,
        "$Star PALAVRAS-CHAVE E TERMOS DE BUSCA (SEO) $Star",
        $LineSep,
        "$T1 x $T2, $T1 vs $T2, $T1 $G1 x $G2 $T2, $T1 $G1 a $G2 $T2, $T1 $($Profile.NomeCompleto), $T2 $($Profile.NomeCompleto), $($Profile.SeoKeywords), $ExtrasLine, Skimboll2001, skimboll 2001.",
        "",
        $HashtagsPartida
    )
    $Descricao = $LinhasDesc -join "`r`n"

    $Tags = @(
        "$T1 x $T2",
        "$T1 vs $T2",
        "$T1 $G1 x $G2 $T2",
        "$T1 $($Profile.NomeCurto)"
    ) + $Profile.TagsBase

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

function Draw-SkimbollOfficialBadge {
    param(
        [System.Drawing.Graphics]$Gfx,
        [int]$X, [int]$Y, [int]$W, [int]$H
    )
    if (Test-Path $LogoPath) {
        $LogoImg = [System.Drawing.Image]::FromFile((Resolve-Path $LogoPath).Path)
        $Gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        $Gfx.DrawImage($LogoImg, $X, $Y, $W, $H)
        $LogoImg.Dispose()
    }
}

function New-MatchThumbnail {
    param(
        [hashtable]$Profile,
        [string]$T1, [string]$T2, [int]$G1, [int]$G2,
        [string]$Modo, [string]$OutPath,
        [string]$ActionImgPath, [string]$ScoreboardImgPath
    )

    Add-Type -AssemblyName System.Drawing

    $Bmp = New-Object System.Drawing.Bitmap(1280, 720)
    $Gfx = [System.Drawing.Graphics]::FromImage($Bmp)
    $Gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $Gfx.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    $ColorSkimRed    = [System.Drawing.Color]::FromArgb(255, 210, 29, 29)
    $ColorSkimDark   = [System.Drawing.Color]::FromArgb(255, 140, 14, 14)
    $ColorSkimYellow = [System.Drawing.Color]::FromArgb(255, 244, 230, 0)
    $ColorWhite      = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
    $ColorBlack      = [System.Drawing.Color]::FromArgb(255, 14, 14, 18)

    $BrushSkimRed    = New-Object System.Drawing.SolidBrush($ColorSkimRed)
    $BrushSkimDark   = New-Object System.Drawing.SolidBrush($ColorSkimDark)
    $BrushSkimYellow = New-Object System.Drawing.SolidBrush($ColorSkimYellow)
    $BrushWhite      = New-Object System.Drawing.SolidBrush($ColorWhite)
    $BrushBlack      = New-Object System.Drawing.SolidBrush($ColorBlack)
    $BrushBadge      = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, $Profile.CorBadge[0], $Profile.CorBadge[1], $Profile.CorBadge[2]))
    $BrushAccent     = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, $Profile.CorDestaque[0], $Profile.CorDestaque[1], $Profile.CorDestaque[2]))

    $PenYellowThick  = New-Object System.Drawing.Pen($ColorSkimYellow, 6)
    $PenYellowThin   = New-Object System.Drawing.Pen($ColorSkimYellow, 3)
    $PenRedOuter     = New-Object System.Drawing.Pen($ColorSkimRed, 12)

    $FormatCenter = New-Object System.Drawing.StringFormat
    $FormatCenter.Alignment = [System.Drawing.StringAlignment]::Center
    $FormatCenter.LineAlignment = [System.Drawing.StringAlignment]::Center
    $FormatCenter.FormatFlags = [System.Drawing.StringFormatFlags]::NoWrap

    if (-not $ActionImgPath) {
        $CandidateLance = Join-Path $FramesDir "lance_partida.png"
        if (Test-Path $CandidateLance) { $ActionImgPath = $CandidateLance }
    } elseif ($ActionImgPath -eq "none") {
        $ActionImgPath = $null
    }
    if (-not $ScoreboardImgPath) {
        $CandidateScore = Join-Path $FramesDir "final_menos_10s.png"
        if (Test-Path $CandidateScore) { $ScoreboardImgPath = $CandidateScore }
    } elseif ($ScoreboardImgPath -eq "none") {
        $ScoreboardImgPath = $null
    }

    $Gfx.FillRectangle($BrushSkimDark, 0, 0, 1280, 720)

    if ($ActionImgPath -and (Test-Path $ActionImgPath) -and $ScoreboardImgPath -and (Test-Path $ScoreboardImgPath)) {
        $ActImg = [System.Drawing.Image]::FromFile((Resolve-Path $ActionImgPath).Path)
        if ($Profile.PixelArt) {
            $Gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
            $Gfx.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
        } else {
            $Gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        }
        $Gfx.DrawImage($ActImg, 12, 12, 804, 546)
        $ActImg.Dispose()

        $Gfx.FillRectangle($BrushSkimRed, 820, 12, 448, 546)
        Draw-SkimbollOfficialBadge -Gfx $Gfx -X 828 -Y 14 -W 432 -H 178

        $Gfx.FillRectangle($BrushBadge, 828, 196, 432, 38)
        $Gfx.DrawRectangle($PenYellowThin, 828, 196, 432, 38)
        $Star = [char]0x2605
        $BadgeTxt = "$Star $($Profile.NomeCurto) $Star"
        $FontRightBadge = Get-FittedFont -Gfx $Gfx -Text $BadgeTxt -FontFamily "Consolas" -MaxSize 20 -MinSize 13 -MaxWidth 418
        $Gfx.DrawString($BadgeTxt, $FontRightBadge, $BrushAccent, (New-Object System.Drawing.RectangleF(828, 196, 432, 38)), $FormatCenter)

        $ScoreImg = [System.Drawing.Image]::FromFile((Resolve-Path $ScoreboardImgPath).Path)
        if ($Profile.PixelArt) {
            $Gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        }
        $Gfx.DrawImage($ScoreImg, 828, 238, 432, 314)
        $ScoreImg.Dispose()
        $Gfx.DrawRectangle($PenYellowThin, 828, 238, 432, 314)

        $Gfx.DrawLine($PenYellowThick, 818, 12, 818, 558)
    } else {
        if ($ActionImgPath -and (Test-Path $ActionImgPath)) {
            $ActImg = [System.Drawing.Image]::FromFile((Resolve-Path $ActionImgPath).Path)
            $Gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $Gfx.DrawImage($ActImg, 12, 12, 804, 546)
            $ActImg.Dispose()
        } else {
            $GradBg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
                (New-Object System.Drawing.Point(0, 0)),
                (New-Object System.Drawing.Point(820, 560)),
                ([System.Drawing.Color]::FromArgb(255, $Profile.CorBadge[0], $Profile.CorBadge[1], $Profile.CorBadge[2])),
                $ColorBlack
            )
            $Gfx.FillRectangle($GradBg, 12, 12, 804, 546)

            $PitchPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(75, 244, 230, 0), 4)
            $Gfx.DrawRectangle($PitchPen, 48, 42, 730, 486)
            $Gfx.DrawLine($PitchPen, 413, 42, 413, 528)
            $Gfx.DrawEllipse($PitchPen, 313, 185, 200, 200)

            $FontGameBig = Get-FittedFont -Gfx $Gfx -Text $Profile.NomeCurto -FontFamily "Arial Black" -MaxSize 52 -MinSize 24 -MaxWidth 740
            $Gfx.DrawString($Profile.NomeCurto, $FontGameBig, $BrushAccent, (New-Object System.Drawing.RectangleF(32, 180, 760, 100)), $FormatCenter)

            $FontSubBig = Get-FittedFont -Gfx $Gfx -Text $Profile.SubtituloThumb -FontFamily "Consolas" -MaxSize 26 -MinSize 16 -MaxWidth 740
            $Gfx.DrawString($Profile.SubtituloThumb, $FontSubBig, $BrushWhite, (New-Object System.Drawing.RectangleF(32, 280, 760, 60)), $FormatCenter)
        }

        $Gfx.FillRectangle($BrushSkimRed, 820, 12, 448, 546)
        Draw-SkimbollOfficialBadge -Gfx $Gfx -X 828 -Y 20 -W 432 -H 315

        $Gfx.FillRectangle($BrushBlack, 836, 350, 416, 192)
        $Gfx.DrawRectangle($PenYellowThin, 836, 350, 416, 192)
        $FontCardTitle = Get-FittedFont -Gfx $Gfx -Text $Profile.NomeCurto -FontFamily "Consolas" -MaxSize 24 -MinSize 16 -MaxWidth 390
        $Gfx.DrawString($Profile.NomeCurto, $FontCardTitle, $BrushSkimYellow, (New-Object System.Drawing.RectangleF(840, 365, 408, 50)), $FormatCenter)

        $FontModo = Get-FittedFont -Gfx $Gfx -Text $Modo.ToUpper() -FontFamily "Arial Black" -MaxSize 24 -MinSize 16 -MaxWidth 390
        $Gfx.DrawString($Modo.ToUpper(), $FontModo, $BrushWhite, (New-Object System.Drawing.RectangleF(840, 425, 408, 55)), $FormatCenter)

        $FontCanalTag = New-Object System.Drawing.Font("Consolas", 18, [System.Drawing.FontStyle]::Bold)
        $Gfx.DrawString("SKIMBOLL DESDE 2001", $FontCanalTag, $BrushSkimYellow, (New-Object System.Drawing.RectangleF(840, 485, 408, 40)), $FormatCenter)

        $Gfx.DrawLine($PenYellowThick, 818, 12, 818, 558)
    }

    # Barra Inferior de Torneio (Y=560..708)
    $Gfx.FillRectangle($BrushSkimRed, 12, 560, 1256, 148)
    $Gfx.DrawLine($PenYellowThick, 12, 560, 1268, 560)

    $TriPts = @(
        (New-Object System.Drawing.Point(34, 578)),
        (New-Object System.Drawing.Point(138, 578)),
        (New-Object System.Drawing.Point(86, 686))
    )
    $PenTri = New-Object System.Drawing.Pen($ColorSkimYellow, 8)
    $Gfx.DrawPolygon($PenTri, $TriPts)
    $FontTriS = New-Object System.Drawing.Font("Arial Black", 36, [System.Drawing.FontStyle]::Bold)
    $Gfx.DrawString("S", $FontTriS, $BrushSkimYellow, (New-Object System.Drawing.RectangleF(34, 576, 104, 72)), $FormatCenter)

    $T1Upper = $T1.ToUpper()
    $T2Upper = $T2.ToUpper()

    $FontT1 = Get-FittedFont -Gfx $Gfx -Text $T1Upper -FontFamily "Arial Black" -MaxSize 46 -MinSize 24 -MaxWidth 380
    $Gfx.DrawString($T1Upper, $FontT1, $BrushWhite, (New-Object System.Drawing.RectangleF(155, 572, 390, 92)), $FormatCenter)

    $Gfx.FillRectangle($BrushBlack, 555, 574, 210, 90)
    $Gfx.DrawRectangle($PenYellowThick, 555, 574, 210, 90)
    $ScoreStr = "$G1 x $G2"
    $FontScore = Get-FittedFont -Gfx $Gfx -Text $ScoreStr -FontFamily "Consolas" -MaxSize 50 -MinSize 30 -MaxWidth 195
    $Gfx.DrawString($ScoreStr, $FontScore, $BrushSkimYellow, (New-Object System.Drawing.RectangleF(555, 574, 210, 90)), $FormatCenter)

    $FontT2 = Get-FittedFont -Gfx $Gfx -Text $T2Upper -FontFamily "Arial Black" -MaxSize 46 -MinSize 24 -MaxWidth 380
    $Gfx.DrawString($T2Upper, $FontT2, $BrushWhite, (New-Object System.Drawing.RectangleF(775, 572, 390, 92)), $FormatCenter)

    $Gfx.FillRectangle($BrushSkimDark, 155, 668, 1095, 34)
    $FontBottomSub = Get-FittedFont -Gfx $Gfx -Text "$($Profile.SubtituloThumb)  |  SKIMBOLL DESDE 2001 • SEIT 2001 • SINCE 2001" -FontFamily "Consolas" -MaxSize 16 -MinSize 12 -MaxWidth 1080
    $Gfx.DrawString("$($Profile.SubtituloThumb)  |  SKIMBOLL DESDE 2001 • SEIT 2001 • SINCE 2001", $FontBottomSub, $BrushSkimYellow, (New-Object System.Drawing.RectangleF(155, 668, 1095, 34)), $FormatCenter)

    $Gfx.DrawRectangle($PenRedOuter, 6, 6, 1268, 708)
    $Gfx.DrawRectangle($PenYellowThick, 12, 12, 1256, 696)

    $Bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $Gfx.Dispose()
    $Bmp.Dispose()
}

switch ($Acao) {
    "ExtrairFrames" {
        $VideoFile = Resolve-TargetVideo $ArquivoVideo
        Invoke-ExtractMatchFrames $VideoFile
        Get-ChildItem $FramesDir | Select-Object Name, Length
        return
    }

    "GerarThumb" {
        $Profile = Get-GameProfile -InputJogo $Jogo -InputAno $Ano -InputRom $VersaoRom -VideoFileName $ArquivoVideo
        if (-not $ArquivoThumb) {
            $ArquivoThumb = Join-Path $ThumbsDir "thumb-ultima-partida.png"
        }
        New-MatchThumbnail -Profile $Profile -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -OutPath $ArquivoThumb -ActionImgPath $ImagemLance -ScoreboardImgPath $ImagemPlacar
        $Seo = Build-MatchSeoData -Profile $Profile -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -Rom $VersaoRom
        $DescPath = Join-Path $PSScriptRoot "..\descricao-video.txt"
        [System.IO.File]::WriteAllText($DescPath, $Seo.Descricao, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "Thumbnail ($($Profile.NomeCompleto)) gerada em: $ArquivoThumb" -ForegroundColor Green
        Write-Host "Titulo SEO: $($Seo.Titulo)" -ForegroundColor Cyan
        return
    }

    "GerarModelosJogos" {
        New-Item -ItemType Directory -Force -Path $ThumbsDir | Out-Null

        # 1. Modelo ISSD Normal
        $P1 = Get-GameProfile -InputJogo "ISSD" -InputAno "" -InputRom "" -VideoFileName ""
        $OutIssd = Join-Path $ThumbsDir "modelo-thumb-ISSD.png"
        New-MatchThumbnail -Profile $P1 -T1 "Alemanha" -T2 "Japão" -G1 3 -G2 0 -Modo "International Cup Deluxe" -OutPath $OutIssd
        Copy-Item $OutIssd (Join-Path $ThumbsDir "thumb-ultima-partida.png") -Force

        # 2. Modelo eFootball
        $P2 = Get-GameProfile -InputJogo "eFootball" -InputAno "" -InputRom "" -VideoFileName ""
        $OutEf = Join-Path $ThumbsDir "modelo-thumb-eFootball.png"
        New-MatchThumbnail -Profile $P2 -T1 "Brasil" -T2 "Argentina" -G1 2 -G2 1 -Modo "eFootball International Cup" -OutPath $OutEf -ActionImgPath "none" -ScoreboardImgPath "none"

        # 3. Modelo EAFC
        $P3 = Get-GameProfile -InputJogo "EAFC" -InputAno "" -InputRom "" -VideoFileName ""
        $OutEafc = Join-Path $ThumbsDir "modelo-thumb-EAFC.png"
        New-MatchThumbnail -Profile $P3 -T1 "Real Madrid" -T2 "Bayern" -G1 3 -G2 2 -Modo "Champions Tournament" -OutPath $OutEafc -ActionImgPath "none" -ScoreboardImgPath "none"

        # 4. Modelo FIFA
        $P4 = Get-GameProfile -InputJogo "FIFA" -InputAno "" -InputRom "" -VideoFileName ""
        $OutFifa = Join-Path $ThumbsDir "modelo-thumb-FIFA.png"
        New-MatchThumbnail -Profile $P4 -T1 "França" -T2 "Itália" -G1 1 -G2 0 -Modo "World Cup Classic" -OutPath $OutFifa -ActionImgPath "none" -ScoreboardImgPath "none"

        Write-Host "Todos os modelos de Thumbnails foram gerados (sem referencias a Nintendo/Konami) em: $ThumbsDir" -ForegroundColor Green
        Get-ChildItem $ThumbsDir -Filter "*.png" | Select-Object Name, Length
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

    $Html = [System.Text.Encoding]::UTF8.GetBytes("<html><body style='background:#D21D1D;color:#F4E600;font-family:monospace;text-align:center;padding-top:80px;'><h1>SKIMBOLL2001 AUTORIZADO!</h1><p style='color:#fff;'>Pode fechar esta aba e voltar ao VS Code.</p></body></html>")
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
        $Profile = Get-GameProfile -InputJogo $Jogo -InputAno $Ano -InputRom $VersaoRom -VideoFileName $ArquivoVideo
        $Token = Get-AccessToken
        $Seo = Build-MatchSeoData -Profile $Profile -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -Rom $VersaoRom

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

        Write-Host "Atualizando titulo, descricao SEO ($($Profile.NomeCompleto)) e tags do video $VideoId..." -ForegroundColor Cyan
        $UpdateResultFile = Join-Path $PSScriptRoot "..\.secrets\temp-update-res.json"
        & curl.exe -s -S -X PUT "https://www.googleapis.com/youtube/v3/videos?part=snippet" `
            -H "Authorization: Bearer $Token" `
            -H "Content-Type: application/json; charset=UTF-8" `
            --data-binary "@$TempUpdateFile" `
            -o $UpdateResultFile
        Remove-Item $TempUpdateFile, $UpdateResultFile -Force -ErrorAction SilentlyContinue

        if (-not $ArquivoThumb -or -not (Test-Path $ArquivoThumb)) {
            $ArquivoThumb = Join-Path $ThumbsDir "thumb-ultima-partida.png"
            Write-Host "Gerando thumbnail 1280x720 ($($Profile.NomeCurto) : $Time1 $Gols1 x $Gols2 $Time2)..." -ForegroundColor Yellow
            New-MatchThumbnail -Profile $Profile -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -OutPath $ArquivoThumb -ActionImgPath $ImagemLance -ScoreboardImgPath $ImagemPlacar
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
        $Profile = Get-GameProfile -InputJogo $Jogo -InputAno $Ano -InputRom $VersaoRom -VideoFileName $VideoFile.Name

        Invoke-ExtractMatchFrames $VideoFile

        $Token = Get-AccessToken
        $Canal = Invoke-RestMethod -Uri "https://www.googleapis.com/youtube/v3/channels?part=snippet&mine=true" -Headers @{ Authorization = "Bearer $Token" }
        Write-Host "Publicando ($($Profile.NomeCompleto)) no canal: $($Canal.items[0].snippet.title) ($($Canal.items[0].id))" -ForegroundColor Cyan

        $Seo = Build-MatchSeoData -Profile $Profile -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -Rom $VersaoRom

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
            $ArquivoThumb = Join-Path $ThumbsDir "thumb-ultima-partida.png"
            Write-Host "3/3 Gerando thumbnail automatica ($($Profile.NomeCurto) : $Time1 $Gols1 x $Gols2 $Time2)..." -ForegroundColor Yellow
            New-MatchThumbnail -Profile $Profile -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -OutPath $ArquivoThumb -ActionImgPath $ImagemLance -ScoreboardImgPath $ImagemPlacar
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
        Write-Host "Jogo     : $($Profile.NomeCompleto)" -ForegroundColor White
        Write-Host "Partida  : $Time1 $Gols1 x $Gols2 $Time2" -ForegroundColor Yellow
        Write-Host "ID       : $($VideoResp.id)" -ForegroundColor White
        Write-Host "Link     : https://youtu.be/$($VideoResp.id)" -ForegroundColor Cyan
        Write-Host "Studio   : https://studio.youtube.com/video/$($VideoResp.id)/edit" -ForegroundColor Yellow
        Write-Host "======================================================" -ForegroundColor Green
    }
}
