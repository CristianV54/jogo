# Percurso real (agente andando, sem teleporte entre regiões)

**Resultado: REPROVADO.** Chegou ao Castelo: **NÃO**. Duração: 800 s (13.3 min). Posição final: (39.0, -12.0) (refugio_do_pinhal).
Teclas: W + Shift, E para fechar diálogos; câmera apontada ao próximo ponto; desvio de 90 graus quando fica 1,2 s parado. Dano recebido: 33 (a vida era reposta abaixo de 40 %). Lutas com bicho ou inimigo no caminho: 2.
Limites: 90 s por trecho, 1500 s no total, reprova se ficar 6 s sem avançar 3 m.

## Por região (a região é a que o jogo reporta no momento em que o Torin está)

| Região | Entrada (s) | Saída (s) | Início | Fim | Distância andada | Vel. média | Menor fps | Quedas | Desvios (obstáculos) | Resultado |
|---|---|---|---|---|---|---|---|---|---|---|
| refugio_do_pinhal | 31 | 800 | (-10.0, -1.0) | (39.0, -12.0) | 390 m | 5.9 m/s | 1 | 0 | 8 | PASS |
| estrada_ou_campo | 157 | 620 | (2.0, -160.0) | (0.0, -161.0) | 463 m | 9.4 m/s | 1 | 0 | 0 | PASS |
| bosque_velado | 313 | 503 | (0.0, -391.0) | (-3.0, -391.0) | 354 m | 7.9 m/s | 1 | 0 | 3 | PASS |

## Trechos

| Trecho | Resultado | Tempo | Desvios | Região ao fim | fps |
|---|---|---|---|---|---|
| (retomada do checkpoint 7) | teleporte de retomada | 0 s | 0 | refugio_do_pinhal | 0 |
| Contorna a casa do Vane pelo oeste | chegou | 2 s | 0 | refugio_do_pinhal | 2 |
| Atrás da casa do Vane | chegou | 2 s | 0 | refugio_do_pinhal | 2 |
| Portão norte da palicada | chegou | 1 s | 0 | refugio_do_pinhal | 3 |
| Refúgio -> Trilha do Bosque | chegou | 25 s | 4 | refugio_do_pinhal | 3 |
| Bosque Velado (entrada) | chegou | 25 s | 0 | estrada_ou_campo | 2 |
| Bosque Velado e Mina (centro) | chegou | 21 s | 1 | bosque_velado | 2 |
| Bosque -> volta ao Refúgio | chegou | 48 s | 2 | estrada_ou_campo | 3 |
| Refúgio (centro) 2 | FALHOU: PRESO: menos de 3 m em 6 s (desviou 4 vezes) | 36 s | 4 | refugio_do_pinhal | 2 |

## Problemas e observações
[refugio_do_pinhal] PROBLEMA em 'Refúgio (centro) 2': PRESO: menos de 3 m em 6 s (desviou 4 vezes). Parou em (39.0, -12.0) (alvo (20.0, 5.0), a 25 m dele).

Não medido por este agente: NPC ou animal preso e erros de console por região (os erros do console são conferidos no log da execução, ver o relatório de estabilização).
