# Mapa do trabalho

Índice de tudo o que há no repositório e para que serve, refeito em 26/11/2026 lendo os arquivos. **Regra: arquivo novo entra aqui na mesma hora.**

Ponto de entrada: [CLAUDE.md](../CLAUDE.md) (regras e estado atual) e [README.md](../README.md) (como rodar).

## 1. Documentos

| Arquivo ou pasta | O que é |
|---|---|
| `CLAUDE.md` | Regras de trabalho, como o usuário quer trabalhar e o estado atual do jogo. |
| `README.md` | Como rodar, teclas, pastas e comandos de conferência. |
| `assets/ASSETS.md` | Registro de cada modelo, animação e som: origem, licença, o que tem. |
| `docs/LEIS-DO-JOGO.md` | O que o jogo nunca pode quebrar e o teste de cada lei. |
| `docs/MAPA-DO-TRABALHO.md` | Este índice. |
| `docs/HISTORIA-E-MISSOES.md` | A campanha ANTIGA (5 capítulos, 20 missões). Está desligada no jogo; fica como referência até o usuário decidir a história nova. |
| `docs/construcoes/` | Uma pasta e um `.md` por peça construída: critério de pronto, resultado, fotos (01_... da bancada, 20_... de dentro do mundo) e pontos fracos. Peças: muralha, rua (e casa), feira, catedral, cidadela, quartel, povoados, acampamento, estradas, montanha dos dragões, terras do gelo, mapa. |
| `docs/galeria/` | 28 folhas com a foto de tudo o que o jogo tinha em 26/11 de manhã (antes dos dragões novos, das armaduras e do gelo). Refaz-se com `tools/montar_galeria.py`. |
| `docs/validacao/` | Provas por asset: armaduras, armas, câmera, casas, dragões, fagulha, personagens, tubarão. |
| `docs/mapa-novo/` | `PLANO-REINO-100.md` (plano e nomes de Valdoria), `IDEIAS-DO-CRISTIAN.md` (pedidos do usuário para depois), `reino_v4/` (fotos de Valdoria de 25/11). |
| `docs/auditoria/` | Relatórios de `tools/auditoria_reino.gd` (`REINO_<data>.md`). |
| `docs/historico/` | Registros de fases anteriores. Ler `docs/historico/LEIA.md`. Não descrevem o jogo de hoje. |

## 2. Testes e ferramentas (`tools/`)

### Os que valem hoje (rodar depois de mexer no mundo)

| Ferramenta | Para que serve |
|---|---|
| `tools/teste_mundo.gd` | O teste principal. Constrói o mundo e confere: regiões, estradas, povoados, Valdoria (muralha, casario, cidadela, rei, quartel, estábulos), Montanha dos Dragões (trilha, dragões, domar), Terras do Gelo, som, salvar e carregar, fome, equipar, comércio, forja, mineração, sono dos NPCs. |
| `tools/auditoria_reino.gd` | Auditoria de Valdoria: casa em cima de rua ou de casa, casa encostada na muralha, gente dentro de parede, portões livres. Relatório em `docs/auditoria/`. |
| `tools/capturar_reino.gd` | Fotos de dentro do jogo (Valdoria, povoados, montanha, gelo, tubarão, loja, inventário) em `tools/capturas/reino/`. Aceita filtro: `-- 02_ 50_`. |
| `tools/capturar_mapa.gd`, `tools/capturar_ilha.gd` | Fotos do mapa da tecla M e da ilha vista de cima, em `tools/capturas/ilha/`. |
| `tools/bancada_construcao.gd` | Monta UMA peça em chão plano com o Torin de régua, fotografa e testa: `-- muralha`, `rua`, `feira`, `catedral`, `quartel`, `acampamento`, `tubarao`, `dragoes`, `armaduras`. |
| `tools/bancada.gd` | Fotografa cada item do jogo sozinho (frente, lado, costas): `-- depois [filtro]`. |
| `tools/montar_galeria.py` | Junta as fotos das bancadas e das capturas nas folhas de `docs/galeria/`. |

### Testes de sistemas antigos

Rodados um por um em 26/11/2026, sem janela, com limite de 10 minutos cada (`godot --headless --path . --script res://tools/<teste>.gd`). Os que falham foram escritos para o mundo em corredor e para a campanha; **não foram revistos para a ilha**. Antes de confiar num deles, ler o que ele confere.

