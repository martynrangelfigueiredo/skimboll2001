# Regras Globais do Repositório — Canal Skimboll2001 (`AGENTS.md`)

Este repositório gerencia a identidade visual, a geração automática de thumbnails (`1280×720`) e a publicação automatizada de vídeos no YouTube para o canal **Skimboll2001** (`UCR1UuLEs-n55oz85e7Lc5gg`).

## 🚫 1. RESTRIÇÃO ABSOLUTA DE MARCAS (OBRIGATÓRIO)
- **NUNCA utilize ou escreva** as palavras **`Nintendo`**, **`Super Nintendo`**, **`SNES`**, **`Super Famicom`** ou **`Konami`** em títulos, descrições, tags, hashtags, miniaturas (thumbnails), banners, overlays ou documentação.
- Para referenciar o estilo retrô ou o jogo clássico, utilize exclusivamente termos como **`ISSD`**, **`International Superstar Soccer Deluxe`**, **`16-Bit`**, **`Futebol Retrô`** ou o nome específico da **ROMHACK**.

## 🤖 2. SKILLS DISPONÍVEIS NESTE REPOSITÓRIO
Sempre consulte as skills em `.agents/skills/` ao executar tarefas:
- [publicar-video-youtube](file:///c:/Users/marty/skimboll2001/.agents/skills/publicar-video-youtube/SKILL.md): Procedimento completo para extrair o placar dos últimos segundos do vídeo, identificar a versão/ROMHACK, gerar a thumbnail, montar o SEO e publicar no YouTube.
- [identidade-visual-skimboll](file:///c:/Users/marty/skimboll2001/.agents/skills/identidade-visual-skimboll/SKILL.md): Diretrizes da Logo Oficial (`20 ▽S 01 SKIMBOLL`), cores (`#D21D1D` e `#F4E600`) e layout de thumbnails estilo *ninjaissd* / *Angelo Salles International Cup Deluxe*.

## 🎮 3. CATÁLOGO DE JOGOS E ROMHACKS DO CANAL
O canal publica partidas completas dos seguintes jogos (suportados nativamente por `scripts/youtube.ps1`):
- **ISSD Clássico e ROMHACKs:**
  - `ISSD` (*International Superstar Soccer Deluxe* normal)
  - `ISSD Charmoso Gauchão - ANO` (Campeonato Gaúcho ROMHACK)
  - `ISSD Deutscher Fussball - ANO` (Campeonato Alemão ROMHACK)
  - `ISSD Champions League - ANO` (Champions League ROMHACK)
  - `ISSD Mundial de Clubes - ANO` (Mundial de Clubes ROMHACK)
  - `ISSD Campeonato Brasileiro 95`, `96`, `97`, `98`, `99`
  - `ISSD Futebol Brasileiro 95`, `96`, `97`, `98`, `99`
  - `ISSD Ronaldinho Soccer - ANO`
  - `ISSD Extended Brasil Popular - ANO` (Campeonato Brasileiro com muitos times ROMHACK)
  - `ISSD Extended` (jogo normal com mais seleções atualizadas)
  - `ISSD Extended - ANO` (jogo extended com as escalações atualizadas do ano)
- **Outros Jogos de Futebol:**
  - `eFootball`
  - `EAFC` (*EA Sports FC*)
  - `FIFA`

## 🔄 4. FLUXO DE TRABALHO, THUMBNAIL 16-BIT, HISTÓRIA DAS EQUIPES, AGENDA (06:00 / 17:30) E GIT (OBRIGATÓRIO)
1. **Detecção Automática nos Últimos Segundos:** Quando o usuário colocar vídeos em `videos/` e pedir para postar ou agendar, **não pergunte qual foi a partida nem o placar**. Execute `-Acao ExtrairFrames` no `scripts/youtube.ps1` e leia as imagens geradas em `.secrets/frames/` para identificar os dois times, a ROMHACK e o placar final.
2. **Thumbnail Estilo Box-Art 16-Bit Sempre Criada por Jogo/Partida:** Gere sempre a thumbnail (`1280×720`) no estilo **Box-Art 16-Bit** de acordo com o jogo e as equipes da partida, com o placar final em destaque na barra inferior e o quadro in-game do placar final.
3. **Falar Sempre Sobre as Equipes em Campo:** Em toda publicação (tanto na descrição do vídeo no YouTube via `scripts/youtube.ps1` quanto na resposta ao usuário), apresente sempre um resumo sobre as duas equipes que jogam (história, cidade/região, estádio, cores tradicionais, apelidos e destaques na partida).
4. **Agenda Fixa de Publicação (06:00 e 17:30):** O canal publica vídeos sempre às **06:00** e às **17:30** (`-03:00`). Use a flag `-AgendarProximoSlot` (ou `-DataPublicacao "YYYY-MM-DDTHH:mm:ss-03:00"`) no `scripts/youtube.ps1` para agendar diretamente na API do YouTube (`publishAt`) e registrar em `agenda-publicacoes.json`.
5. **Vídeos Fora do Git:** Todos os vídeos (`.mkv`, `.mp4`) devem ficar em `videos/` e permanecer no `.gitignore`.
6. **Commit & Push Sempre:** Após qualquer alteração em scripts, documentação, `agenda-publicacoes.json` ou templates, faça sempre `git add`, `git commit` e `git push`.
