# Percurso real (agente andando, sem teleporte entre regiões)

**Resultado: REPROVADO.** Chegou ao Castelo: **NÃO**. Duração: 156 s (2.6 min). Posição final: (-160.0, -6.0) (estrada_ou_campo).
Teclas: W + Shift, E para fechar diálogos; câmera apontada ao próximo ponto; desvio de 90 graus quando fica 1,2 s parado. Dano recebido: 2 (a vida era reposta abaixo de 40 %). Lutas com bicho ou inimigo no caminho: 1.
Limites: 90 s por trecho, 1500 s no total, reprova se ficar 6 s sem avançar 3 m.

## Por região (a região é a que o jogo reporta no momento em que o Torin está)

| Região | Entrada (s) | Saída (s) | Início | Fim | Distância andada | Vel. média | Menor fps | Quedas | Desvios (obstáculos) | Resultado |
|---|---|---|---|---|---|---|---|---|---|---|
| refugio_do_pinhal | 5 | 31 | (0.0, 13.0) | (-159.0, -1.0) | 164 m | 7.4 m/s | 25 | 0 | 0 | PASS |
| estrada_ou_campo | 31 | 156 | (-160.0, -1.0) | (-160.0, -6.0) | 681 m | 6.7 m/s | 16 | 0 | 6 | PASS |

## Trechos

| Trecho | Resultado | Tempo | Desvios | Região ao fim | fps |
|---|---|---|---|---|---|
| Refúgio -> saída oeste (desvia do curral) | chegou | 3 s | 0 | refugio_do_pinhal | 88 |
| Portão oeste da palicada | chegou | 3 s | 0 | refugio_do_pinhal | 95 |
| Estrada do Pomar (início) | chegou | 15 s | 0 | refugio_do_pinhal | 95 |
| Estrada do Pomar (meio) | chegou | 23 s | 0 | estrada_ou_campo | 110 |
| Pomar Alto (centro) | chegou | 18 s | 0 | estrada_ou_campo | 118 |
| Pomar -> volta ao Refúgio | chegou | 31 s | 1 | estrada_ou_campo | 106 |
| Portão oeste (volta) | FALHOU: PRESO: menos de 3 m em 6 s (desviou 5 vezes) | 30 s | 5 | estrada_ou_campo | 102 |

## Problemas e observações
[estrada_ou_campo] PROBLEMA em 'Portão oeste (volta)': PRESO: menos de 3 m em 6 s (desviou 5 vezes). Parou em (-160.0, -6.0) (alvo (-48.0, 0.0), a 112 m dele).

Não medido por este agente: NPC ou animal preso e erros de console por região (os erros do console são conferidos no log da execução, ver o relatório de estabilização).