| Teste | Resultado | Leitura |
|---|---|---|
| `teste_moveis.gd` | PASSOU (3 de 3) | Vale. |
| `teste_queda.gd` | PASSOU (2 de 2) | Vale. |
| `teste_rotinas.gd` | PASSOU (9 de 9) | Vale. |
| `teste_simulacao.gd` | PASSOU (8 de 8) | Vale. |
| `teste_inventario.gd` | 20 de 21 nesta rodada | O item que falhou (vida 71 em vez de 70: a vida volta sozinha durante a espera) foi corrigido depois com tolerância; o teste foi atualizado para o jogo de hoje (começa com itens, 30 espaços, fome) e NÃO foi rodado de novo depois da correção. |
| `teste_solidos.gd` | 19 passaram, não terminou em 10 min | Sem falha vista; precisa de mais tempo para acabar. |
| `teste_fagulha_ambientes.gd` | 11 passaram, não terminou em 10 min | Idem. |
| `teste_bordas.gd` | não terminou em 10 min, nenhum resultado | Anda pelos 4 lados de cada região; é lento. Não se sabe se passa. |
| `teste_sono.gd` | 10 passaram, 2 FALHARAM | "À noite os NPCs deitam na cama: 1 de 7" e a parte de Valdoria (cita a cidade antiga). O primeiro pode ser defeito real: investigar. (`teste_mundo` confere que os trabalhadores se recolhem e isso passa.) |
| `teste_medo.gd` | 5 passaram, 1 FALHOU | "Com o lobo solto os NPCs entraram nas casas: 0 de 3". Pode ser defeito real: investigar. |
| `teste_caca.gd` | 3 passaram, 1 FALHOU | "O NPC mordido foge para casa". Já era instável antes da ilha. |
| `teste_rio.gd` | 1 passou, 2 FALHARAM | Confere uma ponte e um leito em coordenadas do mundo antigo. |
| `teste_cartaz.gd` | 6 passaram, 2 FALHARAM | Espera cartazes do Solon em Valdoria e na estátua, que saíram com a cidade antiga. |
| `teste_fagulha.gd` | 4 passaram, 8 FALHARAM | Confere as 3 fases da Fagulha trocadas pelas missões; com a história desligada ela já começa na fase 3. |
| `teste_montaria_dano.gd` | 2 passaram, 9 FALHARAM, não terminou | Foi feito para rodar COM janela (tira fotos) e procura a primeira vaca do mundo, que na ilha pode estar longe e parada. Golpear animal e montar NÃO estão cobertos por teste hoje. |
| `teste_camera_casa.gd` | erro: precisa de janela | Tira fotos; rodar com `xvfb-run` e `--rendering-driver opengl3`. |
| `teste_casas.gd`, `teste_animais_obstaculos.gd` | terminaram sem imprimir PASSOU nem FALHOU | Usam outro formato de saída; ler a saída inteira para julgar. |

### Todas as ferramentas (primeira linha de comentário de cada uma)

