# Regras do Projeto skimboll2001

1. **Sempre commitar e fazer push:** Após realizar alterações em arquivos, scripts, documentação ou identidade visual do repositório, faça sempre `git add`, `git commit` e `git push`.
2. **Vídeos na pasta `videos/` e fora do Git:** Todos os vídeos de gameplay (`.mkv`, `.mp4`, etc.) devem ficar na pasta `videos/` e estar bloqueados no `.gitignore` para nunca ocuparem espaço no GitHub.
3. **Detecção automática da partida nos últimos segundos:** O placar final no *International Superstar Soccer Deluxe* aparece nos últimos segundos do vídeo. Sempre extraia os frames finais (`powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 -Acao ExtrairFrames`) e leia as imagens geradas em `.secrets/frames/` para descobrir automaticamente as duas seleções e o placar final sem precisar perguntar ao usuário.
4. **Padrão de Publicação YouTube (`Skimboll2001`):**
   - Sempre gerar e aplicar uma Thumbnail `1280x720` PNG com a partida e o placar no tema Vermelho & Amarelo Ouro;
   - Incluir a partida e o resultado no título e na descrição;
   - Incluir pedido e link direto de inscrição (`?sub_confirmation=1`);
   - Focar em palavras-chave de SEO e hashtags dinâmicas da partida, sem textos longos de enrolação.
