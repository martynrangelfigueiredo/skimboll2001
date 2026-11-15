# 🚩⭐ skimboll2001 — Repositório Oficial do Canal (ISS Deluxe • SNES)

Repositório de automação, identidade visual e publicação de vídeos via YouTube Data API v3 do canal **[Skimboll2001](https://www.youtube.com/@skimboll2001)** (`UCR1UuLEs-n55oz85e7Lc5gg`).

- **Foco do Canal:** Gameplays de *International Superstar Soccer Deluxe* (SNES) e suas variações/hacks clássicos (*Campeonato Brasileiro 96*, *Ronaldinho Soccer 97*, *Forte e Campeão*, etc.).
- **Estilo:** Sóbrio, divertido, sem frufru e para todas as idades e gêneros.
- **Identidade Visual:** Predominância de **Vermelho (`#B71C1C` / `#6A0B0B`)** com detalhes em **Amarelo Ouro (`#FFD600`)** (referência estética à China e URSS) aliado às caixas, placares e elementos de interface 16-bit do *ISS Deluxe* da Konami.

---

## 📁 Estrutura do Projeto

```text
skimboll2001/
├── videos/                              # Coloque os vídeos (.mkv / .mp4) aqui (ignorados no Git)
├── identidade-visual/                   # Identidade visual completa do canal
│   ├── 01-logos-e-avatar/               # Avatar 800x800 (SVG)
│   ├── 02-banners-youtube/              # Banner 2560x1440 com área segura 1546x423 (SVG)
│   ├── 03-thumbnails-templates/         # Template SVG + última thumbnail PNG gerada (1280x720)
│   ├── 04-paleta-e-fontes/              # Paleta Vermelho & Ouro e especificações (JSON)
│   ├── 05-intros-outros-overlays/       # Moldura/Bezel 1920x1080 para tela 4:3 do SNES (SVG)
│   └── README.md                        # Guia detalhado da identidade visual
├── scripts/
│   └── youtube.ps1                      # Automação de extração de frames, thumbnail, SEO e upload
├── .secrets/                            # Cofre criptografado DPAPI e frames temporários (NUNCA versionado)
├── descricao-video.txt                  # Última descrição SEO gerada automaticamente
└── README.md                            # Este guia geral de uso e comandos
```

---

## 🔐 Segurança das Chaves do YouTube (Windows DPAPI)

- Nenhum segredo (`ClientSecret` ou `RefreshToken`) fica salvo em texto puro no disco.
- As credenciais estão criptografadas com a **API de Proteção de Dados do Windows (DPAPI)** em `.secrets/youtube-vault.dpapi.xml`, vinculadas exclusivamente ao usuário local do Windows e a esta máquina.
- A pasta `.secrets/` e todos os arquivos de vídeo (`*.mkv`, `*.mp4`, `videos/*`) estão listados no `.gitignore` para nunca ocuparem espaço ou vazarem no GitHub.

---

## 🚀 Fluxo Automático para Postar um Novo Vídeo

### Como funciona a detecção automática da partida e do placar:
No *International Superstar Soccer Deluxe*, o resultado final aparece nos **últimos segundos do vídeo**.
Quando você coloca um vídeo novo na pasta `videos/` e pede ao agente para postar:
1. O comando `ExtrairFrames` usa o `ffmpeg` para capturar quadros dos últimos segundos (`-25s`, `-15s`, `-10s`, `-6s`, `-3s`, `-1s`) em `.secrets/frames/`.
2. O agente lê a imagem do placar final diretamente, identifica sozinho o **`Time 1`**, **`Time 2`** e o **`Placar Final`** (ex: `Alemanha 3 x 0 Japão`), gera a thumbnail `1280×720`, monta o título e a descrição SEO com as hashtags da partida e publica via API!

---

## 🛠️ Comandos Úteis (`scripts/youtube.ps1`)

### 1. Extrair os quadros finais do vídeo mais recente na pasta `videos/` (para ler o placar)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 -Acao ExtrairFrames
```

### 2. Postar um vídeo completo no canal `Skimboll2001` (Upload + SEO + Thumbnail Automática)
*(Se você não passar `-ArquivoVideo`, ele pega automaticamente o vídeo mais recente da pasta `videos/`)*
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 `
  -Acao PostarVideo `
  -Time1 "Alemanha" `
  -Time2 "Japão" `
  -Gols1 3 `
  -Gols2 0 `
  -ModoJogo "Partida Completa" `
  -Privacidade "public"
```

### 3. Atualizar Título, Descrição SEO, Hashtags e Thumbnail de um vídeo já publicado
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 `
  -Acao AtualizarVideo `
  -VideoId "P8OxxFqfObs" `
  -Time1 "Alemanha" `
  -Time2 "Japão" `
  -Gols1 3 `
  -Gols2 0 `
  -ModoJogo "Partida Completa"
```

### 4. Apenas gerar/testar a Thumbnail (`1280×720` PNG) e a Descrição SEO localmente
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 `
  -Acao GerarThumb `
  -Time1 "Brasil" `
  -Time2 "Itália" `
  -Gols1 2 `
  -Gols2 1
```

### 5. Verificar status do canal conectado
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 -Acao Status
```

### 6. Refazer login / Trocar conta ou canal (caso necessário no futuro)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 -Acao Login
```

---

## 📈 Padrão de SEO Automático dos Vídeos

Todo vídeo publicado pelo script inclui automaticamente:
1. **Título Padronizado:** `<Time 1> <Gols 1> x <Gols 2> <Time 2> | International Superstar Soccer Deluxe (SNES) | skimboll2001`
2. **Primeiras 2 linhas da Descrição:** Confronto + Resultado Final + Link direto de inscrição (`?sub_confirmation=1`).
3. **Palavras-Chave das Seleções:** Inclui os nomes das seleções em português/inglês e os nomes dos **craques clássicos daquelas seleções no ISS Deluxe** (ex: *Allejo, Gomez, Beranco, Kolle, Sieke, Fujimoto, Paz, Galfano, Carboni, Capitale, Redonda, Van Wijk*).
4. **Hashtags Dinâmicas da Partida:** Ex: `#AlemanhaxJapao #Alemanha #Japao #ISSDeluxe #SNES #InternationalSuperstarSoccerDeluxe #skimboll2001 #FutebolRetro #SuperNintendo #16Bit #Konami`.
5. **Thumbnail 1280×720 PNG:** Gerada automaticamente com o confronto e o placar final.
