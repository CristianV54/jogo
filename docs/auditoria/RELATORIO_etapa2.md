# Relatório de auditoria — etapa2

Gerado por `tools/drone_auditoria.gd` (varredura sem o Torin).

| Severidade | Total |
|---|---|
| BLOQUEADOR | 0 |
| CRITICO | 65 |
| VISUAL | 10 |
| MENOR | 0 |

## Por categoria (total, e até 12 exemplos com coordenada)

### CRITICO / penhasco no terreno: 5
- (-70.0, -52.0) `terreno` desnível de 4.6 m em 6 m: o jogador não sobe nem desce
- (-64.0, -58.0) `terreno` desnível de 4.7 m em 6 m: o jogador não sobe nem desce
- (-22.0, -616.0) `terreno` desnível de 5.3 m em 6 m: o jogador não sobe nem desce
- (-22.0, -610.0) `terreno` desnível de 4.8 m em 6 m: o jogador não sobe nem desce
- (-4.0, -82.0) `terreno` desnível de 4.6 m em 6 m: o jogador não sobe nem desce

### CRITICO / ser dentro de parede: 2
- (-504.1, -300.7) `@Node3D@28809` dentro de /root/Jogo/AreaAtual/Mundo/pomar_alto/SolidosDoPomar
- (639.5, -387.7) `@Node3D@28887` dentro de /root/Jogo/AreaAtual/Mundo/acampamento_ruptura/SolidosDaArea

### CRITICO / ser flutuando ou enterrado: 58
- (-504.1, -300.7) `@Node3D@28809` a -4.0 m do chão
- (639.5, -387.7) `@Node3D@28887` a -4.0 m do chão
- (-73.0, -99.0) `GuardaImperial` a -1.8 m do chão
- (-57.0, -100.0) `@CharacterBody3D@4320` a -1.8 m do chão
- (-65.0, -94.0) `@CharacterBody3D@4323` a -1.8 m do chão
- (-14.0, -557.0) `GuardaImperial` a -1.8 m do chão
- (-4.0, -616.0) `@CharacterBody3D@9327` a -1.8 m do chão
- (7.0, -635.0) `@CharacterBody3D@9369` a -1.8 m do chão
- (-8.0, -650.0) `@CharacterBody3D@9372` a -1.8 m do chão
- (8.0, -650.0) `@CharacterBody3D@9375` a -1.8 m do chão
- (-12.0, -667.6) `@CharacterBody3D@9378` a -1.8 m do chão
- (12.0, -667.6) `@CharacterBody3D@9381` a -1.8 m do chão

### VISUAL / água no ar sobre chão mais baixo: 10
- (-381.5, 113.2) `mundo/rio` 624 de 942 amostras; pior 1.2 m abaixo da faixa de água
- (342.8, 58.5) `mundo/rio` 680 de 1032 amostras; pior 1.2 m abaixo da faixa de água
- (776.4, -387.1) `mundo/rio` 336 de 516 amostras; pior 1.0 m abaixo da faixa de água
- (-336.2, -60.5) `mundo/rio` 259 de 768 amostras; pior 0.8 m abaixo da faixa de água
- (-225.2, -480.8) `mundo/rio` 268 de 804 amostras; pior 0.6 m abaixo da faixa de água
- (271.4, -451.5) `mundo/rio` 150 de 450 amostras; pior 0.6 m abaixo da faixa de água
- (40.8, -50.2) `refugio_do_pinhal/rio` 325 de 972 amostras; pior 0.7 m abaixo da faixa de água
- (-353.6, -161.7) `pomar_alto/rio` 150 de 450 amostras; pior 0.6 m abaixo da faixa de água
- (71.2, -508.4) `bosque_velado/rio` 226 de 624 amostras; pior 0.8 m abaixo da faixa de água
- (619.9, -339.3) `acampamento_ruptura/rio` 397 de 606 amostras; pior 1.2 m abaixo da faixa de água
