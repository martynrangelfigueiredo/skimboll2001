# 🚩▽S skimboll2001 — Repositório Oficial do Canal

Repositório de automação, identidade visual e publicação de vídeos via YouTube Data API v3 do canal **[Skimboll2001](https://www.youtube.com/@skimboll2001)** (`UCR1UuLEs-n55oz85e7Lc5gg`).

- **Lema Oficial:** *Skimboll desde 2001 • Skimboll seit 2001 • Skimboll since 2001 • Skimboll 自 2001 年*
- **Jogos do Canal:**
  1. **`ISSD`** — *International Superstar Soccer Deluxe* (SNES) & Hacks/Torneios (*NINJAISSD*, *Angelo Salles International Cup Deluxe Tournaments*, *Club World Cup Deluxe*, *Ronaldinho Soccer 97*, *Campeonato Brasileiro 96*).
  2. **`eFootball`** — Konami *eFootball* (Partidas, Torneios e Dream Team).
  3. **`EAFC`** — *EA Sports FC* (EA FC 24, 25, 26, Torneios e Ultimate Team).
  4. **`FIFA`** — Edições clássicas e modernas de *FIFA*.

---

## 🖼️ Como Funcionam as Novas Thumbnails Automáticas (`1280×720` PNG)

Inspiradas no estilo de canais de torneios de ISSD (**`ninjaissd`** e **`Angelo Salles` / *International Cup Deluxe Tournaments***):

1. **Lado Esquerdo (`804×546`):** Exibe a **imagem real da partida em campo** extraída do vídeo (com filtro *NearestNeighbor Pixel-Perfect* no SNES para manter os pixels nítidos e **sem tampar as bandeiras superiores do jogo**).
2. **Topo Direito (`432×178`):** Exibe a **Logo Oficial do Canal (`logo-oficial-skimboll2001.png` — `20 ▽S 01 SKIMBOLL`)**.
3. **Centro-Direito (`432×314`):** Exibe o **Placar Final In-Game real** extraído dos últimos segundos do vídeo (mostrando bandeiras, estatísticas de chutes/faltas e autores dos gols).
4. **Barra Inferior de Torneio (`1256×148`):** Emblema `▽S` + **`<TIME 1>  [ GOLS 1 x GOLS 2 ]  <TIME 2>`** + Subtítulo do jogo/torneio.

---

## 📁 Estrutura do Projeto

```text
skimboll2001/
├── videos/                              # Coloque os vídeos (.mkv / .mp4) aqui (ignorados no Git)
├── identidade-visual/                   # Identidade visual completa baseada na Logo Oficial
│   ├── 01-logos-e-avatar/               # logo-oficial-skimboll2001.png + avatar-skimboll2001.svg
│   ├── 02-banners-youtube/              # Banner 2560x1440 com área segura 1546x423 (SVG)
│   ├── 03-thumbnails-templates/         # Modelos prontos: ISSD, eFootball, EAFC e FIFA (PNG)
│   ├── 04-paleta-e-fontes/              # Paleta oficial (#D21D1D / #F4E600) e presets por jogo
│   ├── 05-intros-outros-overlays/       # Bezel 1920x1080 para tela 4:3 do SNES com a logo oficial
│   └── README.md                        # Guia detalhado da identidade visual
├── scripts/
│   └── youtube.ps1                      # Automação multi-jogos (ISSD, eFootball, EAFC, FIFA)
├── .secrets/                            # Cofre criptografado DPAPI e frames temporários (NUNCA versionado)
├── descricao-video.txt                  # Última descrição SEO gerada automaticamente
└── README.md                            # Este guia geral de uso e comandos
```

---

## 🛠️ Comandos Principais (`scripts/youtube.ps1`)

### 1. Extrair os quadros da partida e o placar final dos últimos segundos do vídeo
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 -Acao ExtrairFrames
```

### 2. Postar um vídeo (ISSD, eFootball, EAFC ou FIFA)
*(Se `-Jogo` não for informado, o script detecta pelo nome do arquivo ou usa `ISSD` como padrão)*
```powershell
# Exemplo ISS Deluxe (SNES):
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 `
  -Acao PostarVideo `
  -Jogo "ISSD" `
  -Time1 "Alemanha" -Time2 "Japão" -Gols1 3 -Gols2 0 `
  -ModoJogo "International Cup Deluxe"

# Exemplo eFootball:
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 `
  -Acao PostarVideo `
  -Jogo "eFootball" `
  -Time1 "Brasil" -Time2 "Argentina" -Gols1 2 -Gols2 1 `
  -ModoJogo "eFootball International Cup"

# Exemplo EA Sports FC (EAFC):
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 `
  -Acao PostarVideo `
  -Jogo "EAFC" `
  -Time1 "Real Madrid" -Time2 "Bayern" -Gols1 3 -Gols2 2 `
  -ModoJogo "Champions League"

# Exemplo FIFA:
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 `
  -Acao PostarVideo `
  -Jogo "FIFA" `
  -Time1 "França" -Time2 "Itália" -Gols1 1 -Gols2 0 `
  -ModoJogo "World Cup"
```

### 3. Atualizar vídeo já publicado no YouTube (Título, SEO, Hashtags e Thumbnail)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 `
  -Acao AtualizarVideo `
  -VideoId "P8OxxFqfObs" `
  -Jogo "ISSD" `
  -Time1 "Alemanha" -Time2 "Japão" -Gols1 3 -Gols2 0 `
  -ModoJogo "International Cup Deluxe"
```

### 4. Gerar todos os 4 modelos de Thumbnail (`ISSD`, `eFootball`, `EAFC`, `FIFA`)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 -Acao GerarModelosJogos
```
