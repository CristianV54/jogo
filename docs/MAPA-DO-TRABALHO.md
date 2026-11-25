# Mapa do trabalho (gerado lendo os arquivos em 23/11/2026; atualizar quando criar algo novo)

Regra: arquivo novo entra aqui na mesma hora. Capturas e relatórios dizem de qual teste vieram.

Ponto de entrada: [README.md](../README.md) e [CLAUDE.md](../CLAUDE.md). Relato completo da última sessão: [SESSAO-2026-11-23.md](SESSAO-2026-11-23.md).

## Testes e ferramentas em tools/ (primeira linha de comentário de cada um)

| Arquivo | Para que serve |
|---|---|
| `tools/abrir_com_lobo.gd` | Abre o jogo normal (janela jogável) com um lobo a 4 m do Torin. Não fecha sozinho. |
| `tools/auditar_colisao.gd` | Auditoria: toda malha "grande" (>= 0,7 m de base e >= 0,5 m de altura, abaixo de 2,6 m) de cada área precisa ter colisão |
| `tools/auditoria_buracos.gd` | Acha buracos no chão do mundo (pontos sem chão sob eles) e confere a borda. Grade de 3 m sobre todo o mundo + 40 m de margem. |
| `tools/auditoria_cercos.gd` | Auditoria de cercos do mundo aberto, sem janela. Anda numa grade de 4 m (cápsula do jogador; ligações conferidas com raio): |
| `tools/auditoria_continua.gd` | Auditoria do mundo contínuo, sem janela. Constrói o mundo inteiro e confere, andando com a cápsula do jogador: |
| `tools/auditoria_logica.gd` | Auditoria de LÓGICA do mundo (sem janela): o que está no lugar errado em relação ao resto, em todas as regiões e povoados. |
| `tools/auditoria_mundo.gd` | Auditoria do mundo, sem janela: para cada área confere |
| `tools/auditoria_portais.gd` | Todo portal leva a uma área que existe, a um spawn que existe, e a área de destino tem portal de volta. |
| `tools/bancada.gd` | BANCADA: mundo plano e vazio que fotografa cada item do jogo sozinho (frente, lado e costas; parado e andando quando tem animação), |
| `tools/bancada_movimento.gd` | BANCADA DE MOVIMENTO: 6 quadros de cada animação de cada ser (vista de lado) e medidas de amplitude, passo e velocidade pedida contra a do jogo. |
| `tools/criaturas/consertar_andar_do_lobo.py` | Blender: religa as pernas do lobo aos alvos de IK e grava a pose nos ossos (Walk, Run), cria o Idle e refaz a morte, direto no `lobo.glb`. |
| `tools/criaturas/refazer_andar_emprestado.py` | Blender: refaz Walk, WalkSlow e Run da ovelha, porco, cão e javali a partir da vaca (cascos por IK na escala de cada bicho; no cão, giro reduzido). |
| `tools/bancada_candidatos.gd` | Fotografa modelos baixados (4 vistas e até 6 animações) ANTES de entrarem no jogo; lê tools/capturas/candidatos/. |
| `tools/criaturas/preparar_galinha_e_coelho.py` | Blender: prepara a galinha e o coelho novos (CC0) a partir dos .blend originais. |
| `tools/calibrar_arma.gd` | Fotografa uma arma segurada de 8 jeitos (direção da lâmina x torção do cabo) e imprime o giro de cada um. |
| `tools/calibrar_punho.gd` | Com a orientação da lâmina já escolhida, varre o ponto do punho (x e y no espaço de hand_r) e fotografa de 2 ângulos. |
| `tools/campanha_jogavel.gd` | Agente de controle: joga o jogo pela janela, só com teclas de verdade (Input.parse_input_event), região por região: teleporte F1..F8, |
| `tools/capturar_aberto.gd` | Fotos do mundo aberto: poço, menino Nilo, espada nas costas correndo, povoados livres, crista com vão e barreira, mata. |
| `tools/capturar_agua.gd` | Fotos dos rios.  godot --path . --resolution 1280x720 --script res://tools/capturar_agua.gd |
| `tools/capturar_capim.gd` | Fotos do capim em vários biomas.  godot --path . --resolution 1280x720 --script res://tools/capturar_capim.gd |
| `tools/capturar_cartazes.gd` | Cartazes, estátua e NPCs novos.  godot --path . --resolution 1280x720 --script res://tools/capturar_cartazes.gd |
| `tools/capturar_casas.gd` | Fotos das casas de vários povoados e regiões.  godot --path . --resolution 1280x720 --script res://tools/capturar_casas.gd |
| `tools/capturar_castelo.gd` | Fotos do castelo e da cidade.  godot --path . --resolution 1280x720 --script res://tools/capturar_castelo.gd |
| `tools/capturar_clima.gd` | Fotos do clima no Refúgio: alvorecer, meio-dia, pôr do sol, noite, chuva e tempestade (com relâmpago). |
| `tools/capturar_costa.gd` | Fotos da costa.  godot --path . --resolution 1280x720 --script res://tools/capturar_costa.gd |
| `tools/capturar_lobo_jogo.gd` | Lobo no mundo, ao lado do Torin (para ver o tamanho).  godot --path . --resolution 1280x720 --script res://tools/capturar_lobo_jogo.gd |
| `tools/capturar_mapa.gd` | Foto do mapa do mundo (tecla M).  godot --path . --resolution 1280x720 --script res://tools/capturar_mapa.gd |
| `tools/capturar_mundo.gd` | Fotos do mundo contínuo: povoados, fazendas, estrada com ponte, mata do corredor, divisa entre regiões, vista aérea e o mapa. |
| `tools/capturar_noite.gd` | Refúgio à noite com chuva: gente dormindo, torre, capim.  godot --path . --resolution 1280x720 --script res://tools/capturar_noite.gd |
| `tools/capturar_plantacao.gd` | Fotos das plantações: Refúgio, Fazenda Campina e Vila Campos Altos.  godot --path . --resolution 1280x720 --script res://tools/capturar_plantacao.gd |
| `tools/capturar_ui.gd` | Captura a interface do jogo: mapa do mundo, caixa de diálogo (letra a letra e completa) e marcador "?" sobre o NPC. |
| `tools/diag_borda.gd` | Diagnóstico: anda de verdade rumo ao leste a partir de x=-175 (estrada do Pomar) e imprime onde o Torin trava. |
| `tools/diag_frente_lobo.gd` | Mede, sem olho, para onde o lobo olha: direção cabeça-menos-rabo no mundo contra a frente do corpo (-Z) usada pelo ataque e pelo movimento. |
| `tools/diag_ossos.gd` | Lista, por criatura, os ossos e onde está cada um (no modelo em repouso), para posicionar olhos e conferir tamanhos. |
| `tools/drone_auditoria.gd` | Varredura completa do mundo, sem o Torin: grade de raios sobre todo o mapa, água contra terreno, começo e fim de cada rio, |
| `tools/drone_fotos.gd` | Fotos de cada região pelo Drone (câmera livre): visão aérea, entrada, centro e borda. Uma folha de contato por região |
| `tools/drone_pontos.gd` | Fotos do Drone em pontos escolhidos (coordenadas do relatório da auditoria): de cima, em ângulo e de perto. |
| `tools/drone_povoados.gd` | Fotos do Drone de todos os povoados: uma folha por povoado (aérea, entrada, centro e detalhe) em tools/capturas/povoado_<etapa>_<id>.png. |
| `tools/drone_precisao.gd` | Varredura de alta precisão (passo de 1,5 m) só nas áreas críticas: ao longo de cada rio (faixa de 14 m de cada lado), em volta de |
| `tools/drone_rios.gd` | Fotos de todos os rios do mundo pelo Drone: 3 pontos por rio (começo, meio, fim), cada um de cima e de perto. |
| `tools/medir_arma.gd` | Mede armas importadas no espaço da RAIZ da instância (o nó filho da malha vem girado pelo importador). |
| `tools/medir_punho.gd` | Centro do punho fechado: centroide dos vértices da luva ligados à mão direita e aos dedos, no espaço de hand_r. |
| `tools/percurso_real.gd` | Agente de percurso real: anda de verdade (W + Shift, sem teleporte entre regiões) do Refúgio ao Castelo, com idas ao Pomar Alto e ao Bosque |
| `tools/perfil.gd` | Perfil de desempenho em janela: anda pelo mundo e imprime fps, tempo de física/processo e chamadas de desenho. |
| `tools/perfil2.gd` | Anda pela estrada dos campos a 8 m/s e mede os picos de quadro (hitches), que é o que o jogador sente como "trava". |
| `tools/perfil3.gd` | (sem descrição: precisa de uma) |
| `tools/perfil4.gd` | (sem descrição: precisa de uma) |
| `tools/perfil_aberto.gd` | Desempenho do mundo aberto em janela: fps, tempo de física e desenho em pontos típicos (com a floresta em blocos). |
| `tools/teste_animais_obstaculos.gd` | Animais colados na cerca e nas casas vagam por 40 s de jogo (tempo acelerado 4x): nenhum pode atravessar. |
| `tools/teste_caca.gd` | O lobo ataca gente e bicho de fazenda de verdade: o NPC é mordido (se encolhe, reclama), foge para casa e volta ao trabalho quando o |
| `tools/teste_bordas.gd` | A beirada de cada região não pode ser um degrau: o Torin entra andando nas 8 regiões pelos 4 lados (96 entradas) e não pode parar na linha da borda. |
| `tools/capturar_ilha.gd` | Fotos da ILHA (mapa novo): planta de cima, vistas aéreas, praia, reino e o mapa da tecla M; também prova o tubarão (avisa e mata). |
| `tools/mundo/encher_o_mundo.py` | Sorteia lugares para povoados novos e traça a Estrada da Costa, conferindo mar, rio, região e vizinhos; escreve em `mundo_dados.gd` (bloco GERADO). |
| `tools/auditoria_reino.gd` | AUDITORIA DO REINO: casa enterrada/flutuando, sobre rua, encavalada, colada na muralha, portão entupido, ser dentro de parede. Relatório em docs/auditoria/REINO_<data>.md. |
| `tools/capturar_reino.gd` | Fotos do REINO (muralha, portão sul, bairro, mercado, feira, rua do anel e vistas aéreas), em tools/capturas/reino/. |
| `tools/planta_do_mapa.py` | Desenha a PLANTA do mapa novo (ilha de 3 x 3 km, reino no centro) em docs/mapa-novo/, para aprovar antes de construir. |
| `tools/teste_cadeia.gd` | Cadeia de missões do jogo inteiro: começa no zero, cumpre os objetivos de cada missão pelos eventos reais e confere que |
| `tools/teste_camera_casa.gd` | A câmera de 3ª pessoa dentro da casa do Vane: 8 combinações de giro e inclinação, com captura e verificação numérica. |
| `tools/teste_cartaz.gd` | Cartaz lido com E abre a cena de diálogo com todas as linhas; os NPCs novos (Pomar, Ferrogris) existem e falam. |
| `tools/teste_casas.gd` | Teste de física das casas do Refúgio: um corpo do tamanho do jogador (capsula de 0,35 x 1,8 m) tenta |
| `tools/teste_cena.gd` | Roteiro automático da cena de teste (precisa de janela, para capturar tela): |
| `tools/teste_fagulha.gd` | As três fases do Fagulha em jogo real: tamanho e cor, voo, ataque, montaria e a troca de fase pelas missões C1-M4, C2-M3 e C3-M4. |
| `tools/teste_fagulha_ambientes.gd` | O Fagulha nas 3 fases em campo aberto, mata fechada, ponte e junto de uma casa fechada: nunca fica dentro de parede/tronco, acompanha |
| `tools/teste_inventario.gd` | Inventário na cena principal, com teclas de verdade: I abre, clique seleciona, Enter usa, Esc/I fecham. |
| `tools/teste_jogo.gd` | Jogada completa automatizada (precisa de janela, para capturar tela): |
| `tools/teste_marco3.gd` | Marco 3 ponta a ponta, sem janela: C1-M2, C1-M3 e C1-M4 pelo fluxo real (interação, entrega, combate, montaria, zonas). |
| `tools/teste_marco4.gd` | Marco 4 ponta a ponta, sem janela: C2-M1 a C2-M4 no Bosque Velado e na Mina das Correntes. |
| `tools/teste_marco5.gd` | Marco 5 ponta a ponta, sem janela: C3-M1 a C3-M4 no Acampamento da Ruptura e na Fortaleza de Ferrogris. |
| `tools/teste_marco6.gd` | Marco 6 ponta a ponta, sem janela: C4-M1 a C4-M4 na Cratera de Ignis. |
| `tools/teste_marco7.gd` | Marco 7 ponta a ponta, sem janela: C5-M1 a C5-M4 em Valdoria e no Castelo Imperial. |
| `tools/teste_medo.gd` | NPCs fogem para dentro das casas quando um monstro chega perto, e voltam quando passa o perigo. |
| `tools/teste_missoes.gd` | Fluxo real da missão C1-M1, sem janela: falar com Vane e Brenn, bater 3x no boneco, acender 3 tochas, receber a recompensa. |
| `tools/teste_missoes_dados.gd` | Valida as 20 missões contra o mundo de verdade: cadeia de pré-requisitos, e para cada objetivo se existe no mundo o que o cumpre |
| `tools/teste_montaria_dano.gd` | Testa, na cena principal e com janela: (1) golpe em vaca, ovelha e NPC, (2) montar o cavalo, andar, correr e desmontar, |
| `tools/teste_moveis.gd` | Na cena principal: o jogador entra na Cabana1 pela porta e não atravessa o baú nem a mesa. |
| `tools/teste_mundo.gd` | Mundo contínuo, sem janela: regiões, povoados com gente e animais, fauna coerente, e o horário dos NPCs (vão para casa à noite |
| `tools/teste_pulo.gd` | O jogador pula PARA CIMA: parado, sobe ~1,4 m e desce no mesmo lugar; correndo, mantém o avanço. Conferido com física real. |
| `tools/teste_queda.gd` | Rede de segurança: jogar o Torin para fora do mundo e ver se ele volta ao chão firme. |
| `tools/teste_rio.gd` | Rios: o jogador fica de pé em cima da ponte (não atravessa o tabuleiro) e consegue estar dentro da água rasa (pisa no leito). |
| `tools/teste_rotinas.gd` | Sem janela, em tempo acelerado (8x): cada NPC cumpre a rotina? Mede distância andada, animações vistas e se ficou preso. |
| `tools/teste_simulacao.gd` | Simulação de física e combate, medindo onde os corpos ficam de verdade (não é foto): |
| `tools/teste_solidos.gd` | O jogador anda de frente contra cada coisa sólida do Refúgio e tem que ficar do lado de cá dela: |
| `tools/teste_sono.gd` | À noite os NPCs vão dormir na cama (deitados, dentro da casa) e de manhã voltam; o Torin dorme e amanhece. |
| `tools/testes_areas_carregam.gd` | Carrega cada área e confere: sem erro de script, chefe criado, spawns e portal de volta existentes. |
| `tools/testes_cena_carrega.gd` | Só carrega a cena de teste e confere que os nós e as ligações existem. Sai com erro se faltar algo. |
| `tools/testes_inspeciona_cena.gd` | Imprime a árvore (até 4 níveis) e um caminho de trilha de animação de cada cena passada como argumento. |
| `tools/ver_animais.gd` | Põe os animais lado a lado, toca uma animação em cada um, mede altura/comprimento e fotografa. |
| `tools/ver_area.gd` | Fotografa uma área de câmeras escolhidas à mão. |
| `tools/ver_bosque_animais.gd` | Cervo, urso, coelho e corvo lado a lado, de perfil e de três quartos. |
| `tools/ver_cabelos.gd` | Todos os personagens com cabelo, lado a lado, em pleno rolamento: o cabelo tem que acompanhar a cabeça. |
| `tools/ver_cenario.gd` | Fotografa um personagem em vários ângulos, inclusive rente ao piso, e mede altura e pés. |
| `tools/ver_correndo_jogo.gd` | Foto do Torin correndo no jogo, de trás e de lado.  godot --path . --resolution 1280x720 --script res://tools/ver_correndo_jogo.gd |
| `tools/ver_dialogo.gd` | Abre falas longas e fotografa a caixa de diálogo.  godot --path . --resolution 1280x720 --script res://tools/ver_dialogo.gd |
| `tools/ver_escala.gd` | Torin ao lado dos dragões, na escala real do jogo: Fagulha, Filhote de Asa e Ignis-Maw. |
| `tools/ver_espada.gd` | Fotografa o Torin correndo e parado (espada sempre na mão), de costas, de lado e de frente. |
| `tools/ver_fagulha_fases.gd` | Fotografa o Fagulha nas 3 fases (em campo aberto, na mata e perto de uma casa).  godot --path . --resolution 1280x720 --script res://tools/ver_fagulha_fases.gd |
| `tools/ver_fogo.gd` | Fogo isolado, com e sem fumaça, sobre fundo escuro e fundo claro. |
| `tools/ver_itens.gd` | Os quatro itens de drop lado a lado, no tamanho que aparecem no jogo (escala 1,8). |
| `tools/ver_lobo.gd` | Fotografa o lobo em cada animação.  godot --path . --resolution 900x600 --script res://tools/ver_lobo.gd |
| `tools/ver_pelagens.gd` | 6 indivíduos de cada espécie, para conferir a variação de cor e a textura de pelo. |
| `tools/ver_personagem.gd` | Fotografa um personagem em vários ângulos, inclusive rente ao piso, e mede altura e pés. |
| `tools/ver_porta.gd` | Uma casa com a porta fechada e depois aberta (um "jogador" fantasma se aproxima). |
| `tools/ver_sono.gd` | Fotos de NPCs dormindo, por dentro da casa.  godot --path . --resolution 1280x720 --script res://tools/ver_sono.gd |

## Documentos em docs/

| Arquivo | Título |
|---|---|
| `docs/HISTORIA-E-MISSOES.md` | Reino de Cinzas (Sangue e Escamas): história, missões, cidades e povoados |
| `docs/INVENTARIO-DE-DEFEITOS.md` | Inventário de defeitos de 24/11/2026 (lista única, com foto ou medida de cada um; fotos em `docs/inventario/`) |
| `docs/mapa-novo/construcao_v1/` e `construcao_v2/` | Fotos da ilha construída: v1 = ilha de 4,6 km; v2 = ilha de 7,45 x 5,6 km com o mapa (tecla M) em estilo antigo |
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
