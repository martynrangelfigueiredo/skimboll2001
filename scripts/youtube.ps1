<#
.SYNOPSIS
    Publicador e Agendador Oficial Multi-Jogos & ROMHACKs - Canal Skimboll2001
    - PROIBIDO referenciar "Nintendo", "Super Nintendo", "SNES", "Super Famicom" ou "Konami"
    - Suporta agendamento nativo na API do YouTube (publishAt) sempre nos horarios 06:00 e 17:30 (-03:00)
    - Suporta todo o catalogo de ISSD + ROMHACKs, eFootball, EAFC e FIFA
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Login", "Status", "AtualizarCanal", "ExtrairFrames", "PostarVideo", "AtualizarVideo", "DeletarVideo", "GerarThumb", "GerarModelosJogos", "ListarAgenda")]
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
    [string]$DataPublicacao = "",       # Formato ISO 8601 ex: 2026-11-17T06:00:00-03:00
    [switch]$AgendarProximoSlot,        # Calcula automaticamente o proximo slot 06:00 ou 17:30
    [string]$TituloCustom = "",         # Opcional para treinos/especiais
    [string]$TextoBarraCustom = "",     # Opcional para barra inferior da thumb
    [string]$NotaExtra = "",            # Nota adicional em destaque no topo da descricao
    [ValidateSet("1080p", "1440p", "Original")]
    [string]$QualidadeUpload = "1440p", # Upscale Pixel-Perfect (NearestNeighbor) automatico para 1440p60 (VP9) ou 1080p60
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
$AgendaPath = Join-Path $PSScriptRoot "..\agenda-publicacoes.json"

function Get-NextScheduleSlot {
    # Horarios fixos da agenda do canal: 06:00 e 17:30 (horario de Brasilia -03:00)
    $Now = Get-Date
    $LastScheduled = $Now

    if (Test-Path $AgendaPath) {
        try {
            $AgendaItems = Get-Content $AgendaPath -Raw -Encoding UTF8 | ConvertFrom-Json
            foreach ($item in $AgendaItems) {
                if ($item.publishAt) {
                    $dt = [DateTime]::Parse($item.publishAt)
                    if ($dt -gt $LastScheduled) {
                        $LastScheduled = $dt
                    }
                }
            }
        } catch {}
    }

    # Encontrar o proximo slot (06:00 ou 17:30) estritamente apos $LastScheduled
    $CandidateDate = $LastScheduled.Date
    for ($d = 0; $d -le 60; $d++) {
        $Day = $CandidateDate.AddDays($d)
        $SlotMorning = New-Object DateTime($Day.Year, $Day.Month, $Day.Day, 6, 0, 0)
        $SlotEvening = New-Object DateTime($Day.Year, $Day.Month, $Day.Day, 17, 30, 0)

        if ($SlotMorning -gt $LastScheduled.AddMinutes(5)) {
            return $SlotMorning.ToString("yyyy-MM-ddTHH:mm:ss-03:00")
        }
        if ($SlotEvening -gt $LastScheduled.AddMinutes(5)) {
            return $SlotEvening.ToString("yyyy-MM-ddTHH:mm:ss-03:00")
        }
    }
}

function Save-AgendaEntry {
    param([string]$VideoId, [string]$Titulo, [string]$Arquivo, [string]$Status, [string]$PublishAt)
    $List = @()
    if (Test-Path $AgendaPath) {
        try {
            $Existing = Get-Content $AgendaPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($Existing) { $List = @($Existing) }
        } catch {}
    }
    $NewEntry = [PSCustomObject]@{
        videoId    = $VideoId
        url        = "https://youtu.be/$VideoId"
        titulo     = $Titulo
        arquivo    = $Arquivo
        status     = $Status
        publishAt  = $PublishAt
        enviadoEm  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss-03:00")
    }
    $List += $NewEntry
    $Json = $List | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($AgendaPath, $Json, (New-Object System.Text.UTF8Encoding($false)))
}