| Arquivo | Para que serve |
|---|---|
| `tools/audio/gerar_sons.py` | Gera TODOS os sons do jogo por síntese (nenhum arquivo baixado): |
| `tools/auditoria_reino.gd` | AUDITORIA DO REINO: |
| `tools/bancada.gd` | BANCADA: |
| `tools/bancada_construcao.gd` | BANCADA DE CONSTRUÇÃO: |
| `tools/bancada_movimento.gd` | BANCADA DE MOVIMENTO: |
| `tools/capturar_ilha.gd` | Fotos da ILHA (mapa novo): |
| `tools/capturar_mapa.gd` | Fotos do mapa do mundo (tecla M): inteiro, com destino marcado, com zoom, e o facho do destino dentro do jogo.  godot --path . --resolution 1280x720 --script res://tools/capturar_mapa.gd |
| `tools/capturar_reino.gd` | Fotos do REINO (Valdoria grande): |
| `tools/criaturas/consertar_andar_do_lobo.py` | Conserta as animações do lobo JÁ exportado (assets/models/criaturas/lobo/lobo.glb), sem precisar do FBX original. |
| `tools/criaturas/converter_animais_e_armas.py` | Converte para .glb: |
| `tools/criaturas/converter_tubarao.py` | Converte o tubarão-martelo CC0 (Phelippeau Rudy, OpenGameArt "Shark - low poly") para .glb com uma animação "Swim" em laço (a cauda e o corpo ondulam de lado). |
| `tools/criaturas/gerar_animais.py` | Gera os animais do jogo a partir do pacote Farm Animals (Quaternius, CC0), só leitura. |
| `tools/criaturas/gerar_criaturas.sh` | Gera criaturas e armas. Uso (na raiz do projeto): zsh tools/criaturas/gerar_criaturas.sh |
| `tools/criaturas/gerar_galinha.py` | Modela a galinha (low-poly, cor chapada, ~0,4 m): |
| `tools/criaturas/gerar_lobo.py` | Gera o lobo do jogo a partir do Wolf do "Animal Pack Vol.2" (Quaternius, CC0, baixado de opengameart.org/content/animated-animales-low-poly). |
| `tools/criaturas/listar_modelo.gd` | Lista o que há dentro de modelos 3D importados: |
| `tools/criaturas/preparar_galinha_e_coelho.py` | Prepara a galinha e o coelho novos (CC0, Snabisch / OpenGameArt) para o jogo, a partir dos .blend originais: |
| `tools/criaturas/refazer_andar_emprestado.py` | Refaz o andar que a ovelha, o porco, o cão e o javali pegaram emprestado da vaca (Walk, WalkSlow e Run). |
| `tools/drone_auditoria.gd` | Varredura completa do mundo, sem o Torin: |
| `tools/fagulha/captura.gd` | Uso: godot --path . --script res://captura.gd -- NomeDaAnimacao arquivo.png segundos Toca a animação explicitamente (com loop) e fotografa o que o Godot desenha. |
| `tools/fagulha/medir_frente.gd` | Mede para onde a cabeça do Fagulha aponta (cabeça menos pélvis, em metros, no espaço do modelo). |
| `tools/fagulha/medir_loop.gd` | Sem gambiarra: carrega o glb como o jogo carregaria e confere nomes, loop, cor do vértice, escala e se cada animação fecha o ciclo (pose do último quadro vs. primeiro, em graus). |
| `tools/fagulha/preparar_fagulha.py` | Prepara o Fagulha a partir do dragão rigado de ~/Downloads (só leitura): |
| `tools/itens/gerar_itens.py` | Modela os itens que os animais deixam ao morrer (carne, couro, lã, presa), em low-poly de cor chapada, no mesmo estilo dos outros assets. |
| `tools/itens/gerar_itens_de_oficio.py` | Modela os itens de ofício e as armaduras (moeda, minério e lingote de ferro, madeira, pão, peixe assado, picareta, peitoral e ombreira de couro e de ferro), no mesmo estilo dos outros itens (formas simples, sombreado suave). |
| `tools/montar_galeria.py` | Monta a GALERIA: |
| `tools/mundo/encher_o_mundo.py` | Enche a ilha: |
| `tools/personagens/gerar_todos.sh` | Gera os humanoides jogáveis e de história a partir dos pacotes CC0 do Quaternius (só leitura) e importa no Godot. Uso (na raiz do projeto):  zsh tools/personagens/gerar_todos.sh |
| `tools/personagens/montar_personagem.py` | Monta um personagem humanoide a partir dos pacotes CC0 do Quaternius (só leitura): |
| `tools/planta_do_mapa.py` | Desenha a PLANTA do mapa novo (ilha de 3 x 3 km, reino no centro), para aprovar no papel antes de construir no jogo. |
| `tools/teste_animais_obstaculos.gd` | Animais colados na cerca e nas casas vagam por 40 s de jogo (tempo acelerado 4x): nenhum pode atravessar. godot --path . --resolution 800x450 --script res://tools/teste_animais_obstaculos.gd |
| `tools/teste_bordas.gd` | A beirada de cada região não pode ser um degrau: |
| `tools/teste_caca.gd` | O lobo ataca gente e bicho de fazenda de verdade: |
| `tools/teste_camera_casa.gd` | A câmera de 3ª pessoa dentro da casa do Vane: 8 combinações de giro e inclinação, com captura e verificação numérica. godot --path . --resolution 960x540 --script res://tools/teste_camera_casa.gd |
| `tools/teste_cartaz.gd` | Cartaz lido com E abre a cena de diálogo com todas as linhas; os NPCs novos (Pomar, Ferrogris) existem e falam. godot --headless --path . --script res://tools/teste_cartaz.gd |
| `tools/teste_casas.gd` | Teste de física das casas do Refúgio: |
| `tools/teste_fagulha.gd` | As três fases do Fagulha em jogo real: tamanho e cor, voo, ataque, montaria e a troca de fase pelas missões C1-M4, C2-M3 e C3-M4. godot --headless --path . --script res://tools/teste_fagulha.gd |
| `tools/teste_fagulha_ambientes.gd` | O Fagulha nas 3 fases em campo aberto, mata fechada, ponte e junto de uma casa fechada: |
| `tools/teste_inventario.gd` | Inventário na cena principal, com teclas de verdade: I abre, clique seleciona, Enter usa, Esc/I fecham. godot --path . --resolution 1280x720 --script res://tools/teste_inventario.gd |
| `tools/teste_medo.gd` | NPCs fogem para dentro das casas quando um monstro chega perto, e voltam quando passa o perigo. godot --headless --path . --script res://tools/teste_medo.gd |
| `tools/teste_montaria_dano.gd` | Testa, na cena principal e com janela: |
| `tools/teste_moveis.gd` | Na cena principal: o jogador entra na Cabana1 pela porta e não atravessa o baú nem a mesa. godot --path . --resolution 1280x720 --script res://tools/teste_moveis.gd |
| `tools/teste_mundo.gd` | Mundo contínuo, sem janela: |
| `tools/teste_queda.gd` | Rede de segurança: jogar o Torin para fora do mundo e ver se ele volta ao chão firme. godot --headless --path . --script res://tools/teste_queda.gd |
| `tools/teste_rio.gd` | Rios: o jogador fica de pé em cima da ponte (não atravessa o tabuleiro) e consegue estar dentro da água rasa (pisa no leito). godot --headless --path . --script res://tools/teste_rio.gd |
| `tools/teste_rotinas.gd` | Sem janela, em tempo acelerado (8x): cada NPC cumpre a rotina? Mede distância andada, animações vistas e se ficou preso. godot --headless --path . --script res://tools/teste_rotinas.gd |
| `tools/teste_simulacao.gd` | Simulação de física e combate, medindo onde os corpos ficam de verdade (não é foto): |
| `tools/teste_solidos.gd` | O jogador anda de frente contra cada coisa sólida do Refúgio e tem que ficar do lado de cá dela: |
| `tools/teste_sono.gd` | À noite os NPCs vão dormir na cama (deitados, dentro da casa) e de manhã voltam; o Torin dorme e amanhece. godot --headless --path . --script res://tools/teste_sono.gd |

