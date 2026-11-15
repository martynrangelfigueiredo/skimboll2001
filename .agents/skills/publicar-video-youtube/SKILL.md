---
name: publicar-video-youtube
description: >-
  Use esta skill sempre que o usuário pedir para postar, subir, atualizar ou
  preparar um vídeo de gameplay no YouTube para o canal Skimboll2001 (ISSD,
  ROMHACKs de ISSD, eFootball, EAFC ou FIFA). Ensina como extrair o placar dos
  últimos segundos do vídeo, identificar a ROMHACK, gerar a thumbnail e publicar
  sem mencionar Nintendo ou Konami.
---

# Publicar Vídeo no YouTube — Canal Skimboll2001

Siga este procedimento passo a passo sempre que o usuário colocar um vídeo novo no repositório ou pedir para postar/atualizar uma partida no YouTube.

## ⚠️ Regra de Ouro (Restrição de Marcas)
**JAMAIS** escreva `Nintendo`, `Super Nintendo`, `SNES`, `Super Famicom` ou `Konami` no título, na descrição, nas tags, nas hashtags ou na thumbnail.

## Passo 1: Localizar o Vídeo e Extrair os Quadros Finais (`ffmpeg`)
1. Se o usuário deixou o arquivo `.mkv` ou `.mp4` na raiz do projeto, mova-o para a pasta `videos/`:
   ```powershell
   Move-Item -Path ".\*.mkv", ".\*.mp4" -Destination ".\videos\" -Force -ErrorAction SilentlyContinue
   ```
2. Extraia automaticamente os quadros da partida e os últimos segundos do vídeo (onde aparece o placar final):
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 -Acao ExtrairFrames
   ```

## Passo 2: Ler o Placar Final e Identificar os Times e o Jogo
1. Use a ferramenta `read_file` para visualizar as imagens geradas em `.secrets/frames/`:
   - Veja `final_menos_10s.png`, `final_menos_6s.png` ou `final_menos_3s.png` para ler o **Placar Final** (ex: `GERMANY 3 - 0 JAPAN`) e estatísticas.
   - Veja `lance_partida.png` (ou `lance_120s.png` / `lance_540s.png`) para conferir o visual do campo e o HUD da partida.
2. Identifique qual jogo ou **ROMHACK** está sendo jogado consultando o [Catálogo de Jogos e ROMHACKs](./references/catalogo-jogos-e-roms.md).
3. Traduza os nomes das seleções para o português no título e na descrição (ex: `Germany` → `Alemanha`, `Japan` → `Japão`), mantendo os termos em inglês no bloco de SEO.

## Passo 3: Publicar (ou Atualizar) o Vídeo via API
Execute `scripts/youtube.ps1` passando `-Jogo`, `-Ano` (se aplicável à ROMHACK), `-Time1`, `-Time2`, `-Gols1` e `-Gols2`:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 `
  -Acao PostarVideo `
  -Jogo "ISSD" `
  -Ano "" `
  -Time1 "Alemanha" `
  -Time2 "Japão" `
  -Gols1 3 `
  -Gols2 0 `
  -ModoJogo "International Cup Deluxe" `
  -Privacidade "public"
```
*(Nota: Para o envio à internet via API do YouTube, execute o comando com `BypassSandbox: true` caso o modo sandbox bloqueie a resolução DNS de `oauth2.googleapis.com`).*

## Passo 4: Validar e Fazer Commit/Push
1. Verifique se o script retornou `VIDEO PUBLICADO COM SUCESSO!` com o link `https://youtu.be/<ID>` e `Thumbnail aplicada com sucesso!`.
2. Faça `git add`, `git commit` e `git push` de quaisquer atualizações nos templates ou metadados (garantindo que `videos/` e `.secrets/` continuem fora do Git).
