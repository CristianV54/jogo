# Leis do jogo (Reino de Cinzas)

Regras que o jogo nunca pode quebrar, cada uma com o teste que a confere HOJE. Erro novo apontado pelo usuário vira uma lei nova aqui e um teste. Refeito em 26/11/2026: as leis da campanha antiga e do mundo em corredor saíram junto com os testes delas (o texto antigo está no histórico do git).

## O mundo

| Lei | Teste |
|---|---|
| O mundo tem 6 regiões, 32 estradas e 119 povoados, sem barreira nenhuma | `teste_mundo` |
| Todo povoado tem gente trabalhando; há fazendeiros nos campos e fauna solta | `teste_mundo` |
| Lobo e javali não nascem dentro de fazenda ou vila; ninguém nasce dentro d'água | `teste_mundo` |
| À noite e na tempestade os trabalhadores se recolhem; de manhã voltam | `teste_mundo` |
| A beirada de uma região nunca é um degrau: entra-se andando por qualquer lado | `teste_bordas` (não terminou em 10 min em 26/11: não se sabe se passa) |
| Cair do mundo não mata: o Torin volta ao último chão firme | `teste_queda` |

## Valdoria

| Lei | Teste |
|---|---|
| Muralha com 3 portões de passagem livre, 24 torres ou mais e escadas para o caminho de ronda | `teste_mundo`, bancada `muralha` |
| Dentro da muralha não há inimigo | `teste_mundo` |
| 500 casas ou mais; nenhuma em cima de rua, de outra casa ou encostada na muralha; ninguém dentro de parede | `teste_mundo`, `auditoria_reino` |
| Sobe-se a pé a rampa do penhasco até a cidadela; o rei está no Salão do Trono | `teste_mundo` |
| Quartel com soldados que são gente (não inimigos); estábulos com 4 cavalos montáveis; sentinelas nos portões | `teste_mundo` |

## Montanha dos Dragões e Terras do Gelo

| Lei | Teste |
|---|---|
| Sobe-se a pé do pé da montanha ao ninho, sem degrau maior que 0,9 m | `teste_mundo` |
| O dragão do ninho só se doma com 3 carnes e vira montaria que voa | `teste_mundo` |
| Anda-se em cima do Lago Congelado (o Torin não afunda na placa) | `teste_mundo` |

## O jogador

| Lei | Teste |
|---|---|
| A fome cai com o tempo; comida mata a fome; a zero, tira vida | `teste_mundo` |
| Equipar arma muda o dano; armadura aparece no corpo e tira dano | `teste_mundo`, bancada `armaduras` |
| Comprar custa o preço, vender rende metade, pechinchar só uma vez por visita | `teste_mundo` |
| Forjar gasta o material da receita; sem material não forja; o veio só dá ferro com picareta | `teste_mundo` |
| Salvar e carregar devolve o lugar e a bolsa | `teste_mundo` |
| Os sons carregam, os laços tocam e os efeitos saem na hora certa | `teste_mundo` (por contagem; ninguém ouviu) |
| O inventário abre com I, trava o jogador, mostra ícone e quantidade, come e equipa | `teste_inventario` |

## Criaturas e construções novas

| Lei | Como conferir |
|---|---|
| Criatura nova ou alterada é fotografada sozinha, com o Torin de régua, antes de entrar no jogo | `tools/bancada.gd`, `tools/bancada_construcao.gd -- dragoes`, `-- tubarao` |
| Peça de construção nova passa pela bancada e tem critério de pronto escrito | `tools/bancada_construcao.gd`, `docs/construcoes/<peca>.md` |

## Leis sem teste que valha hoje

| Lei | Situação |
|---|---|
| Golpe do Torin tira vida de animal e de inimigo; monta-se e desmonta-se cavalo e dragão | `teste_montaria_dano` foi feito para o mundo antigo e com janela: falha. Sem cobertura. |
| NPC dorme na própria cama à noite; NPC foge de monstro para dentro de casa | `teste_sono` e `teste_medo` falham nesses itens (podem ser defeito real). |
| O cavalo montado não atravessa parede; monstro não entra em casa | `teste_simulacao` PASSA (8 de 8). |
| As rotinas de trabalho dos NPCs | `teste_rotinas` PASSA (9 de 9). |

## Como rodar

```bash
godot --headless --path . --script res://tools/teste_mundo.gd
godot --headless --path . --script res://tools/auditoria_reino.gd
godot --headless --path . --script res://tools/<outro_teste>.gd
```

O estado de cada teste (passa, falha, não termina) em 26/11/2026 está na seção 2 de `docs/MAPA-DO-TRABALHO.md`.

## Teclas de teste (nó Admin, fora do jogo normal)

F1 a F6 teleportam às 6 regiões, F9 troca a hora, F10 o tempo, F11 liga a câmera livre (WASD, Espaço, C, Shift, mouse).