`tools/capturas/` é saída de ferramenta e fica fora do git (ver `.gitignore`).

## 3. Scripts do jogo (`scripts/`)

### `scripts/camera/`

| Arquivo | Classe | Para que serve |
|---|---|---|
| `camera_terceira_pessoa.gd` | CameraTerceiraPessoa | Câmera em 3ª pessoa: gira em volta do alvo com o mouse e fica atrás dele. O braço (SpringArm3D) encurta sozinho quando algo fica entre a câmera e o alvo. |

### `scripts/criaturas/`

| Arquivo | Classe | Para que serve |
|---|---|---|
| `acessorios.gd` | Acessorios | Peças que transformam um modelo existente em outro bicho: |
| `animal_vila.gd` | AnimalVila | Animal de vila/fazenda: |
| `corvo.gd` | Corvo | Corvo pousado num poste ou galho. |
| `domar_dragao.gd` | DomarDragao | O gesto de domar: com E, perto do dragão pousado no ninho. Custa 3 carnes; sem elas o dragão rosna e nada acontece. |
| `dragao_selvagem.gd` | DragaoSelvagem | Dragão selvagem da Montanha dos Dragões. |
| `fagulha.gd` | Fagulha | Fagulha acompanha o alvo: parado perto, andando a distância média, correndo quando longe. Tecla F alterna o voo (sobe e paira em cima do alvo). O modelo olha para +Z (medido com a cabeça e a pélvis). |
| `montaria.gd` | Montaria | Faz de uma criatura (filho direto do dono) algo que o jogador monta. |
| `olhos.gd` | Olhos | Olhos para os bichos dos pacotes (que vêm sem olho). |
| `tubarao.gd` | Tubarao | O mar em volta da ilha tem dono. |
| `variacao_de_cores.gd` | VariacaoDeCores | Cada animal sai com uma pelagem diferente: |

### `scripts/importacao/`

