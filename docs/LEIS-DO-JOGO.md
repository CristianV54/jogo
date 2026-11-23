# Leis do jogo (Reino de Cinzas)

Regras que o jogo nunca pode quebrar. Cada uma aponta para o teste que a confere; erro novo apontado pelo Cristian vira uma lei nova aqui e um teste.
Rodar tudo: ver "Suíte completa" no fim.

| Lei | Teste |
|---|---|
| Não existe ponto jogável sem piso; ninguém cai do mundo | `drone_auditoria` (grade de 6 m), `auditoria_buracos`, `teste_queda` |
| Nenhum desnível de terreno passa de 45° (6 m em 6 m) | `drone_auditoria` |
| A água nunca fica pendurada sobre chão mais baixo; margem acima da água | `drone_auditoria` (categoria "água no ar") |
| Todo rio termina em outro rio, no mar ou numa borda de região; pontas livres afinam | `drone_auditoria` (rio sem começo ou fim) |
| Toda ponte termina no chão nas duas pontas | `drone_auditoria` |
| As barreiras fechadas selam a história; abertas ligam as 8 regiões e os 21 povoados | `auditoria_cercos` |
| Nenhum ser (NPC, bicho, inimigo) flutua, fica enterrado ou dentro de parede | `drone_auditoria`, `auditoria_logica` |
| Quem anda sem física usa `Mundo.chao_em` (chão da região, não do mundo) | `drone_auditoria` |
| Toda casa tem telhado, porta, colisão e cama (se é moradia) | `drone_auditoria`, `auditoria_logica` |
| Nenhuma construção sobre outra; nada solto dentro de campo ou casa | `auditoria_logica` |
| O cavalo montado tem corpo e não atravessa parede | `teste_simulacao` |
| Monstro não entra em casa e só golpeia quem está à frente e sem parede entre os dois | `teste_simulacao` |
| NPC dorme na própria cama à noite e na chuva, acorda de manhã; cama é solta depois do susto | `teste_sono`, `teste_medo` |
| NPC foge de monstro (também parado perto), para longe dele, e volta quando passa | `teste_medo` |
| As 20 missões estão em cadeia, concluem por evento real e cada objetivo tem fonte no mundo | `teste_cadeia`, `teste_marco3` a `7`, `teste_missoes_dados` |
| As 5 barreiras abrem só com a missão ou o chefe certo | `teste_missoes_dados`, `auditoria_cercos` |
| O Fagulha tem 3 fases (tamanho, cor, voo, ataque, montaria) trocadas pelas missões | `teste_fagulha` |
| Solon aparece em cartazes antes do Castelo | `teste_cartaz` |
| 60 fps nos pontos típicos (Refúgio, estrada, mata, aldeias, Valdoria, tempestade) | `perfil_aberto` |

## Suíte completa
```
godot --headless --path . --script res://tools/<teste>.gd
teste_fagulha teste_missoes teste_cadeia teste_marco3..7 teste_mundo teste_simulacao teste_medo teste_sono
teste_cartaz teste_rio teste_queda teste_rotinas teste_missoes_dados auditoria_mundo auditoria_portais
auditoria_continua auditoria_cercos auditoria_buracos auditoria_logica
godot --headless --path . --script res://tools/drone_auditoria.gd -- <etapa>   # relatório em docs/auditoria/
godot --path . --resolution 1280x720 --script res://tools/drone_fotos.gd -- <etapa>   # fotos das 8 regiões
```
Testes que já falhavam no baseline (não são regressões): `teste_solidos`, `teste_montaria_dano` (balão de protesto do NPC). Aviso falso conhecido: bigorna da forja em `auditoria_logica`.

## Teclas de teste (nó Admin, fora do gameplay)
F1 a F8 teleportam às regiões, F9 troca a hora, F10 o tempo, F11 liga o Drone (câmera livre: WASD, Espaço, C, Shift, mouse).