function Get-GameProfile {
    param([string]$InputJogo, [string]$InputAno, [string]$InputRom, [string]$VideoFileName)

    $Combined = "$InputJogo $InputRom $VideoFileName".Trim()
    $AnoFinal = $InputAno
    if (-not $AnoFinal -and $Combined -match "\b(199[5-9]|20[0-2][0-9]|9[5-9]|2[4-9])\b") {
        $AnoFinal = $Matches[1]
    }
    $SufixoAno = if ($AnoFinal) { " $AnoFinal" } else { "" }

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
    elseif ($Combined -match "(?i)champions\s*league|\bcl\s*2[0-9]\b") {
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
    "China"           = "China, Sun Hao, Liu Kun, Luo Ning, Selecao Chinesa, Team China, ISSD Extended"
    "Islandia"        = "Iceland, Islandia, Magnus, Bjarni, Selecao Islandesa, ISSD Extended"
    "Brasil"          = "Brazil, Allejo, Gomez, Beranco, Pardilla, Ferreira, Cicero, Roca, Santos, Silva, Ronaldo, Rivaldo, Roberto Carlos"
    "Brasil99"        = "Brazil 1999, Brasil 99, Ronaldo, Rivaldo, Christian, Roberto Carlos, Cafu, Dida, Emerson, Ze Roberto"
    "Franca98"        = "France 1998, Franca 98, Zidane, Deschamps, Henry, Trezeguet, Barthez, Blanc, Thuram, Petit, Vieira"
    "Alemanha"        = "Germany, Kolle, Sieke, Kuhnert, Klahold, Bergmann, Strauss, Becker, Muller, Stein"
    "RepublicaTcheca" = "Czech Republic, Czech, Blazek, Nedved, Poborsky, Berger, Koller, Smicer"
    "Japao"           = "Japan, Fujimoto, Paz, Hasebe, Takeda, Moriyama, Sato, Kojima, Blue Samurai"
    "Italia"          = "Italy, Galfano, Carboni, Premoli, Pagani, Rossi, Conti, Azzurra"
    "Argentina"       = "Argentina, Capitale, Redonda, Fuerte, Ayala, Galvez, Albiceleste"
    "Inglaterra"      = "England, Milner, Wright, Bruce, Clarke, Baker"
    "Holanda"         = "Netherlands, Holland, Van Wijk, Rijkaard, De Vries, Koppers"
    "Franca"          = "France, Dubois, Moreau, Girard, Blanc, Laurent"
    "BayernDeMunique" = "Bayern Munchen, Bayern Munich, Harry Kane, Goretzka, Alphonso Davies, Urbig, Musiala, Kimmich"
    "BorussiaDortmund"= "Borussia Dortmund, BVB, Ryerson, Der Klassiker, Bundesliga, Champions League"
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

function Optimize-VideoForYouTube {
    param(
        [System.IO.FileInfo]$InputVideo,
        [string]$TargetQuality = "1440p"
    )
    if ($TargetQuality -eq "Original" -or $InputVideo.Name -match "_(1440p|1080p)60_HD\.mp4$") {
        return $InputVideo
    }

    $FfmpegExe = Find-Ffmpeg
    $OldEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $ProbeOut = (& $FfmpegExe -i $InputVideo.FullName 2>&1 | Out-String)
    $ErrorActionPreference = $OldEap
    $Width = 0; $Height = 0
    if ($ProbeOut -match "Stream #\d+:\d+.*Video:.*,\s*(\d+)x(\d+)") {
        $Width  = [int]$Matches[1]
        $Height = [int]$Matches[2]
    }

    # Se o video ja estiver em 1080p ou superior, nao precisa recodificar
    if ($Height -ge 1080) {
        Write-Host "Video ja esta em alta resolucao (${Width}x${Height}). Mantendo arquivo original." -ForegroundColor Green
        return $InputVideo
    }

    $OutRes = if ($TargetQuality -eq "1440p") { "2560:1440" } else { "1920:1080" }
    $OutFileName = "$($InputVideo.BaseName)_${TargetQuality}60_HD.mp4"
    $OutFilePath = Join-Path $InputVideo.DirectoryName $OutFileName

    if (Test-Path $OutFilePath) {
        $Existing = Get-Item $OutFilePath
        if ($Existing.Length -gt 10MB) {
            Write-Host "Arquivo otimizado em $TargetQuality60 ja existe: $($Existing.Name) ($([math]::Round($Existing.Length / 1MB, 2)) MB)" -ForegroundColor Green
            return $Existing
        }
    }

    Write-Host "==================================================================" -ForegroundColor Magenta
    Write-Host "OTIMIZANDO QUALIDADE DE VIDEO PARA YOUTUBE ($TargetQuality 60FPS PIXEL-PERFECT)" -ForegroundColor Magenta
    Write-Host "Origem : $($InputVideo.Name) (${Width}x${Height} -> causava 240p no YouTube)" -ForegroundColor Yellow
    Write-Host "Destino: $OutFileName ($OutRes @ 60fps com filtro NearestNeighbor nítido)" -ForegroundColor Cyan
    Write-Host "==================================================================" -ForegroundColor Magenta

    # Usa aceleracao de hardware Intel Quick Sync (h264_qsv) com fallback automatico para libx264
    & $FfmpegExe -y -loglevel warning -stats `
        -i $InputVideo.FullName `
        -vf "scale=${OutRes}:flags=neighbor,format=nv12" `
        -r 60 `
        -c:v h264_qsv -global_quality 25 -look_ahead 0 `
        -c:a aac -b:a 192k -ar 48000 `
        -movflags +faststart `
        $OutFilePath

    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $OutFilePath)) {
        Write-Host "Usando encoder CPU libx264 superfast..." -ForegroundColor Yellow
        & $FfmpegExe -y -loglevel warning -stats `
            -i $InputVideo.FullName `
            -vf "scale=${OutRes}:flags=neighbor,format=yuv420p" `
            -r 60 `
            -c:v libx264 -preset superfast -crf 19 `
            -c:a aac -b:a 320k -ar 48000 `
            -movflags +faststart `
            $OutFilePath
    }

    return (Get-Item $OutFilePath)
}

function Invoke-ExtractMatchFrames([System.IO.FileInfo]$VideoFile) {
    $FfmpegExe = Find-Ffmpeg
    New-Item -ItemType Directory -Force -Path $FramesDir | Out-Null
    Get-ChildItem $FramesDir -File -ErrorAction SilentlyContinue | Remove-Item -Force

    Write-Host "Extraindo quadros da partida e placar final de '$($VideoFile.Name)'..." -ForegroundColor Cyan
    foreach ($offset in @(25, 15, 10, 8, 5, 2)) {
        $outImg = Join-Path $FramesDir "final_menos_${offset}s.png"
        & $FfmpegExe -y -loglevel error -sseof "-$offset" -i $VideoFile.FullName -frames:v 1 $outImg
    }
    foreach ($sec in @(60, 180, 300)) {
        $actImg = Join-Path $FramesDir "lance_${sec}s.png"
        & $FfmpegExe -y -loglevel error -ss $sec -i $VideoFile.FullName -frames:v 1 $actImg
    }
    $mainLance = Join-Path $FramesDir "lance_180s.png"
    if (-not (Test-Path $mainLance)) { $mainLance = Join-Path $FramesDir "lance_60s.png" }
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
        [hashtable]$Profile, [string]$T1, [string]$T2, [int]$G1, [int]$G2, [string]$Modo, [string]$Rom, [string]$CustomTitle, [string]$ExtraNote
    )

    $NomeJogo = if ($Rom) { $Rom } else { $Profile.NomeCompleto }

    if ($CustomTitle) {
        $Titulo = $CustomTitle
    } else {
        $Titulo = "$T1 $G1 x $G2 $T2 | $($Profile.NomeCompleto) | skimboll2001"
        if ($Titulo.Length -gt 100) {
            $Titulo = "$T1 $G1 x $G2 $T2 | $($Profile.NomeCurto) | skimboll2001"
        }
    }

    $TagT1 = Remove-Accents $T1
    $TagT2 = Remove-Accents $T2
    if ($T2) {
        $HashtagsPartida = "#${TagT1}x${TagT2} #$TagT1 #$TagT2 $($Profile.HashtagsBase)"
        $LinhaTopo = "PARTIDA: $T1 vs $T2 | RESULTADO FINAL: $T1 $G1 x $G2 $T2"
        $ConfrontoDesc = "$T1 x $T2"
        $PlacarDesc = "$T1 $G1 x $G2 $T2"
    } else {
        $HashtagsPartida = "#$TagT1 #TrainingSession $($Profile.HashtagsBase)"
        $LinhaTopo = "TREINO / GAMEPLAY: $T1 ($Modo) | $NomeJogo"
        $ConfrontoDesc = "$T1 ($Modo)"
        $PlacarDesc = $Modo
    }

    $ExtrasT1 = $IssdTeamKeywords[$TagT1]
    $ExtrasT2 = $IssdTeamKeywords[$TagT2]
    $ExtrasLine = (@($ExtrasT1, $ExtrasT2) | Where-Object { $_ }) -join ", "

    $Star = [char]0x2605
    $LineSep = ([string][char]0x2501) * 34

    $LinhasDesc = @(
        $LinhaTopo,
        "INSCREVA-SE NO CANAL SKIMBOLL2001: https://www.youtube.com/@skimboll2001?sub_confirmation=1"
    )
    if ($ExtraNote) {
        $LinhasDesc += @(
            "",
            "AVISO IMPORTANTE (PROJETO EM DESENVOLVIMENTO):",
            $ExtraNote
        )
    }
    $LinhasDesc += @(
        "Deixe o Like e inscreva-se para acompanhar todas as partidas e torneios no canal Skimboll2001 (videos novos as 06:00 e as 17:30)!",
        "",
        $LineSep,
        "$Star FICHA DA PARTIDA & RESULTADO $Star",
        $LineSep,
        "- Confronto: $ConfrontoDesc",
        "- Resultado / Modo: $PlacarDesc",
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
        "$T1, $T2, $ConfrontoDesc, $PlacarDesc, $T1 $($Profile.NomeCompleto), $($Profile.SeoKeywords), $ExtrasLine, Skimboll2001, skimboll 2001.",
        "",
        $HashtagsPartida
    )
    $Descricao = $LinhasDesc -join "`r`n"

    $Tags = @(
        $T1,
        "$T1 $($Profile.NomeCurto)"
    )
    if ($T2) {
        $Tags += @("$T1 x $T2", "$T1 vs $T2", "$T1 $G1 x $G2 $T2")
    }
    $Tags += $Profile.TagsBase

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
        [hashtable]$Profile,
        [string]$T1, [string]$T2, [int]$G1, [int]$G2,
        [string]$Modo, [string]$OutPath,
        [string]$ActionImgPath, [string]$ScoreboardImgPath,
        [string]$CustomBarText
    )

    Add-Type -AssemblyName System.Drawing

    $Bmp = New-Object System.Drawing.Bitmap(1280, 720)
    $Gfx = [System.Drawing.Graphics]::FromImage($Bmp)
    $Gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $Gfx.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    $ColorSkimRed    = [System.Drawing.Color]::FromArgb(255, 210, 29, 29)
    $ColorSkimYellow = [System.Drawing.Color]::FromArgb(255, 244, 230, 0)
    $ColorWhite      = [System.Drawing.Color]::FromArgb(255, 248, 249, 250)
    $ColorMuted      = [System.Drawing.Color]::FromArgb(255, 200, 205, 212)
    $ColorBarBg      = [System.Drawing.Color]::FromArgb(218, 12, 14, 18)

    $BrushSkimRed    = New-Object System.Drawing.SolidBrush($ColorSkimRed)
    $BrushSkimYellow = New-Object System.Drawing.SolidBrush($ColorSkimYellow)
    $BrushWhite      = New-Object System.Drawing.SolidBrush($ColorWhite)
    $BrushMuted      = New-Object System.Drawing.SolidBrush($ColorMuted)
    $BrushBarBg      = New-Object System.Drawing.SolidBrush($ColorBarBg)

    $PenYellowThin   = New-Object System.Drawing.Pen($ColorSkimYellow, 2)
    $PenSubtleBorder = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 244, 230, 0), 2)

    $FormatCenter = New-Object System.Drawing.StringFormat
    $FormatCenter.Alignment = [System.Drawing.StringAlignment]::Center
    $FormatCenter.LineAlignment = [System.Drawing.StringAlignment]::Center
    $FormatCenter.FormatFlags = [System.Drawing.StringFormatFlags]::NoWrap

    $FormatLeft = New-Object System.Drawing.StringFormat
    $FormatLeft.Alignment = [System.Drawing.StringAlignment]::Near
    $FormatLeft.LineAlignment = [System.Drawing.StringAlignment]::Center
    $FormatLeft.FormatFlags = [System.Drawing.StringFormatFlags]::NoWrap

    $FormatRight = New-Object System.Drawing.StringFormat
    $FormatRight.Alignment = [System.Drawing.StringAlignment]::Far
    $FormatRight.LineAlignment = [System.Drawing.StringAlignment]::Center
    $FormatRight.FormatFlags = [System.Drawing.StringFormatFlags]::NoWrap

    if (-not $ActionImgPath) {
        $CandidateLance = Join-Path $FramesDir "lance_partida.png"
        if (Test-Path $CandidateLance) { $ActionImgPath = $CandidateLance }
    } elseif ($ActionImgPath -eq "none") {
        $ActionImgPath = $null
    }
    if (-not $ScoreboardImgPath) {
        $CandidateScore = Join-Path $FramesDir "final_menos_8s.png"
        if (-not (Test-Path $CandidateScore)) { $CandidateScore = Join-Path $FramesDir "final_menos_10s.png" }
        if (Test-Path $CandidateScore) { $ScoreboardImgPath = $CandidateScore }
    } elseif ($ScoreboardImgPath -eq "none") {
        $ScoreboardImgPath = $null
    }

    # 1. FUNDO 100% TELA CHEIA (1280x720) — O VIDEO E O PROTAGONISTA ABSOLUTO
    if ($ActionImgPath -and (Test-Path $ActionImgPath)) {
        $ActImg = [System.Drawing.Image]::FromFile((Resolve-Path $ActionImgPath).Path)
        if ($Profile.PixelArt) {
            $Gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
            $Gfx.PixelOffsetMode   = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
        } else {
            $Gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        }
        $Gfx.DrawImage($ActImg, 0, 0, 1280, 720)
        $ActImg.Dispose()
    } else {
        $GradBg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            (New-Object System.Drawing.Point(0, 0)),
            (New-Object System.Drawing.Point(1280, 720)),
            ([System.Drawing.Color]::FromArgb(255, 18, 28, 22)),
            ([System.Drawing.Color]::FromArgb(255, 10, 14, 18))
        )
        $Gfx.FillRectangle($GradBg, 0, 0, 1280, 720)

        $PitchPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(45, 255, 255, 255), 3)
        $Gfx.DrawRectangle($PitchPen, 90, 50, 1100, 560)
        $Gfx.DrawLine($PitchPen, 640, 50, 640, 610)
        $Gfx.DrawEllipse($PitchPen, 510, 200, 260, 260)

        $FontWatermarkCenter = Get-FittedFont -Gfx $Gfx -Text $Profile.NomeCompleto -FontFamily "Segoe UI" -MaxSize 42 -MinSize 24 -MaxWidth 1000
        $Gfx.DrawString($Profile.NomeCompleto, $FontWatermarkCenter, $BrushMuted, (New-Object System.Drawing.RectangleF(140, 280, 1000, 80)), $FormatCenter)
    }

    # 2. MINIATURA DISCRETA DO PLACAR FINAL IN-GAME (Canto Inferior Direito, acima da barra: 304x224)
    if ($ScoreboardImgPath -and (Test-Path $ScoreboardImgPath)) {
        $PipX = 958
        $PipY = 412
        $PipW = 304
        $PipH = 224
        $ShadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(160, 0, 0, 0))
        $Gfx.FillRectangle($ShadowBrush, ($PipX - 4), ($PipY - 4), ($PipW + 8), ($PipH + 8))

        $ScoreImg = [System.Drawing.Image]::FromFile((Resolve-Path $ScoreboardImgPath).Path)
        if ($Profile.PixelArt) {
            $Gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        }
        $Gfx.DrawImage($ScoreImg, $PipX, $PipY, $PipW, $PipH)
        $ScoreImg.Dispose()
        $Gfx.DrawRectangle($PenSubtleBorder, $PipX, $PipY, $PipW, $PipH)
    }

    # 3. BARRA INFERIOR DISCRETA E SOBRIA (Apenas 68px de altura, semi-transparente)
    $BarY = 652
    $BarH = 68
    $Gfx.FillRectangle($BrushBarBg, 0, $BarY, 1280, $BarH)
    $Gfx.DrawLine($PenYellowThin, 0, $BarY, 1280, $BarY)

    # Watermark Oficial (Triangulo Invertido ▽ com S) discreto na esquerda da barra
    $TriPts = @(
        (New-Object System.Drawing.PointF(22, 664)),
        (New-Object System.Drawing.PointF(70, 664)),
        (New-Object System.Drawing.PointF(46, 710))
    )
    $Gfx.FillPolygon($BrushSkimRed, $TriPts)
    $PenTriSmall = New-Object System.Drawing.Pen($ColorSkimYellow, 3)
    $Gfx.DrawPolygon($PenTriSmall, $TriPts)
    $FontTriS = New-Object System.Drawing.Font("Arial Black", 16, [System.Drawing.FontStyle]::Bold)
    $Gfx.DrawString("S", $FontTriS, $BrushSkimYellow, (New-Object System.Drawing.RectangleF(22, 662, 48, 34)), $FormatCenter)

    # Confronto e Placar Limpos (Esquerda/Centro da barra)
    if ($CustomBarText) {
        $MatchString = $CustomBarText.ToUpper()
    } else {
        $T1Upper = $T1.ToUpper()
        $T2Upper = $T2.ToUpper()
        $MatchString = "$T1Upper   $G1 x $G2   $T2Upper"
    }
    $FontMatch = Get-FittedFont -Gfx $Gfx -Text $MatchString -FontFamily "Segoe UI" -MaxSize 28 -MinSize 18 -MaxWidth 740
    $Gfx.DrawString($MatchString, $FontMatch, $BrushWhite, (New-Object System.Drawing.RectangleF(88, $BarY, 750, $BarH)), $FormatLeft)

    # Identificacao Discreta do Jogo / ROMHACK na Direita da Barra
    $GameLabel = "$($Profile.NomeCurto)  •  SKIMBOLL2001"
    $FontGame = Get-FittedFont -Gfx $Gfx -Text $GameLabel -FontFamily "Consolas" -MaxSize 17 -MinSize 12 -MaxWidth 470
    $Gfx.DrawString($GameLabel, $FontGame, $BrushSkimYellow, (New-Object System.Drawing.RectangleF(770, $BarY, 490, $BarH)), $FormatRight)

    $Bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $Gfx.Dispose()
    $Bmp.Dispose()
}

