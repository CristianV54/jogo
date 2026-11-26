# Percurso real de 24/11/2026: do Refúgio ao Castelo, em trechos

Agente `tools/percurso_real.gd` (anda de verdade com W + Shift, sem teleporte entre regiões), rodado num servidor sem placa de vídeo
(2 a 5 quadros por segundo). Por causa da lentidão o percurso **não foi feito numa rodada só**: foram 6 trechos encadeados, cada um
retomado do último ponto concluído pelo anterior (`-- retomar`, o único teleporte que o agente permite).

**Resultado: o agente chegou ao centro do Castelo Imperial, e todo o caminho do Refúgio até lá foi andado.**
O arquivo `PERCURSO_REAL.md` guarda só o último trecho (Valdoria → Castelo, PASS). Este documento conta o percurso inteiro.
Falta repetir numa rodada só, num computador com placa de vídeo (no Mac: `godot --path . --resolution 1280x720 --script res://tools/percurso_real.gd`).

## Trechos andados

| # | De → até | Resultado |
|---|---|---|
| 1 | Refúgio → portão oeste → Estrada do Pomar → Pomar Alto → volta pelo portão oeste → praça | chegou |
| 2 | Praça → oeste da casa do Vane → portão norte → Trilha do Bosque → Bosque Velado (entrada e centro) → volta à Trilha | chegou |
| 3 | Trilha → portão norte → praça → portão leste → começo da Estrada dos Campos Altos | chegou |
| 4 | Vão da barreira da Ruptura → Campos Altos → Acampamento da Ruptura → Caminho da Ruptura → entrada de Ferrogris | chegou |
| 5 | Brecha de Ferrogris → Fortaleza (centro) → Estrada Queimada → Cratera de Ignis → Estrada Imperial → Valdoria → alto da escadaria | chegou |
| 6 | Valdoria (fonte) → escadaria → viaduto → portão do Castelo → Castelo Imperial (centro) | chegou |

## Onde o agente parou no caminho, e por quê

| Onde | Causa | O que foi feito |
|---|---|---|
| x=-160, entrada oeste do Refúgio (parada antiga) | **Defeito do jogo:** degrau de 0,2 m na borda oeste e norte de cada região | Corrigido em `terreno_mundo.gd`; `tools/teste_bordas.gd` |
| Alto da rampa do Castelo, (584, -2191,6) | **Defeito do jogo:** a rampa chegava ao alto 2 m depois da face da plataforma; na face faltavam 0,33 m e não dava para entrar no Castelo a pé | Corrigido em `castelo_imperial.gd` (rampa chega na face) |
| Meio do portão do Castelo, (584, -2197,6) | **Defeito do jogo:** um mastro de bandeira no eixo do portão barrava quem vinha reto | Mastro do eixo retirado em `castelo_imperial.gd` |
| Praça do Refúgio, a caminho do portão norte (2 vezes) | Rota do agente: ia reto para o norte e a casa do Vane fica no meio; depois o desvio caía dentro de um cercado | Pontos de passagem pelo corredor livre a oeste da casa |
| Volta do Bosque para a praça | Rota do agente: cortava a paliçada fora do portão | Pontos de passagem pelos portões |
| Serra de pedra em x=324 | Rota do agente: ia reto em vez de passar pelo vão da barreira em (330, -1) | Pontos de passagem no vão |
| Muralha de Ferrogris | Rota do agente: a entrada é a Brecha, 5 m a oeste do eixo; o portão dos fundos só abre quando o Kaelor cai | Pontos de passagem na Brecha; o agente abre os 2 portões de chefe como no fim da campanha |
| Portão do Castelo fechado | O agente marcava as missões só até a C4-M4; o portão pede a C5-M1 | Agente marca também a C5-M1 |
| Embaixo da rampa de Valdoria (3 retomadas) | Defeito do agente: a retomada pousava o Torin numa região ainda desligada (sem chão sólido) | Retomada liga a região antes de pousar |

## O que este percurso NÃO prova

- Não foi uma rodada única, e o tempo de cada trecho foi medido a 2 a 5 quadros por segundo.
- O agente anda por pontos de passagem escolhidos por mim com um mapa de obstáculos; ele não acha o caminho sozinho. Um caminho que
  exige contornar algo que eu não previ aparece como "preso".
- Não luta com chefes: as barreiras e os 2 portões de chefe são abertos por código, como estariam no fim da campanha.
- Não entra em casas, não cobre os 21 povoados nem os caminhos fora das estradas.
