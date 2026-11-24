# Percurso real (agente andando, sem teleporte entre regiões)

**Resultado: PASS.** Chegou ao Castelo: **SIM**. Duração: 499 s (8.3 min). Posição final: (584.0, -2295.0) (castelo_imperial).
Teclas: W + Shift, E para fechar diálogos; câmera apontada ao próximo ponto; desvio de 90 graus quando fica 1,2 s parado. Dano recebido: 143 (a vida era reposta abaixo de 40 %). Lutas com bicho ou inimigo no caminho: 9.
Limites: 90 s por trecho, 1500 s no total, reprova se ficar 6 s sem avançar 3 m.

## Por região (a região é a que o jogo reporta no momento em que o Torin está)

| Região | Entrada (s) | Saída (s) | Início | Fim | Distância andada | Vel. média | Menor fps | Quedas | Desvios (obstáculos) | Resultado |
|---|---|---|---|---|---|---|---|---|---|---|
| valdoria | 24 | 164 | (593.0, -1881.0) | (584.0, -2029.0) | 155 m | 9.6 m/s | 2 | 0 | 0 | PASS |
| estrada_ou_campo | 164 | 205 | (584.0, -2030.0) | (584.0, -2150.0) | 120 m | 9.3 m/s | 2 | 0 | 0 | PASS |
| castelo_imperial | 205 | 499 | (584.0, -2151.0) | (584.0, -2295.0) | 170 m | 8.7 m/s | 2 | 0 | 0 | PASS |

## Trechos

| Trecho | Resultado | Tempo | Desvios | Região ao fim | fps |
|---|---|---|---|---|---|
| (retomada do checkpoint 38) | teleporte de retomada | 0 s | 0 | valdoria | 0 |
| Valdoria: pé da escadaria | chegou | 8 s | 0 | valdoria | 3 |
| Escadaria de Valdoria (alto) | chegou | 6 s | 0 | valdoria | 3 |
| Viaduto (fim) | chegou | 16 s | 0 | castelo_imperial | 3 |
| Portão do Castelo | chegou | 4 s | 0 | castelo_imperial | 3 |
| Castelo Imperial (centro) | chegou | 15 s | 0 | castelo_imperial | 3 |

## Problemas e observações
Nenhum.

Não medido por este agente: NPC ou animal preso e erros de console por região (os erros do console são conferidos no log da execução, ver o relatório de estabilização).
