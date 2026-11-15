# Regras do Projeto skimboll2001

1. **PROIBIDO citar Nintendo ou Konami:** Nunca inclua `Nintendo`, `Super Nintendo`, `SNES`, `Super Famicom` ou `Konami` em títulos, descrições, tags, hashtags, miniaturas ou documentação. Use `ISSD`, `International Superstar Soccer Deluxe`, `16-Bit` ou o nome da ROMHACK.
2. **Sempre commitar e fazer push:** Após realizar alterações em arquivos, scripts, documentação ou identidade visual do repositório, faça sempre `git add`, `git commit` e `git push`.
3. **Vídeos na pasta `videos/` e fora do Git:** Todos os vídeos de gameplay (`.mkv`, `.mp4`, etc.) devem ficar na pasta `videos/` e estar bloqueados no `.gitignore` para nunca ocuparem espaço no GitHub.
4. **Detecção automática da partida nos últimos segundos:** O placar final aparece nos últimos segundos do vídeo. Sempre extraia os frames finais (`powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 -Acao ExtrairFrames`) e leia as imagens geradas em `.secrets/frames/` para descobrir automaticamente as duas equipes, a versão/ROMHACK e o placar final sem precisar perguntar ao usuário.
5. **Padrão de Publicação YouTube (`Skimboll2001`):**
   - Sempre gerar e aplicar uma Thumbnail `1280x720` PNG usando o lance real em campo + placar final in-game + Logo Oficial (`20 ▽S 01 SKIMBOLL`);
   - Incluir a partida e o resultado no título e na descrição;
   - Incluir pedido e link direto de inscrição (`?sub_confirmation=1`);
   - Focar em palavras-chave de SEO e hashtags dinâmicas da partida, sem textos longos de enrolação.
