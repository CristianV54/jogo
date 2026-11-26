# BASELINE — Reino de Cinzas (antes da reconstrução)

Registrado em 22/11/2026, no início do plano de reconstrução e validação (`PLANO DE RECONSTRUÇÃO E VALIDAÇÃO.docx`).

## Estado do repositório
- Branch de trabalho: `reconstrucao` (criada a partir de `fundacao`, commit `96c0557`).
- Tag de retorno: `baseline-reconstrucao` (aponta para `96c0557`, sem as mudanças da Etapa 0/1).
- Outras tags úteis: `checkpoint-antes-titulo-e-dialogos`.
- Motor: Godot 4.7.2, renderizador `mobile` + Metal. Blender 5.3.0 para modelos.

## Compilação
`godot --headless --path . --import`: **0 erros de script** (log guardado em `/tmp/compila.log` na hora; repetir com o mesmo comando).

## Testes automáticos existentes (todos passaram no baseline)
teste_missoes, teste_cadeia, teste_marco3 a 7, teste_mundo, teste_rio, teste_medo, teste_sono, teste_cartaz, teste_queda, auditoria_mundo, auditoria_portais, auditoria_continua, auditoria_cercos, auditoria_buracos (todos 0 problemas) e auditoria_logica (1 aviso conhecido e falso: a bigorna da forja encosta na parede da forja).

**Lição do baseline:** todos os testes passavam e mesmo assim o jogo tinha erros graves à vista (cavalo atravessando pedra, água no ar, bichos no ar). Os testes conferiam o que eu já imaginava, não o mundo inteiro. Por isso nasceu o Drone de Auditoria.

## Catálogo
- 83 scripts em `scripts/` (61 em `mundo/`, 6 `criaturas`, 3 `interface`, 3 `jogo`, 3 `personagens`, 2 `missoes`, 2 `importacao`, 1 `camera`, 1 `jogador`, 1 `inimigos`).
- 52 cenas em `scenes/`, 8 delas regiões em `scenes/areas/`.
- 73 ferramentas em `tools/` (testes, auditorias, capturas).
- 40 arquivos de script criam colisão (119 ocorrências de `StaticBody3D.new`/`CollisionShape3D.new`/`collision_layer`).
- 20 missões (C1-M1 a C5-M4) em `scripts/missoes/dados_missoes.gd`.
- Mundo: `scripts/mundo/mundo.gd` monta as 8 regiões (`MundoDados.REGIOES`), o chão (`terreno_mundo.gd`), estradas, rios, pontes, serras (`CRISTAS`), barreiras, costa (`costa.gd`), florestas, 21 povoados (`povoado.gd`), fauna, clima.
- Camadas de colisão: 1 mundo (paredes, terreno, troncos, portas fechadas), 2 tetos só para a câmera, 4 móveis das casas, 8 seres (NPC, bicho, Fagulha).

## Teclas de teste (F1 a F11), agora no nó `Admin` (`scripts/jogo/admin.gd`)
F1 a F8 teleportam às 8 regiões (ignorando os bloqueios da história), F9 troca a hora (6, 12, 18, 22), F10 troca o tempo (limpo, nublado, chuva, tempestade), F11 liga o Drone (`scripts/jogo/drone.gd`, câmera livre que não depende do Torin). Não alteram o gameplay normal.

## Erros conhecidos no baseline

**Apontados pelo usuário (ainda sem teste que os pegue):**
- Cavalo montado atravessa parede e pedra (só a cápsula do Torin colide; o corpo do cavalo é desligado ao montar).
- Lobo ataca de costas e através de parede (o golpe só confere distância); persegue em linha reta, sem contornar.
- Cavalo sem olhos e com aparência fraca (modelo de pacote simples).
- Rio com água em faixa plana sobre chão mais baixo; cortes secos nos fins de trecho (a verificar).
- Mapa vertical e simples: corredor norte-sul com 8 regiões em fila; serras fecham tudo menos o vão das barreiras.
- NPCs: medo de lobo parado inexistente; o lobo nunca ataca NPC; camas reservadas no medo não são soltas; criança que segue o jogador não foge.

**Achados pelo Drone de Auditoria no baseline** (`docs/auditoria/RELATORIO_baseline.md`):
- 86 × CRITICO **penhasco no terreno** (desnível de 4,5 a 6,4 m em 6 m), todos na faixa da costa.
- 77 × CRITICO **ser flutuando ou enterrado** (de -3,1 a +3,3 m), concentrados no Pomar Alto: a fauna nasce com a altura do chão do mundo dentro de uma região que tem chão próprio.
- 10 × VISUAL **água no ar sobre chão mais baixo** (até 1,2 m), nos rios do mundo e das regiões.
- 0 bloqueadores (nenhum buraco sem piso em terra); 0 pontes terminando no ar; 0 casas sem telhado, porta ou colisão.
