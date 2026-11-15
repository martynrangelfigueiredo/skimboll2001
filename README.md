# 🚩▽S skimboll2001 — Repositório Oficial do Canal

Repositório de automação, identidade visual, **AI Skills** e publicação de vídeos via YouTube Data API v3 do canal **[Skimboll2001](https://www.youtube.com/@skimboll2001)** (`UCR1UuLEs-n55oz85e7Lc5gg`).

- **Lema Oficial:** *Skimboll desde 2001 • Skimboll seit 2001 • Skimboll since 2001 • Skimboll 自 2001 年*
- **Restrição Importante:** Nenhuma arte, título, descrição ou tag deve referenciar *Nintendo* ou *Konami*.

---

## 🤖 Otimizado para Agentes de IA (`AGENTS.md` & `.agents/skills/`)

Qualquer agente de IA que abrir este repositório encontrará instruções estruturadas automaticamente:
- **[AGENTS.md](file:///c:/Users/marty/skimboll2001/AGENTS.md):** Regras globais sempre ativas (restrições de marca, catálogo de ROMHACKs e fluxo de commit/push).
- **Skill [publicar-video-youtube](file:///c:/Users/marty/skimboll2001/.agents/skills/publicar-video-youtube/SKILL.md):** Passo a passo para extrair os últimos segundos do vídeo via `ffmpeg`, ler o placar final na imagem, identificar a ROMHACK e publicar na API.
  - Inclui o [Catálogo Completo de Jogos e ROMHACKs](file:///c:/Users/marty/skimboll2001/.agents/skills/publicar-video-youtube/references/catalogo-jogos-e-roms.md).
- **Skill [identidade-visual-skimboll](file:///c:/Users/marty/skimboll2001/.agents/skills/identidade-visual-skimboll/SKILL.md):** Especificações da Logo Oficial (`20 ▽S 01 SKIMBOLL`) e do gerador de thumbnails (`1280×720`).

---

## 🎮 Catálogo de Jogos e ROMHACKs Suportados

### Linha ISSD (*International Superstar Soccer Deluxe* & ROMHACKs)
- **`ISSD`** — *International Superstar Soccer Deluxe* (normal)
- **`ISSD Charmoso Gauchão - ANO`** — Campeonato Gaúcho ROMHACK
- **`ISSD Deutscher Fussball - ANO`** — Campeonato Alemão ROMHACK
- **`ISSD Champions League - ANO`** — Champions League ROMHACK
- **`ISSD Mundial de Clubes - ANO`** — Mundial de Clubes ROMHACK
- **`ISSD Campeonato Brasileiro 95, 96, 97, 98, 99`**
- **`ISSD Futebol Brasileiro 95, 96, 97, 98, 99`**
- **`ISSD Ronaldinho Soccer - ANO`**
- **`ISSD Extended Brasil Popular - ANO`** — Campeonato Brasileiro com muitos times ROMHACK
- **`ISSD Extended`** — Jogo normal com mais seleções atualizadas
- **`ISSD Extended - ANO`** — Jogo extended com as escalações atualizadas do ano

### Outros Jogos de Futebol
- **`eFootball`**
- **`EAFC`** (*EA Sports FC*)
- **`FIFA`**

---

## 🛠️ Comandos Principais (`scripts/youtube.ps1`)

### 1. Extrair os quadros da partida e o placar final dos últimos segundos do vídeo
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 -Acao ExtrairFrames
```

### 2. Postar um vídeo (qualquer variação de ISSD, ROMHACK, eFootball, EAFC ou FIFA)
```powershell
# Exemplo ISSD Normal:
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 `
  -Acao PostarVideo `
  -Jogo "ISSD" `
  -Time1 "Alemanha" -Time2 "Japão" -Gols1 3 -Gols2 0 `
  -ModoJogo "International Cup Deluxe"

# Exemplo ISSD Charmoso Gauchão (com Ano):
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 `
  -Acao PostarVideo `
  -Jogo "ISSD Charmoso Gauchão" -Ano "2025" `
  -Time1 "Grêmio" -Time2 "Internacional" -Gols1 2 -Gols2 1 `
  -ModoJogo "Campeonato Gaúcho"

# Exemplo ISSD Campeonato Brasileiro (95 a 99):
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 `
  -Acao PostarVideo `
  -Jogo "ISSD Campeonato Brasileiro" -Ano "96" `
  -Time1 "Palmeiras" -Time2 "Corinthians" -Gols1 3 -Gols2 1 `
  -ModoJogo "Brasileirão 96"

# Exemplo ISSD Extended / Brasil Popular:
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 `
  -Acao PostarVideo `
  -Jogo "ISSD Extended Brasil Popular" -Ano "2025" `
  -Time1 "Flamengo" -Time2 "Vasco" -Gols1 2 -Gols2 2

# Exemplo eFootball / EAFC / FIFA:
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 `
  -Acao PostarVideo `
  -Jogo "EAFC" -Ano "25" `
  -Time1 "Real Madrid" -Time2 "Bayern" -Gols1 3 -Gols2 2
```

### 3. Atualizar vídeo já publicado no YouTube
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 `
  -Acao AtualizarVideo `
  -VideoId "P8OxxFqfObs" `
  -Jogo "ISSD" `
  -Time1 "Alemanha" -Time2 "Japão" -Gols1 3 -Gols2 0 `
  -ModoJogo "International Cup Deluxe"
```

### 4. Regenerar todos os 4 modelos base de Thumbnail
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 -Acao GerarModelosJogos
```
