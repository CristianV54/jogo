# Mapa do trabalho (gerado lendo os arquivos em 23/11/2026; atualizar quando criar algo novo)

Regra: arquivo novo entra aqui na mesma hora. Em 25/11/2026 foi feita uma LIMPEZA (pedido do usuário: ficar só o que o jogo usa): saíram `wip/`, 69 ferramentas antigas de `tools/` (perfis, diagnósticos, visualizadores, auditorias do corredor antigo e testes da campanha) e duas cenas de teste. Menções a elas mais abaixo neste arquivo são históricas; tudo continua no histórico do git (tag `baseline-reconstrucao`). Capturas e relatórios dizem de qual teste vieram.

Ponto de entrada: [README.md](../README.md) e [CLAUDE.md](../CLAUDE.md). Relato completo da última sessão: [SESSAO-2026-11-23.md](SESSAO-2026-11-23.md).

## Testes e ferramentas em tools/ (primeira linha de comentário de cada um)

| Arquivo | Para que serve |
|---|---|
| `tools/bancada.gd` | BANCADA: mundo plano e vazio que fotografa cada item do jogo sozinho (frente, lado e costas; parado e andando quando tem animação), |
| `tools/bancada_construcao.gd` | BANCADA DAS CONSTRUÇÕES: monta UMA peça (hoje a muralha) num chão plano com o Torin de régua, tira 13 fotos e roda 3 testes em ~12 s. Uso: `... --script res://tools/bancada_construcao.gd -- muralha`. Fotos em `docs/construcoes/muralha/`. |
| `scripts/mundo/pecas_da_muralha.gd` | Kit da muralha (lanço, torre, escada, portão com arco). Aprovado na bancada e usado por `muralha_do_reino.gd`. |
| `scripts/mundo/pecas_de_construcao.gd` | Base dos kits de construção: junta caixas, cilindros e prismas em poucos MultiMesh e guarda as colisões. |
| `scripts/mundo/pecas_da_rua.gd` | Kit da rua: calçada, sarjeta, degrau, lampiões (parede e poste), placa, carga, banco, vaso, barraca de feira, carroça, cavalete de armas, alvo de arco e estandarte. Usado por `casario_do_reino.gd`, `vida_das_ruas.gd` e `povoado.gd` (mercado). Bancada: `-- rua` e `-- feira`. Critério em `docs/construcoes/rua.md`. |
| `scripts/mundo/catedral.gd` | A catedral gótica de Valdoria inteira (nave, torres, vitrais, portal, rosácea). Usada por `povoado.gd`. Bancada: `-- catedral`. Critério em `docs/construcoes/catedral.md`. |
| `docs/construcoes/` | Uma pasta e um `.md` por peça (muralha, rua, feira, catedral, cidadela, quartel): critério de pronto, resultado, fotos da bancada (01_...) e de dentro do mundo (20_...), e os pontos fracos anotados para depois. |
| `tools/bancada_movimento.gd` | BANCADA DE MOVIMENTO: 6 quadros de cada animação de cada ser (vista de lado) e medidas de amplitude, passo e velocidade pedida contra a do jogo. |
| `tools/criaturas/consertar_andar_do_lobo.py` | Blender: religa as pernas do lobo aos alvos de IK e grava a pose nos ossos (Walk, Run), cria o Idle e refaz a morte, direto no `lobo.glb`. |
| `tools/criaturas/refazer_andar_emprestado.py` | Blender: refaz Walk, WalkSlow e Run da ovelha, porco, cão e javali a partir da vaca (cascos por IK na escala de cada bicho; no cão, giro reduzido). |
| `tools/criaturas/preparar_galinha_e_coelho.py` | Blender: prepara a galinha e o coelho novos (CC0) a partir dos .blend originais. |
| `tools/capturar_mapa.gd` | Foto do mapa do mundo (tecla M).  godot --path . --resolution 1280x720 --script res://tools/capturar_mapa.gd |
| `tools/drone_auditoria.gd` | Varredura completa do mundo, sem o Torin: grade de raios sobre todo o mapa, água contra terreno, começo e fim de cada rio, |
| `tools/teste_animais_obstaculos.gd` | Animais colados na cerca e nas casas vagam por 40 s de jogo (tempo acelerado 4x): nenhum pode atravessar. |
| `tools/teste_caca.gd` | O lobo ataca gente e bicho de fazenda de verdade: o NPC é mordido (se encolhe, reclama), foge para casa e volta ao trabalho quando o |
| `tools/teste_bordas.gd` | A beirada de cada região não pode ser um degrau: o Torin entra andando nas 8 regiões pelos 4 lados (96 entradas) e não pode parar na linha da borda. |
| `tools/capturar_ilha.gd` | Fotos da ILHA (mapa novo): planta de cima, vistas aéreas, praia, reino e o mapa da tecla M; também prova o tubarão (avisa e mata). |
| `tools/mundo/encher_o_mundo.py` | Sorteia lugares para povoados novos e traça a Estrada da Costa, conferindo mar, rio, região e vizinhos; escreve em `mundo_dados.gd` (bloco GERADO). |
| `tools/auditoria_reino.gd` | AUDITORIA DO REINO: casa enterrada/flutuando, sobre rua, encavalada, colada na muralha, portão entupido, ser dentro de parede. Relatório em docs/auditoria/REINO_<data>.md. |
| `tools/capturar_reino.gd` | Fotos do REINO (muralha, portão sul, bairro, mercado, feira, rua do anel e vistas aéreas), em tools/capturas/reino/. |
| `tools/planta_do_mapa.py` | Desenha a PLANTA do mapa novo (ilha de 3 x 3 km, reino no centro) em docs/mapa-novo/, para aprovar antes de construir. |
| `tools/teste_camera_casa.gd` | A câmera de 3ª pessoa dentro da casa do Vane: 8 combinações de giro e inclinação, com captura e verificação numérica. |
| `tools/teste_cartaz.gd` | Cartaz lido com E abre a cena de diálogo com todas as linhas; os NPCs novos (Pomar, Ferrogris) existem e falam. |
| `tools/teste_casas.gd` | Teste de física das casas do Refúgio: um corpo do tamanho do jogador (capsula de 0,35 x 1,8 m) tenta |
| `tools/teste_fagulha.gd` | As três fases do Fagulha em jogo real: tamanho e cor, voo, ataque, montaria e a troca de fase pelas missões C1-M4, C2-M3 e C3-M4. |
| `tools/teste_fagulha_ambientes.gd` | O Fagulha nas 3 fases em campo aberto, mata fechada, ponte e junto de uma casa fechada: nunca fica dentro de parede/tronco, acompanha |
| `tools/teste_inventario.gd` | Inventário na cena principal, com teclas de verdade: I abre, clique seleciona, Enter usa, Esc/I fecham. |
| `tools/teste_medo.gd` | NPCs fogem para dentro das casas quando um monstro chega perto, e voltam quando passa o perigo. |
| `tools/teste_montaria_dano.gd` | Testa, na cena principal e com janela: (1) golpe em vaca, ovelha e NPC, (2) montar o cavalo, andar, correr e desmontar, |
| `tools/teste_moveis.gd` | Na cena principal: o jogador entra na Cabana1 pela porta e não atravessa o baú nem a mesa. |
| `tools/teste_mundo.gd` | Mundo contínuo, sem janela: regiões, povoados com gente e animais, fauna coerente, e o horário dos NPCs (vão para casa à noite |
| `tools/teste_queda.gd` | Rede de segurança: jogar o Torin para fora do mundo e ver se ele volta ao chão firme. |
| `tools/teste_rio.gd` | Rios: o jogador fica de pé em cima da ponte (não atravessa o tabuleiro) e consegue estar dentro da água rasa (pisa no leito). |
| `tools/teste_rotinas.gd` | Sem janela, em tempo acelerado (8x): cada NPC cumpre a rotina? Mede distância andada, animações vistas e se ficou preso. |
| `tools/teste_simulacao.gd` | Simulação de física e combate, medindo onde os corpos ficam de verdade (não é foto): |
| `tools/teste_solidos.gd` | O jogador anda de frente contra cada coisa sólida do Refúgio e tem que ficar do lado de cá dela: |
| `tools/teste_sono.gd` | À noite os NPCs vão dormir na cama (deitados, dentro da casa) e de manhã voltam; o Torin dorme e amanhece. |

## Documentos em docs/

| Arquivo | Título |
|---|---|
| `docs/HISTORIA-E-MISSOES.md` | Reino de Cinzas (Sangue e Escamas): história, missões, cidades e povoados |
| `docs/INVENTARIO-DE-DEFEITOS.md` | Inventário de defeitos de 24/11/2026 (lista única, com foto ou medida de cada um; fotos em `docs/inventario/`) |
| `docs/mapa-novo/construcao_v1/` e `construcao_v2/` | Fotos da ilha construída: v1 = ilha de 4,6 km; v2 = ilha de 7,45 x 5,6 km com o mapa (tecla M) em estilo antigo |
| `docs/mapa-novo/reino_v2/` | Fotos do reino pronto (19 fotos: portões, ruas, travessa, bairro, mercado, feira, quartel, estábulos, pedra de perto, castelo, aéreas e mapa) |
| `docs/mapa-novo/reino_v1/` | Fotos do reino grande, primeira versão (muralha, 3 portões, 17 bairros, mercados e feiras) |
| `docs/mapa-novo/PLANO-REINO-100.md` | Plano aprovado para entregar o reino inteiro (9 blocos com critério de pronto e o que fica de fora) |
| `docs/mapa-novo/PLANTA_v1.md` | Planta do mapa novo, versão 1: tamanho, lugares, temas e o que fica para depois |
| `docs/LEIS-DO-JOGO.md` | Leis do jogo (Reino de Cinzas) |
| `docs/MAPA-DO-TRABALHO.md` | Mapa do trabalho (gerado lendo os arquivos em 23/11/2026; atualizar quando criar algo novo) |
| `docs/SESSAO-2026-11-23.md` | Sessão de 22 e 23/11/2026: o que foi feito, os erros e o que falta |
| `docs/ajustes/LEIA-ME.md` | Fotos dos ajustes (itens ajustados) |
| `docs/ajustes/LISTA.md` | Lista dos ajustes (item por item) |
| `docs/auditoria/AJUSTES_LISTA.md` | Lista dos ajustes (item por item) |
| `docs/auditoria/CAMPANHA_JOGAVEL.md` | Campanha jogável (agente de controle, teclas reais) |
| `docs/auditoria/ETAPA_10.md` |  |
| `docs/auditoria/ETAPA_2.md` |  |
| `docs/auditoria/ETAPA_3.md` |  |
| `docs/auditoria/ETAPA_4.md` |  |
| `docs/auditoria/ETAPA_5_6.md` |  |
| `docs/auditoria/ETAPA_7.md` |  |
| `docs/auditoria/ETAPA_8.md` |  |
| `docs/auditoria/ETAPA_9.md` |  |
| `docs/auditoria/PERCURSO_REAL_2026-11-24.md` | Percurso real de 24/11: os 6 trechos do Refúgio ao Castelo, onde o agente parou e por quê |
| `docs/auditoria/PERCURSO_REAL.md` | Percurso real (agente andando, sem teleporte entre regiões) |
| `docs/auditoria/PERCURSO_REAL_PROGRESSO.md` | Percurso real: progresso (atualizado a cada 15 s) |
| `docs/auditoria/PRECISAO_estab.md` | Varredura de alta precisão — estab |
| `docs/auditoria/PRECISAO_estab2.md` | Varredura de alta precisão — estab2 |
| `docs/auditoria/PRECISAO_final.md` | Varredura de alta precisão — final |
| `docs/auditoria/RELATORIO_FINAL_ESTABILIZACAO.md` | Relatório final da rodada de estabilização |
| `docs/auditoria/RELATORIO_baseline.md` | Relatório de auditoria — baseline |
| `docs/auditoria/RELATORIO_estab1.md` | Relatório de auditoria — estab1 |
| `docs/auditoria/RELATORIO_estab2.md` | Relatório de auditoria — estab2 |
| `docs/auditoria/RELATORIO_estab3.md` | Relatório de auditoria — estab3 |
| `docs/auditoria/RELATORIO_estab4.md` | Relatório de auditoria — estab4 |
| `docs/auditoria/RELATORIO_estab5.md` | Relatório de auditoria — estab5 |
| `docs/auditoria/RELATORIO_etapa2.md` | Relatório de auditoria — etapa2 |
| `docs/auditoria/RELATORIO_etapa2b.md` | Relatório de auditoria — etapa2b |
| `docs/auditoria/RELATORIO_etapa2c.md` | Relatório de auditoria — etapa2c |
| `docs/auditoria/RELATORIO_etapa2d.md` | Relatório de auditoria — etapa2d |
| `docs/auditoria/RELATORIO_etapa2e.md` | Relatório de auditoria — etapa2e |
| `docs/auditoria/RELATORIO_etapa2f.md` | Relatório de auditoria — etapa2f |
| `docs/auditoria/RELATORIO_etapa2g.md` | Relatório de auditoria — etapa2g |
| `docs/auditoria/RELATORIO_etapa2h.md` | Relatório de auditoria — etapa2h |
| `docs/auditoria/RELATORIO_etapa2i.md` | Relatório de auditoria — etapa2i |
| `docs/auditoria/RELATORIO_etapa3a.md` | Relatório de auditoria — etapa3a |
| `docs/auditoria/RELATORIO_etapa3c.md` | Relatório de auditoria — etapa3c |
| `docs/auditoria/RELATORIO_etapa3d.md` | Relatório de auditoria — etapa3d |
| `docs/auditoria/RELATORIO_etapa3e.md` | Relatório de auditoria — etapa3e |
| `docs/auditoria/RELATORIO_etapa3f.md` | Relatório de auditoria — etapa3f |
| `docs/auditoria/RELATORIO_etapa4.md` | Relatório de auditoria — etapa4 |
| `docs/auditoria/RELATORIO_etapa5.md` | Relatório de auditoria — etapa5 |
| `docs/auditoria/RELATORIO_etapa5b.md` | Relatório de auditoria — etapa5b |
| `docs/auditoria/RELATORIO_etapa7.md` | Relatório de auditoria — etapa7 |
| `docs/auditoria/RELATORIO_etapa9.md` | Relatório de auditoria — etapa9 |
| `docs/auditoria/RELATORIO_final.md` | Relatório de auditoria — final |
| `docs/auditoria/RELATORIO_final2.md` | Relatório de auditoria — final2 |
| `docs/auditoria/RELATORIO_final3.md` | Relatório de auditoria — final3 |
| `docs/auditoria/RELATORIO_final4.md` | Relatório de auditoria — final4 |

## Capturas e fotos

- tools/capturas/: 528 imagens (prefixos: lobo_ = bancada antiga do lobo, jogavel_ = agente de teclado, drone_final_ = varredura, percurso_ = percurso real, pontos_ = fotos de pontos do mundo). Fora do git.
- docs/validacao/: evidências por tema (armas, casas, fagulha, personagens, refúgio...).
- docs/ajustes/: fotos antes/depois dos 11 itens ajustados + LISTA.md dos 271 itens. As fotos dos outros 260 (NÃO ajustados) ficam só em ~/Desktop/ajustes/ e se refazem com tools/bancada.gd.

## Pendências abertas (nenhuma foi resolvida)

- LOBO: corpo ainda alongado demais; olhos levemente assimétricos; conferir ao lado do Torin.
- TEXTURA e ANIMAÇÃO de todos os animais (cavalo, vaca, ovelha, porco, cão, galinha...).
- Galinha, dragões (filhote, Ignis, Fagulha) e gente: sem olhos conferidos.
- Árvores (galhos, cor), grama, drops no chão (carne), casas repetidas, vilas: só fotografados.
- Mapa corredor norte-sul: o usuário pediu mundo aberto com diversidade e mandou uma referência (ainda não localizada).
- Percurso real Refúgio→Castelo: REPROVADO, o Torin trava em x=-160 indo para o leste vindo do Pomar (o chão sobe de 0 a 1,9 m entre x=-160 e x=-148). Causa não confirmada.
- `teste_caca` INSTÁVEL (já no commit 456cf7d): o lobo às vezes não ataca a vaca no curral. Defeito real, não corrigido.
- Junção dos rios (-308,87) e (-337,-54): funcional, irregular.
- Branch reconstrucao: NÃO fundida.