switch ($Acao) {
    "ListarAgenda" {
        if (Test-Path $AgendaPath) {
            Get-Content $AgendaPath -Raw -Encoding UTF8 | ConvertFrom-Json | Format-Table videoId, status, publishAt, titulo -AutoSize
        } else {
            Write-Host "Nenhum video registrado em agenda-publicacoes.json ainda." -ForegroundColor Yellow
        }
        return
    }

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
        New-MatchThumbnail -Profile $Profile -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -OutPath $ArquivoThumb -ActionImgPath $ImagemLance -ScoreboardImgPath $ImagemPlacar -CustomBarText $TextoBarraCustom
        $Seo = Build-MatchSeoData -Profile $Profile -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -Rom $VersaoRom -CustomTitle $TituloCustom -ExtraNote $NotaExtra
        $DescPath = Join-Path $PSScriptRoot "..\descricao-video.txt"
        [System.IO.File]::WriteAllText($DescPath, $Seo.Descricao, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host "Thumbnail ($($Profile.NomeCompleto)) gerada em: $ArquivoThumb" -ForegroundColor Green
        Write-Host "Titulo SEO: $($Seo.Titulo)" -ForegroundColor Cyan
        return
    }

    "GerarModelosJogos" {
        New-Item -ItemType Directory -Force -Path $ThumbsDir | Out-Null

        $P1 = Get-GameProfile -InputJogo "ISSD" -InputAno "" -InputRom "" -VideoFileName ""
        $OutIssd = Join-Path $ThumbsDir "modelo-thumb-ISSD.png"
        New-MatchThumbnail -Profile $P1 -T1 "Alemanha" -T2 "Japão" -G1 3 -G2 0 -Modo "International Cup Deluxe" -OutPath $OutIssd
        Copy-Item $OutIssd (Join-Path $ThumbsDir "thumb-ultima-partida.png") -Force

        $P2 = Get-GameProfile -InputJogo "eFootball" -InputAno "" -InputRom "" -VideoFileName ""
        $OutEf = Join-Path $ThumbsDir "modelo-thumb-eFootball.png"
        New-MatchThumbnail -Profile $P2 -T1 "Brasil" -T2 "Argentina" -G1 2 -G2 1 -Modo "eFootball International Cup" -OutPath $OutEf -ActionImgPath "none" -ScoreboardImgPath "none"

        $P3 = Get-GameProfile -InputJogo "EAFC" -InputAno "" -InputRom "" -VideoFileName ""
        $OutEafc = Join-Path $ThumbsDir "modelo-thumb-EAFC.png"
        New-MatchThumbnail -Profile $P3 -T1 "Real Madrid" -T2 "Bayern" -G1 3 -G2 2 -Modo "Champions Tournament" -OutPath $OutEafc -ActionImgPath "none" -ScoreboardImgPath "none"

        $P4 = Get-GameProfile -InputJogo "FIFA" -InputAno "" -InputRom "" -VideoFileName ""
        $OutFifa = Join-Path $ThumbsDir "modelo-thumb-FIFA.png"
        New-MatchThumbnail -Profile $P4 -T1 "França" -T2 "Itália" -G1 1 -G2 0 -Modo "World Cup Classic" -OutPath $OutFifa -ActionImgPath "none" -ScoreboardImgPath "none"

        Write-Host "Todos os modelos de Thumbnails foram gerados em: $ThumbsDir" -ForegroundColor Green
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

    "DeletarVideo" {
        if (-not $VideoId) { throw "Informe -VideoId para deletar." }
        $Token = Get-AccessToken
        & curl.exe -s -S -X DELETE "https://www.googleapis.com/youtube/v3/videos?id=$VideoId" `
            -H "Authorization: Bearer $Token"
        Write-Host "Video antigo ($VideoId) removido do YouTube com sucesso!" -ForegroundColor Yellow
    }

    "AtualizarCanal" {
        $Token = Get-AccessToken
        $Canal = Invoke-RestMethod -Uri "https://www.googleapis.com/youtube/v3/channels?part=brandingSettings&mine=true" -Headers @{ Authorization = "Bearer $Token" }
        $ChannelId = $Canal.items[0].id
        $DescCanalPath = Join-Path $PSScriptRoot "..\identidade-visual\descricao-canal-youtube.txt"
        $DescCanal = [System.IO.File]::ReadAllText((Resolve-Path $DescCanalPath).Path, [System.Text.Encoding]::UTF8)

        $BodyObj = @{
            id               = $ChannelId
            brandingSettings = @{
                channel = @{
                    description     = $DescCanal
                    keywords        = '"International Superstar Soccer Deluxe" "ISS Deluxe" ISSD "Charmoso Gaucho" "Deutscher Fussball" "Campeonato Brasileiro 96" "Ronaldinho Soccer" "ISSD Extended" eFootball EAFC FIFA skimboll2001'
                    defaultLanguage = "pt_BR"
                    country         = "BR"
                }
            }
        }
        $BodyJson = $BodyObj | ConvertTo-Json -Depth 6 -Compress
        $TempChFile = Join-Path $PSScriptRoot "..\.secrets\temp-channel.json"
        [System.IO.File]::WriteAllText($TempChFile, $BodyJson, (New-Object System.Text.UTF8Encoding($false)))

        $ResChFile = Join-Path $PSScriptRoot "..\.secrets\temp-channel-res.json"
        & curl.exe -s -S -X PUT "https://www.googleapis.com/youtube/v3/channels?part=brandingSettings" `
            -H "Authorization: Bearer $Token" `
            -H "Content-Type: application/json; charset=UTF-8" `
            --data-binary "@$TempChFile" `
            -o $ResChFile

        Remove-Item $TempChFile, $ResChFile -Force -ErrorAction SilentlyContinue
        Write-Host "Descricao e palavras-chave do canal Skimboll2001 atualizadas com sucesso no YouTube!" -ForegroundColor Green
    }

    "AtualizarVideo" {
        if (-not $VideoId) { throw "Informe -VideoId para atualizar." }
        $Profile = Get-GameProfile -InputJogo $Jogo -InputAno $Ano -InputRom $VersaoRom -VideoFileName $ArquivoVideo
        $Token = Get-AccessToken
        $Seo = Build-MatchSeoData -Profile $Profile -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -Rom $VersaoRom -CustomTitle $TituloCustom -ExtraNote $NotaExtra

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
            Write-Host "Gerando thumbnail 1280x720 ($($Profile.NomeCurto))..." -ForegroundColor Yellow
            New-MatchThumbnail -Profile $Profile -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -OutPath $ArquivoThumb -ActionImgPath $ImagemLance -ScoreboardImgPath $ImagemPlacar -CustomBarText $TextoBarraCustom
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
        $RawVideoFile = Resolve-TargetVideo $ArquivoVideo
        $Profile = Get-GameProfile -InputJogo $Jogo -InputAno $Ano -InputRom $VersaoRom -VideoFileName $RawVideoFile.Name

        # Otimizar automaticamente videos de baixa resolucao (ex: 256x224) para 1440p60/1080p60 Pixel-Perfect antes do upload!
        $VideoFile = Optimize-VideoForYouTube -InputVideo $RawVideoFile -TargetQuality $QualidadeUpload
        $MimeType = if ($VideoFile.Extension -match "(?i)mp4") { "video/mp4" } else { "video/x-matroska" }

        if ($AgendarProximoSlot -and -not $DataPublicacao) {
            $DataPublicacao = Get-NextScheduleSlot
        }

        $Token = Get-AccessToken
        $Canal = Invoke-RestMethod -Uri "https://www.googleapis.com/youtube/v3/channels?part=snippet&mine=true" -Headers @{ Authorization = "Bearer $Token" }
        Write-Host "Publicando ($($Profile.NomeCompleto)) no canal: $($Canal.items[0].snippet.title) ($($Canal.items[0].id))" -ForegroundColor Cyan

        $Seo = Build-MatchSeoData -Profile $Profile -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -Rom $VersaoRom -CustomTitle $TituloCustom -ExtraNote $NotaExtra

        $DescPath = Join-Path $PSScriptRoot "..\descricao-video.txt"
        [System.IO.File]::WriteAllText($DescPath, $Seo.Descricao, (New-Object System.Text.UTF8Encoding($false)))

        $StatusObj = @{
            selfDeclaredMadeForKids = $false
        }
        if ($DataPublicacao) {
            # Para agendamento no YouTube Data API v3, privacyStatus DEVE ser "private" + publishAt (ISO 8601)
            $StatusObj["privacyStatus"] = "private"
            $StatusObj["publishAt"]     = $DataPublicacao
            Write-Host "Agendando publicacao automatica no YouTube para: $DataPublicacao" -ForegroundColor Magenta
        } else {
            $StatusObj["privacyStatus"] = $Privacidade
        }

        $MetadataObj = @{
            snippet = @{
                title                = $Seo.Titulo
                description          = $Seo.Descricao
                tags                 = $Seo.Tags
                categoryId           = "20"
                defaultLanguage      = "pt-BR"
                defaultAudioLanguage = "pt-BR"
            }
            status  = $StatusObj
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
            -H "X-Upload-Content-Type: $MimeType" `
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
        & curl.exe -g -s -S -X PUT $UploadUrl `
            -H "Authorization: Bearer $Token" `
            -H "Content-Type: $MimeType" `
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
            Write-Host "3/3 Gerando thumbnail automatica ($($Profile.NomeCurto))..." -ForegroundColor Yellow
            New-MatchThumbnail -Profile $Profile -T1 $Time1 -T2 $Time2 -G1 $Gols1 -G2 $Gols2 -Modo $ModoJogo -OutPath $ArquivoThumb -ActionImgPath $ImagemLance -ScoreboardImgPath $ImagemPlacar -CustomBarText $TextoBarraCustom
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

        $StatusFinal = if ($DataPublicacao) { "scheduled ($DataPublicacao)" } else { $Privacidade }
        Save-AgendaEntry -VideoId $VideoResp.id -Titulo $Seo.Titulo -Arquivo $VideoFile.Name -Status $StatusFinal -PublishAt $DataPublicacao

        Write-Host "======================================================" -ForegroundColor Green
        Write-Host "VIDEO ENVIADO COM SUCESSO!" -ForegroundColor Green
        Write-Host "Canal    : $($Canal.items[0].snippet.title)" -ForegroundColor Cyan
        Write-Host "Titulo   : $($Seo.Titulo)" -ForegroundColor White
        Write-Host "Status   : $StatusFinal" -ForegroundColor Yellow
        Write-Host "ID       : $($VideoResp.id)" -ForegroundColor White
        Write-Host "Link     : https://youtu.be/$($VideoResp.id)" -ForegroundColor Cyan
        Write-Host "Studio   : https://studio.youtube.com/video/$($VideoResp.id)/edit" -ForegroundColor Yellow
        Write-Host "======================================================" -ForegroundColor Green
    }
}