| Arquivo | Classe | Para que serve |
|---|---|---|
| `post_importar_fagulha.gd` | - | Roda toda vez que o Godot importa o dragão. |
| `post_importar_ual.gd` | - | Roda quando o Godot importa a Universal Animation Library (CC0, Quaternius). Extrai as animações para uma biblioteca reutilizável por qualquer humanoide com o mesmo esqueleto (65 ossos). |

### `scripts/inimigos/`

| Arquivo | Classe | Para que serve |
|---|---|---|
| `inimigo.gd` | Inimigo | Inimigo genérico, serve de criatura comum e de chefe: |

### `scripts/interface/`

| Arquivo | Classe | Para que serve |
|---|---|---|
| `hud.gd` | Hud | Interface do jogo, desenhada por código: |
| `mapa_do_mundo.gd` | MapaDoMundo | Mapa do mundo (tecla M): |
| `painel_de_oficio.gd` | PainelDeOficio | Janela de COMÉRCIO e de FORJA (uma lista de botões no meio da tela; clica-se com o mouse, Esc fecha). |
| `painel_inventario.gd` | PainelInventario | Janela do inventário: |
| `pintura_do_mapa.gd` | PinturaDoMapa | Pinta a imagem do mapa do mundo (tecla M) como mapa de JOGO: |

### `scripts/jogador/`

| Arquivo | Classe | Para que serve |
|---|---|---|
| `jogador.gd` | Jogador | Corpo do jogador (Torin): |

### `scripts/jogo/`

| Arquivo | Classe | Para que serve |
|---|---|---|
| `admin.gd` | Admin | Ferramentas de teste e auditoria, separadas do jogo normal (nó filho do Jogo; não toca no gameplay): |
| `drone.gd` | Drone | Drone de auditoria: |
| `itens.gd` | Itens | Catálogo dos itens do jogo: |
| `jogo.gd` | Jogo | Cena principal: |
| `pickup.gd` | Pickup | Item largado no chão (carne, couro, lã, presa): gira e flutua, e o jogador o recolhe ao chegar perto. |
| `salvar_jogo.gd` | SalvarJogo | SALVAR O JOGO: |

### `scripts/missoes/`

| Arquivo | Classe | Para que serve |
|---|---|---|
| `dados_missoes.gd` | DadosMissoes | Catálogo das missões da campanha (Bíblia de Reino de Cinzas). |
| `gerenciador_missoes.gd` | GerenciadorMissoes | Rastreia as missões: |

### `scripts/mundo/`

