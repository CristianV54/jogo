# Medidas de movimento (tools/bancada_movimento.gd)

Amplitude = quanto o osso que mais mexe se desloca no ciclo (m). Passo = vai e vem do pé que mais anda, no eixo da frente (m).
Velocidade pedida = 2 x passo / duração (o pé fica no chão metade do ciclo). Se a do jogo for muito diferente, o pé desliza.

| Ser | Animação | Duração (s) | Loop | Amplitude (m) | Passo (m) | Vel. pedida (m/s) | Vel. no jogo (m/s) | Observação |
|---|---|---|---|---|---|---|---|---|
| vaca | Death | 1.29 | não | 2.36 | 0.20 |  |  |  |
| vaca | Idle | 6.29 | sim | 0.15 | 0.00 |  |  |  |
| vaca | Jump | 1.75 | não | 1.44 | 1.40 |  |  |  |
| vaca | Run | 1.46 | sim | 1.55 | 1.53 | 4.0 | 4.0 |  |
| vaca | Walk | 3.38 | sim | 0.91 | 0.89 | 0.5 |  |  |
| vaca | WalkSlow | 2.12 | sim | 0.80 | 0.79 | 1.1 | 1.0 |  |
| ovelha | Death | 1.29 | não | 1.12 | 0.17 |  |  |  |
| ovelha | Idle | 6.29 | sim | 0.06 | 0.00 |  |  |  |
| ovelha | Jump | 1.17 | não | 1.15 | 1.13 |  |  |  |
| ovelha | Run | 1.46 | sim | 0.96 | 0.92 | 3.8 | 4.0 |  |
| ovelha | Walk | 3.38 | sim | 0.54 | 0.54 | 0.3 |  |  |
| ovelha | WalkSlow | 2.12 | sim | 0.60 | 0.59 | 0.9 | 1.0 |  |
| cavalo | Death | 1.12 | não | 2.89 | 0.24 |  |  |  |
| cavalo | Idle | 6.29 | sim | 0.15 | 0.01 |  |  |  |
| cavalo | Jump | 1.54 | não | 1.49 | 1.46 |  |  |  |
| cavalo | Run | 0.88 | sim | 1.62 | 1.59 | 4.0 | 4.0 |  |
| cavalo | Walk | 2.71 | sim | 0.95 | 0.93 | 0.7 |  |  |
| cavalo | WalkSlow | 2.04 | sim | 0.82 | 0.82 | 1.0 | 1.0 |  |
| porco | Death | 1.29 | não | 0.92 | 0.14 |  |  |  |
| porco | Idle | 6.29 | sim | 0.06 | 0.00 |  |  |  |
| porco | Jump | 1.54 | não | 0.90 | 0.88 |  |  |  |
| porco | Run | 1.46 | sim | 0.42 | 0.40 | 1.7 | 4.0 | pé desliza: jogo 2.4x mais rápido que o passo |
| porco | Walk | 3.38 | sim | 0.23 | 0.22 | 0.1 |  |  |
| porco | WalkSlow | 2.12 | sim | 0.26 | 0.26 | 0.5 | 0.4 |  |
| cao | Death | 1.29 | não | 0.80 | 0.11 |  |  |  |
| cao | Idle | 6.29 | sim | 0.03 | 0.00 |  |  |  |
| cao | Jump | 1.54 | não | 0.53 | 0.51 |  |  |  |
| cao | Run | 1.46 | sim | 0.25 | 0.24 | 1.0 | 4.0 | pé desliza: jogo 4.1x mais rápido que o passo |
| cao | Walk | 3.38 | sim | 0.14 | 0.14 | 0.1 |  |  |
| cao | WalkSlow | 2.12 | sim | 0.16 | 0.15 | 0.3 | 0.3 |  |
| galinha | (sem AnimationPlayer ou sem esqueleto) | | | | | | | SEM ANIMAÇÃO |
| cervo | Death | 1.12 | não | 1.79 | 0.15 |  |  |  |
| cervo | Idle | 6.29 | sim | 0.09 | 0.01 |  |  |  |
| cervo | Jump | 1.54 | não | 0.92 | 0.90 |  |  |  |
| cervo | Run | 0.88 | sim | 1.00 | 0.99 | 4.0 | 4.0 |  |
| cervo | Walk | 2.71 | sim | 0.59 | 0.58 | 0.4 |  |  |
| cervo | WalkSlow | 2.04 | sim | 0.51 | 0.51 | 1.0 | 1.0 |  |
| coelho | Death | 1.29 | não | 0.40 | 0.06 |  |  |  |
| coelho | Idle | 6.29 | sim | 0.02 | 0.00 |  |  |  |
| coelho | Jump | 1.54 | não | 0.26 | 0.26 |  |  |  |
| coelho | Run | 1.46 | sim | 0.12 | 0.12 | 0.5 | 4.0 | pé desliza: jogo 8.2x mais rápido que o passo |
| coelho | Walk | 3.38 | sim | 0.07 | 0.07 | 0.0 |  |  |
| coelho | WalkSlow | 2.12 | sim | 0.08 | 0.08 | 0.1 | 0.1 |  |
| arqueiro | Idle (parado) | 2.50 | sim | 0.05 | 0.00 |  |  |  |
| arqueiro | Walk (andar) | 1.33 | sim | 0.86 | 0.85 | 1.3 |  |  |
| arqueiro | Jog_Fwd (correr) | 0.93 | sim | 1.63 | 1.59 | 3.4 |  |  |
| arqueiro | Spell_Simple_Shoot (atacar) | 0.50 | não | 0.10 | 0.00 |  |  |  |
| arqueiro | Hit_Chest (dano) | 0.33 | não | 0.25 | 0.00 |  |  |  |
| arqueiro | Death01 (morte) | 2.40 | não | 2.02 | 1.75 |  |  |  |
| cao_de_guerra | Idle (parado) | 6.29 | sim | 0.05 | 0.00 |  |  |  |
| cao_de_guerra | Walk (andar) | 3.38 | sim | 0.24 | 0.23 | 0.1 |  |  |
| cao_de_guerra | Run (correr) | 1.46 | sim | 0.42 | 0.40 | 1.7 | 5.6 | pé desliza: jogo 3.4x mais rápido que o passo |
| cao_de_guerra | Jump (atacar) | 1.54 | não | 0.89 | 0.87 |  |  |  |
| cao_de_guerra | Death (morte) | 1.29 | não | 1.36 | 0.19 |  |  |  |
| cao_de_guerra | FALTAM: dano (vazio) | | | | | | | sem animação para isso |
| filhote_de_asa | Idle (parado) | 22.75 | sim | 0.73 | 0.19 |  |  |  |
| filhote_de_asa | Walk (andar) | 3.29 | sim | 0.24 | 0.23 | 0.1 |  |  |
| filhote_de_asa | Run (correr) | 1.62 | sim | 0.27 | 0.26 | 0.3 | 4.6 | pé desliza: jogo 14.3x mais rápido que o passo |
| filhote_de_asa | Run (atacar) | 1.62 | sim | 0.27 | 0.26 | 0.3 | 4.6 | pé desliza: jogo 14.3x mais rápido que o passo |
| filhote_de_asa | FALTAM: dano (vazio), morte (vazio) | | | | | | | sem animação para isso |
| gorath | Idle (parado) | 2.50 | sim | 0.09 | 0.01 |  |  |  |
| gorath | Walk (andar) | 1.33 | sim | 1.51 | 1.50 | 2.2 |  |  |
| gorath | Jog_Fwd (correr) | 0.93 | sim | 2.86 | 2.78 | 6.0 |  |  |
| gorath | Punch_Cross (atacar) | 1.00 | não | 1.24 | 0.08 |  |  |  |
| gorath | Hit_Chest (dano) | 0.33 | não | 0.43 | 0.00 |  |  |  |
| gorath | Death01 (morte) | 2.40 | não | 3.54 | 3.07 |  |  |  |
| guarda_imperial | Idle (parado) | 2.50 | sim | 0.05 | 0.00 |  |  |  |
| guarda_imperial | Walk (andar) | 1.33 | sim | 0.86 | 0.85 | 1.3 |  |  |
| guarda_imperial | Jog_Fwd (correr) | 0.93 | sim | 1.63 | 1.59 | 3.4 |  |  |
| guarda_imperial | Sword_Attack (atacar) | 1.53 | não | 2.34 | 0.97 |  |  |  |
| guarda_imperial | Hit_Chest (dano) | 0.33 | não | 0.25 | 0.00 |  |  |  |
| guarda_imperial | Death01 (morte) | 2.40 | não | 2.02 | 1.75 |  |  |  |
| ignis_maw | Idle (parado) | 22.75 | sim | 9.74 | 2.59 |  |  |  |
| ignis_maw | Walk (andar) | 3.29 | sim | 3.22 | 3.06 | 1.9 |  |  |
| ignis_maw | Run (correr) | 1.62 | sim | 3.53 | 3.48 | 4.3 | 6.0 | pé desliza: jogo 1.4x mais rápido que o passo |
| ignis_maw | Run (atacar) | 1.62 | sim | 3.53 | 3.48 | 4.3 | 6.0 | pé desliza: jogo 1.4x mais rápido que o passo |
| ignis_maw | FALTAM: dano (vazio), morte (vazio) | | | | | | | sem animação para isso |
| javali | Idle (parado) | 6.29 | sim | 0.07 | 0.00 |  |  |  |
| javali | Walk (andar) | 3.38 | sim | 0.26 | 0.26 | 0.2 |  |  |
| javali | Run (correr) | 1.46 | sim | 0.50 | 0.47 | 1.9 | 4.2 | pé desliza: jogo 2.2x mais rápido que o passo |
| javali | Jump (atacar) | 1.54 | não | 1.06 | 1.04 |  |  |  |
| javali | Death (morte) | 1.29 | não | 1.08 | 0.16 |  |  |  |
| javali | FALTAM: dano (vazio) | | | | | | | sem animação para isso |
| kaelor | Idle (parado) | 2.50 | sim | 0.06 | 0.01 |  |  |  |
| kaelor | Walk (andar) | 1.33 | sim | 1.04 | 1.03 | 1.5 |  |  |
| kaelor | Jog_Fwd (correr) | 0.93 | sim | 1.96 | 1.91 | 4.1 |  |  |
| kaelor | Sword_Attack (atacar) | 1.53 | não | 2.81 | 1.16 |  |  |  |
| kaelor | Hit_Chest (dano) | 0.33 | não | 0.30 | 0.00 |  |  |  |
| kaelor | Death01 (morte) | 2.40 | não | 2.43 | 2.11 |  |  |  |
| lobo | Idle (parado) | 1.71 | sim | 0.06 | 0.00 |  |  |  |
| lobo | Walk (andar) | 1.71 | sim | 0.53 | 0.50 | 0.6 |  |  |
| lobo | Run (correr) | 0.88 | sim | 0.56 | 0.52 | 3.8 | 5.0 |  |
| lobo | Jump (atacar) | 0.83 | não | 1.04 | 0.28 |  |  |  |
| lobo | Death (morte) | 1.00 | não | 1.09 | 0.00 |  |  |  |
| lobo | FALTAM: dano (vazio) | | | | | | | sem animação para isso |
| solon | Idle (parado) | 2.50 | sim | 0.06 | 0.01 |  |  |  |
| solon | Walk (andar) | 1.33 | sim | 1.08 | 1.07 | 1.6 |  |  |
| solon | Jog_Fwd (correr) | 0.93 | sim | 2.04 | 1.99 | 4.3 |  |  |
| solon | Sword_Attack (atacar) | 1.53 | não | 2.93 | 1.21 |  |  |  |
| solon | Hit_Chest (dano) | 0.33 | não | 0.31 | 0.00 |  |  |  |
| solon | Death01 (morte) | 2.40 | não | 2.53 | 2.19 |  |  |  |
| urso | Idle (parado) | 6.29 | sim | 0.07 | 0.01 |  |  |  |
| urso | Walk (andar) | 3.38 | sim | 0.32 | 0.32 | 0.2 |  |  |
| urso | Run (correr) | 1.46 | sim | 0.57 | 0.55 | 2.2 | 3.8 | pé desliza: jogo 1.7x mais rápido que o passo |
| urso | Jump (atacar) | 1.54 | não | 1.21 | 1.18 |  |  |  |
| urso | Death (morte) | 1.29 | não | 1.85 | 0.25 |  |  |  |
| urso | FALTAM: dano (vazio) | | | | | | | sem animação para isso |
| vane_duelista | Idle (parado) | 2.50 | sim | 0.06 | 0.01 |  |  |  |
| vane_duelista | Walk (andar) | 1.33 | sim | 0.97 | 0.96 | 1.4 |  |  |
| vane_duelista | Jog_Fwd (correr) | 0.93 | sim | 1.84 | 1.79 | 3.8 |  |  |
| vane_duelista | Sword_Attack (atacar) | 1.53 | não | 2.63 | 1.08 |  |  |  |
| vane_duelista | Hit_Chest (dano) | 0.33 | não | 0.28 | 0.00 |  |  |  |
| vane_duelista | Death01 (morte) | 2.40 | não | 2.27 | 1.97 |  |  |  |
| fagulha | Fly | 2.50 | sim | 4.34 | 0.50 |  |  |  |
| fagulha | Idle | 22.75 | sim | 4.26 | 1.56 |  |  |  |
| fagulha | Run | 1.62 | sim | 1.55 | 1.52 | 1.9 |  |  |
| fagulha | Walk | 3.29 | sim | 1.41 | 1.34 | 0.8 |  |  |
| fagulha | FALTAM: Death | | | | | | | sem animação para isso |
| torin | Idle | 2.50 | sim | 0.05 | 0.00 |  |  |  |
| torin | Jog_Fwd | 0.93 | sim | 1.63 | 1.59 | 3.4 | 4.0 |  |
| torin | Sprint | 0.67 | sim | 1.50 | 1.45 | 4.4 | 7.0 | pé desliza: jogo 1.6x mais rápido que o passo |
| torin | Sword_Attack | 1.53 | não | 2.34 | 0.97 |  |  |  |
| torin | Roll | 1.47 | não | 2.13 | 1.70 |  |  |  |
| torin | Jump | 2.50 | sim | 0.12 | 0.01 |  |  |  |
| torin | Hit_Chest | 0.33 | não | 0.25 | 0.00 |  |  |  |
| torin | Death01 | 2.40 | não | 2.02 | 1.75 |  |  |  |
