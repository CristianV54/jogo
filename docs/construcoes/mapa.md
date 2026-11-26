# Peça: o MAPA DO MUNDO (tecla M)

Código: `scripts/interface/pintura_do_mapa.gd` (a pintura de base) e `scripts/interface/mapa_do_mundo.gd` (o que é traçado por cima).

## Por que mudou (26/11/2026)

O usuário achou o mapa "muito ruim" e pediu visual de jogo. O que a pesquisa trouxe (críticas e uma resenha de cartógrafos sobre mapas de jogos de mundo aberto): o defeito mais comum é o ENTULHO (ícones e nomes demais); os mapas elogiados mostram primeiro o relevo e os nomes grandes e deixam o detalhe para quando se aproxima, com poucos ícones.

## Como ficou

- Base com as cores do chão do jogo, RELEVO sombreado (a montanha e o penhasco aparecem), mata em mancha escura com a árvore por cima, praia clara e mar em três fundos.
- De longe: só Valdoria (castelo), as 6 regiões (escudo), a Montanha dos Dragões e os ícones das vilas, sem nome. Os nomes das vilas e os ícones de fazenda, posto, pescador e cabana aparecem ao aproximar (zoom 1,7); os nomes dos pequenos, com zoom 3.
- Estradas claras com borda, rios azuis, letra clara com contorno escuro, seta amarela do Torin com anel, alfinete vermelho do destino, faixa de cima com o lugar onde se está e a ajuda, faixa de baixo com a legenda e a distância ao destino.
- Fotos em `docs/construcoes/mapa/` (inteiro, com destino, zoom 4x). Só fotografado; o teste do mundo não foi rodado de novo depois desta mudança (ela só toca o desenho do mapa).

## Pontos fracos anotados

- Dois nomes de região se encostam no sul (Refúgio do Pinhal e Acampamento da Ruptura).
- O mapa mostra tudo desde o começo: não há "descobrir" regiões.
- Não há minimapa durante o jogo.