| Arquivo | Classe | Para que serve |
|---|---|---|
| `acampamento_ruptura.gd` | - | Acampamento da Ruptura (Capítulo III): |
| `ancora_de_obelisco.gd` | AncoraDeObelisco | Âncora do obelisco: |
| `area_aberta.gd` | AreaAberta | Base das áreas grandes ao ar livre dos capítulos III em diante: |
| `area_base.gd` | AreaBase | Base de toda área do mundo. |
| `barreira.gd` | Barreira | Barreira de história no corredor entre duas regiões: |
| `biomas.gd` | Biomas | Biomas do mundo: |
| `boneco_de_treino.gd` | BonecoDeTreino | Boneco de treino: |
| `bosque_velado.gd` | - | Bosque Velado e Mina das Correntes (Capítulo II). |
| `calcamento_do_reino.gd` | CalcamentoDoReino | O CHÃO DA CIDADE: |
| `cama.gd` | Cama | Cama de uma casa. |
| `capim_do_mundo.gd` | CapimDoMundo | Capim e mato em todo o chão do mundo (dentro e fora das regiões), gerado em blocos de 40 m em volta do jogador e descartado quando ele se afasta. |
| `carrinho_de_minerio.gd` | CarrinhoDeMinerio | Carrinho de minério sobre trilhos. |
| `cartaz.gd` | Cartaz | Cartaz, carta ou inscrição que o Torin lê com E: |
| `casario_do_reino.gd` | CasarioDoReino | O CASARIO DE VALDORIA, com a planta do Reino de Aethelgard que o Cristian tinha feito em blocos: |
| `catedral.gd` | Catedral | A CATEDRAL DE VALDORIA, gótica: |
| `cela_trancada.gd` | CelaTrancada | Cela de ferro de Ferrogris com cativos dentro (civis, soldados ou um dragão jovem). |
| `cesto_virado.gd` | CestoVirado | Cesto de colheita tombado pelo vento, com maçãs espalhadas. Aperte E para endireitá-lo. |
| `cidadela.gd` | Cidadela | A CIDADELA DE VALDORIA, no alto do penhasco (planta do Reino de Aethelgard que o Cristian tinha feito em blocos): |
| `clima.gd` | Clima | Ciclo de dia e noite, céu, sol, lua, nuvens, chuva e tempestade. |
| `colisores_de_arvores.gd` | ColisoresDeArvores | Troncos sólidos sob demanda. |
| `construtor_casa.gd` | ConstrutorCasa | Monta uma casa a partir das peças modulares do Medieval Village MegaKit (CC0, Quaternius). |
| `costa.gd` | Costa | Costa da ilha. |
| `cratera_ignis.gd` | - | Cratera de Ignis (Capítulo IV): |
| `efeitos.gd` | Efeitos | Efeitos visuais curtos e sem estado. |
| `estaca_de_ferro_negro.gd` | EstacaDeFerroNegro | Estaca de Ferro Negro cravada no pinhal, prendendo o dragão por correntes. Precisa de 3 puxadas (E, E, E) para sair; a cada puxada afunda e o brilho azul enfraquece. Conta para a missão a cada puxada. |
| `fabrica_natureza.gd` | FabricaNatureza | Árvores, pedras e arbustos procedurais, pintados por vértice (sem textura): um estilo só, leves e fáceis de espalhar. Todos os modelos têm a base em y = 0 e os eixos de um objeto em pé. |
| `fachadas.gd` | Fachadas | Pinturas das casas do casario de Valdoria, desenhadas por código (uma vez) e aplicadas em cada face da casa: |
| `fagulha_ferida.gd` | FagulhaFerida | Ponto de interação ao lado da Fagulha ferida na clareira: alimentá-la com carne conta para o resgate. |
| `fauna_do_mundo.gd` | FaunaDoMundo | Bichos coerentes com cada região e cada trecho de estrada do mundo contínuo: |
| `fogo.gd` | Fogo | Fogo de verdade: |
| `fornalha_negra.gd` | FornalhaNegra | Fornalha negra da Cratera de Ignis. |
| `fronteira_ferrogris.gd` | - | Fortaleza de Ferrogris (Capítulo III). |
| `gatilho.gd` | Gatilho | Interagível genérico: ao apertar E chama `ao_usar(este_gatilho)`. Se `uma_vez` for falso, pode ser usado de novo (o código que o criou pode zerar `usado`). Quem cria desenha o visual como filho. |
| `horizonte.gd` | Horizonte | Fecha o mundo de cada área com o que existe além da borda: |
| `interagivel.gd` | Interagivel | Objeto do mundo que o jogador aciona com E quando está perto (tocha, quadro, cesto, jaula...). |
| `interagivel_aviso.gd` | InteragivelAviso | Interagível que só mostra uma mensagem (porta trancada, placa...). Reutilizável: define `mensagem` e `texto`. |
| `jaula_de_filhote.gd` | JaulaDeFilhote | Jaula de ferro com um Filhote de Asa preso. |
| `macieira_colhivel.gd` | MacieiraColhivel | Macieira do Pomar Alto: tronco, copa e maçãs visíveis. Cada E colhe uma maçã (vai para o inventário) até acabarem. |
| `montanha_dos_dragoes.gd` | MontanhaDosDragoes | O que há na Montanha dos Dragões (o chão é do terreno, ver MundoDados.montanha): |
| `mundo.gd` | Mundo | O mundo contínuo: |
| `mundo_dados.gd` | MundoDados | Planta do mundo contínuo (coordenadas do MUNDO, em metros; norte = -Z; o centro do reino fica perto de 0, 0). |
| `muralha_do_reino.gd` | MuralhaDoReino | A muralha de Valdoria: |
| `navegacao_local.gd` | NavegacaoLocal | Malha de navegação de um povoado ou cidade: |
| `obelisco.gd` | Obelisco | O primeiro obelisco de Ferro Negro: |
| `pas_do_moinho.gd` | PasDoMoinho | As pás de um moinho de vento: giram devagar em volta do eixo (Z local). |
| `pecas_da_muralha.gd` | PecasDaMuralha | AS PEÇAS DA MURALHA de Valdoria: |
| `pecas_da_rua.gd` | PecasDaRua | AS PEÇAS DA RUA de Valdoria: |
| `pecas_de_construcao.gd` | PecasDeConstrucao | Base dos kits de construção (muralha, rua...): |
| `pecas_do_gelo.gd` | PecasDoGelo | Peças das Terras do Gelo: a placa do Lago Congelado e os cristais de gelo. Bancada: tools/bancada_construcao.gd -- gelo. |
| `pecas_do_ninho.gd` | PecasDoNinho | Peças da Montanha dos Dragões: |
| `pedra.gd` | Pedra | Material de PEDRA para muralhas e torres: |
| `pilha_de_item.gd` | PilhaDeItem | Pilha de um item no chão (aço imperial no depósito, Ferro Negro bruto no acampamento): E recolhe `qtd` unidades. |
| `plantacao.gd` | Plantacao | Plantação de verdade: |
| `pomar_alto.gd` | - | Pomar Alto das Macieiras: |
| `ponte_de_madeira.gd` | PonteDeMadeira | Ponte de madeira sobre um rio: |
| `porta_casa.gd` | PortaCasa | Porta de casa: |
| `portal.gd` | Portal | Faixa invisível no chão: quando o jogador entra, pede a troca para outra área. |
| `portao.gd` | Portao | Portão de ferro de duas folhas. Fechado bloqueia a passagem; `abrir()` afasta as folhas e libera o caminho. |
| `povoado.gd` | Povoado | Povoado ou fazenda no caminho entre duas regiões (coordenadas do MUNDO). |
| `povoador.gd` | Povoador | Espalha pinheiros, pedras e arbustos sobre um Terreno: MultiMesh para o visual e cilindros para os troncos próximos. |
| `quadro_de_avisos.gd` | QuadroDeAvisos | Quadro de avisos da praça: duas estacas e uma tábua com papéis. Mostra o próximo serviço disponível (ou por que ainda não pode ler). |
| `raiz_medicinal.gd` | RaizMedicinal | Raiz medicinal do Riacho da Névoa: ervas verdes sobre um bulbo claro. Aperte E para colher (vai para o inventário). |
| `refugio_do_pinhal.gd` | - | Refúgio do Pinhal: |
| `roda_dagua.gd` | RodaDagua | Roda d'água do moinho: aro de madeira com pás, gira devagar em torno do eixo X local. |
| `solidos.gd` | Solidos | Ajudantes para dar corpo sólido às coisas. |
| `terras_do_gelo.gd` | TerrasDoGelo | O que há nas Terras do Gelo (o chão e a neve são do terreno e do bioma "gelo"): |
| `terreno.gd` | Terreno | Terreno procedural pintado por vértice (grama, mata, terra, pedra). Plano e limpo numa clareira central (0, 0), com colinas fora dela e caminhos de terra. |
| `terreno_mundo.gd` | TerrenoMundo | Chão do mundo contínuo: |
| `teste_casa.gd` | - | Cena de calibração: uma casa de 3x4 módulos (6x8 m) para conferir frontão, janelas, porta e interior por captura. |
| `tocha_de_treino.gd` | TochaDeTreino | Tocha do pátio de treino: poste de madeira com uma cesta de ferro. Aperte E para acendê-la (chama pequena e luz). |
| `vegetacao_rasteira.gd` | VegetacaoRasteira | Dá vida ao chão de uma clareira: |
| `veio_de_ferro.gd` | VeioDeFerro | Veio de ferro na rocha: |
| `vida_das_ruas.gd` | VidaDasRuas | O que dá vida às ruas de Valdoria (tirado do Reino de Aethelgard de blocos do Cristian): |
| `vila_refugio.gd` | VilaRefugio | Construções da vila do Refúgio do Pinhal que não são casas: |
| `zona_de_calor.gd` | ZonaDeCalor | Retângulo de lava no chão: desenha a lava e queima o jogador que pisa nela (a cada `intervalo`). Pontes e passarelas ficam acima de `altura_max` e são seguras; só quem anda no chão, embaixo, queima. |
| `zona_de_evento.gd` | ZonaDeEvento | Zona invisível: |

