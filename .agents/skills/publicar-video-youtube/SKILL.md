---
name: publicar-video-youtube
description: >-
  Use esta skill sempre que o usuário pedir para postar, subir, agendar, atualizar ou
  preparar vídeos de gameplay no YouTube para o canal Skimboll2001 (ISSD,
  ROMHACKs de ISSD, eFootball, EAFC ou FIFA). Ensina como extrair o placar dos
  últimos segundos do vídeo, identificar a ROMHACK, gerar a thumbnail e publicar
  ou agendar nos horários fixos (06:00 e 17:30) sem mencionar Nintendo ou Konami.
---

# Publicar e Agendar Vídeos no YouTube — Canal Skimboll2001

Siga este procedimento passo a passo sempre que o usuário colocar vídeos novos no repositório ou pedir para postar/agendar partidas no YouTube.

## ⚠️ Regra de Ouro (Restrição de Marcas)
**JAMAIS** escreva `Nintendo`, `Super Nintendo`, `SNES`, `Super Famicom` ou `Konami` no título, na descrição, nas tags, nas hashtags ou na thumbnail.

## 🎬 Qualidade Máxima Automática (`1440p60` 2K Pixel-Perfect)
- Gravações brutas de emuladores 16-bit costumam vir em `256x224`, o que faria o YouTube travar o vídeo em `240p` borrado.
- O `scripts/youtube.ps1` possui a função `Optimize-VideoForYouTube` (ativa por padrão com `-QualidadeUpload "1440p"`), que detecta vídeos abaixo de `1080p` e faz o **upscale automático para `2560x1440` a 60fps (`1440p60` 2K)** usando `scale=2560:1440:flags=neighbor` (Nearest-Neighbor Pixel-Perfect, mantendo cada pixel 100% nítido sem borrar) e aceleração de hardware (`h264_qsv`), forçando o codec **VP9** de alta taxa de bits no YouTube.

## ⏰ Regra de Agendamento (06:00 e 17:30)
- A agenda oficial do canal publica vídeos sempre às **06:00** e às **17:30** (horário de Brasília `-03:00`).
- O agendamento é feito nativamente na API do YouTube (`status.privacyStatus = "private"` + `status.publishAt = "YYYY-MM-DDTHH:mm:ss-03:00"`), de modo que o próprio YouTube libera o vídeo no horário exato mesmo com o computador desligado.
- Para agendar automaticamente no próximo slot livre (`06:00` ou `17:30`) após o último vídeo agendado em `agenda-publicacoes.json`, basta passar a flag `-AgendarProximoSlot` (ou `-DataPublicacao "YYYY-MM-DDTHH:mm:ss-03:00"`).

## Passo 1: Localizar o Vídeo e Extrair os Quadros Finais (`ffmpeg`)
1. Se o usuário deixou o arquivo `.mkv` ou `.mp4` na raiz do projeto, mova-o para a pasta `videos/`.
2. Extraia os quadros da partida e os últimos segundos do vídeo (onde aparece o placar final):
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 -Acao ExtrairFrames -ArquivoVideo ".\videos\nome-do-video.mkv"
   ```

## Passo 2: Ler o Placar Final, Criar a Thumbnail Box-Art 16-Bit e Falar Sobre as Equipes
1. Use `read_file` para visualizar as imagens geradas em `.secrets/frames/`:
   - Veja `final_menos_8s.png`, `final_menos_5s.png` ou `final_menos_10s.png` para ler o **Placar Final**, estatísticas e autores dos gols.
   - Veja `lance_partida.png` para conferir o visual do campo e o HUD da partida.
2. Identifique qual jogo ou **ROMHACK** está sendo jogado consultando o [Catálogo de Jogos e ROMHACKs](./references/catalogo-jogos-e-roms.md).
3. **Thumbnail Box-Art 16-Bit:** Gere sempre a thumbnail personalizada no estilo **Box-Art 16-Bit** de acordo com o jogo e as equipes da partida (usando o subagente `image-generator` quando houver nova combinação de jogo/equipes e compondo o placar final e o quadro in-game via `-Acao GerarThumb` no `scripts/youtube.ps1`).
4. **Falar Sempre Sobre as Equipes:** Adicione os perfis das equipes em `$IssdTeamProfiles` / `$IssdTeamKeywords` no `scripts/youtube.ps1` (ou passe `-SobreEquipes`) e **sempre fale sobre a história, tradição, estádio, cores e curiosidades das duas equipes** na descrição do vídeo e na resposta ao usuário.

## Passo 3: Publicar Imediatamente ou Agendar no Próximo Slot (06:00 / 17:30)
- **Para postar imediatamente (`public`):**
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 `
    -Acao PostarVideo `
    -ArquivoVideo ".\videos\partida.mkv" `
    -Jogo "ISSD Champions League" -Ano "2026" `
    -Time1 "Borussia Dortmund" -Time2 "Bayern de Munique" -Gols1 0 -Gols2 0 `
    -Privacidade "public"
  ```
- **Para agendar no próximo horário disponível (`06:00` ou `17:30`):**
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 `
    -Acao PostarVideo `
    -ArquivoVideo ".\videos\partida.mkv" `
    -Jogo "ISSD Ronaldinho Soccer" -Ano "99" `
    -Time1 "Brasil 99" -Time2 "França 98" -Gols1 1 -Gols2 0 `
    -AgendarProximoSlot
  ```

## Passo 4: Validar Agenda e Fazer Commit/Push
1. Confira a fila agendada com:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 -Acao ListarAgenda
   ```
2. Faça `git add`, `git commit` e `git push` das atualizações em `agenda-publicacoes.json` e templates.
