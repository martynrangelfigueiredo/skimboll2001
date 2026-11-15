---
name: identidade-visual-skimboll
description: >-
  Use esta skill quando o usuário pedir para criar, editar ou ajustar thumbnails,
  logos, banners, overlays ou elementos gráficos do canal Skimboll2001. Define
  as cores exatas (#D21D1D e #F4E600), a Logo Oficial (20 ▽S 01 SKIMBOLL), o
  layout estilo ninjaissd / Angelo Salles e a proibição de citar Nintendo/Konami.
---

# Identidade Visual e Thumbnails — Canal Skimboll2001

## 1. Logo Oficial e Paleta de Cores
- **Arquivo Mestre da Logo:** [logo-oficial-skimboll2001.png](file:///c:/Users/marty/skimboll2001/identidade-visual/01-logos-e-avatar/logo-oficial-skimboll2001.png)
- **Elementos da Logo Oficial:**
  - Fundo Vermelho Vivo (`#D21D1D`) com faixa inferior em Vermelho Escuro (`#B41919`).
  - Moldura fina em Amarelo (`#F4E600`) com **`20`** no canto superior esquerdo e **`01`** no canto superior direito.
  - **Triângulo Invertido Amarelo (`▽`)** centralizado no topo com a letra **`S`** dentro.
  - Título **`SKIMBOLL`** em amarelo abaixo do triângulo.
  - Assinatura multilíngue em 4 linhas:
    1. `Skimboll desde 2001`
    2. `Skimboll seit 2001`
    3. `Skimboll since 2001`
    4. `Skimboll 自 2001 年`

## 2. Estrutura Obrigatória das Thumbnails (`1280×720` PNG)
Inspirada nos canais de torneios de ISSD (**`ninjaissd`** e **`Angelo Salles` / *International Cup Deluxe Tournaments***):
1. **Esquerda (`X=12..816, Y=12..558`):**
   - Imagem real da partida em andamento (`lance_partida.png`), renderizada com `NearestNeighbor` (Pixel-Perfect) para jogos 16-bit (`ISSD` e ROMHACKs) ou `HighQualityBicubic` para jogos HD (`eFootball`, `EAFC`, `FIFA`).
   - **Nunca coloque selos no canto superior esquerdo** sobre a imagem da partida para não cobrir as bandeiras e o placar in-game.
2. **Direita Superior (`X=828..1260, Y=14..192`):**
   - Logo Oficial `logo-oficial-skimboll2001.png`.
3. **Direita Central (`X=828..1260, Y=196..234`):**
   - Faixa identificando o jogo ou ROMHACK (ex: `★ ISS DELUXE • 16-BIT ★`, `★ ISSD CHARMOSO GAUCHAO ★`, `★ eFOOTBALL ★`, `★ EA SPORTS FC ★`, `★ FIFA ★`) — **sem mencionar Nintendo/SNES ou Konami**.
4. **Direita Inferior (`X=828..1260, Y=238..552`):**
   - Imagem real do **Placar Final In-Game** extraída dos últimos segundos do vídeo (`final_menos_10s.png`).
5. **Barra Inferior de Torneio (`Y=560..708`):**
   - Emblema `▽S` à esquerda + **`<TIME 1>  [ GOLS 1 x GOLS 2 ]  <TIME 2>`** + Subtítulo da ROMHACK/Torneio e lema multilíngue.

## 3. Como Gerar ou Atualizar as Thumbnails
- Para gerar a thumbnail de uma partida específica:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 -Acao GerarThumb -Jogo "ISSD Campeonato Brasileiro" -Ano "96" -Time1 "Grêmio" -Time2 "Palmeiras" -Gols1 2 -Gols2 1
  ```
- Para regenerar os 4 modelos base (`ISSD`, `eFootball`, `EAFC`, `FIFA`):
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\youtube.ps1 -Acao GerarModelosJogos
  ```