### `scripts/personagens/`

| Arquivo | Classe | Para que serve |
|---|---|---|
| `criatura.gd` | Criatura | Criatura com animações no próprio modelo (dragões e animais). O nó filho "Modelo" é o .glb importado. Mesma interface do Humanoide (tocar, tem), para o Inimigo tratar os dois do mesmo jeito. |
| `humanoide.gd` | Humanoide | Qualquer personagem humano montado com o esqueleto de 65 ossos (Universal Base Characters + trajes). |
| `npc.gd` | Npc | Personagem não jogável: |

### `scripts/som/`

| Arquivo | Classe | Para que serve |
|---|---|---|
| `sons.gd` | Sons | O SOM DO JOGO. |

## 4. Pendências

### Não existe ainda
- Nadar (o Torin anda no fundo do mar), cortar árvore, lança, elmo e perneira, neve caindo, minimapa.
- Dragões que atacam ou reagem ao Torin; Cinza não segue o Torin depois de domado.
- Mais de um golpe, bloqueio, arco.
- História nova (o usuário vai pensar) e a retirada do código da campanha antiga (`scripts/missoes/` e as partes de missão das 6 regiões).
- Modelos próprios: cervo (usa o do cavalo), arqueiro, guarda imperial e Kaelor (mesmo boneco), chefes.

### Nunca conferido
- Golpear animal e montar cavalo ou dragão: o teste antigo (`teste_montaria_dano.gd`) não roda mais; nada confere isso hoje.
- Se os NPCs ainda dormem na cama e fogem para casa: `teste_sono.gd` e `teste_medo.gd` falham nesses itens (ver a tabela da seção 2).
- O jogo no Mac do usuário: desempenho, tempo da primeira abertura, cor da água, linha d'água do tubarão.
- O som: gerado por síntese, testado só por contagem; ninguém ouviu.

### Pontos fracos anotados em cada peça

**cidadela** (`docs/construcoes/cidadela.md`)
- Alto da rampa (foto 21): o muro de arrimo novo esconde a rocha, mas o calçamento ainda faz calombos onde a rampa encontra o patamar (o chão é uma grade de 4 m).
- Palácio e prédios do pátio ainda são caixas com fachada pintada (sem o relevo que as casas da cidade ganharam).
- A cidadela não tem bancada própria: só foi vista dentro do mundo.

**estradas** (`docs/construcoes/estradas.md`)
- Só uma ponte foi vista em foto; nenhum marco nem pouso foi fotografado de perto.
- O tabuleiro da ponte continua o de antes (tábuas e corrimão simples).
- Não há placa de direção nos cruzamentos.

**mapa** (`docs/construcoes/mapa.md`)
- Dois nomes de região se encostam no sul (Refúgio do Pinhal e Acampamento da Ruptura).
- O mapa mostra tudo desde o começo: não há "descobrir" regiões.
- Não há minimapa durante o jogo.

**montanha dos dragoes** (`docs/construcoes/montanha_dos_dragoes.md`)
- Os dragões selvagens só voam em círculo ou ficam parados: não atacam nem reagem ao Torin.
- Cinza, depois de domado, fica onde o Torin desmonta (não segue como a Fagulha).
- A encosta é lisa de perto (cor por faixas, sem pedras soltas nem vegetação de altitude).
- O mapa da tecla M desenha a montanha (foto `36_no_mapa.jpg`); depois da foto o nome desceu para baixo dos picos (batia no nome da Vila Pedras Altas) e essa posição nova não foi fotografada.

**povoados** (`docs/construcoes/povoados.md`)
- Só 5 dos 92 povoados (contando os postos) foram vistos em foto; os outros usam as mesmas posições, mas o terreno e as casas variam.
- A cabana do pescador da foto não tem água à vista (o cais só aparece quando há rio a menos de 70 m).
- O terreiro ainda é uma mancha de cor lisa de longe (o capim nasce por cima); no posto rebelde lê-se como lama escura.
- As casas dos povoados (modelos prontos) não têm calçada nem cerca de quintal.

**rua** (`docs/construcoes/rua.md`)
- Braseiro do portão é um bloco laranja; topo da muralha faz degrau em ladeira.
- Só a fachada da rua tem relevo; laterais e fundos das casas só pintados; casas de esquina mostram a lateral para a avenida.
- Sem calçada nas esquinas e travessas; sem varal entre casas.
- A casa não tem bancada própria (foi conferida só dentro do mundo).

**terras do gelo** (`docs/construcoes/terras_do_gelo.md`)
- A neve sai azulada na foto (foi escurecida porque o branco puro estourava ao sol); conferir no Mac.
- Não cai neve; as árvores não têm neve em cima; as casas da vila são as mesmas das outras vilas.
- No mapa, o nome "TERRAS DO GELO" ficava cortado pela faixa de cima; foi descido e a posição nova NÃO foi fotografada.
- Não há bicho próprio do gelo.
