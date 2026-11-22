# Registro de assets

Regra: só entra em `assets/models/` o que foi validado. Todo asset tem origem, licença, estilo conferido e o que tem de rig/animação. O que faltar fica listado como pendência.

## criaturas/fagulha/fagulha.glb

- **O que é:** Fagulha, dragão jovem aliado do Torin. Corpo de dragão adulto em escala grande (21/11/2026, a pedido: dragão é grande): envergadura 10,7 m, altura 2,1 m, comprimento 7,6 m (Torin tem 1,8 m).
- **Origem:** arquivo `Dragon_Baked_Actions.blend`, vindo de `~/Downloads` (usuário). Autor e página de origem **não conhecidos**. O arquivo original não está no repositório (só o `.glb` derivado).
- **Licença:** "gratuita", segundo o usuário (informado em 21/11/2026). **Termos exatos não confirmados** (uso comercial, crédito ao autor, redistribuição). Pendência: confirmar antes de publicar o jogo.
- **Como foi gerado:** `tools/fagulha/preparar_fagulha.py` abre o `.blend` (só leitura), pinta a cor por região em cor de vértice (o original não tinha nenhuma textura ligada), renomeia as ações com sufixo `-loop` e exporta o `.glb` sem aplicar escala.
- **Importação (Godot 4.7):** `fagulha.glb.import` com `nodes/root_scale=0.07`; `scripts/importacao/post_importar_fagulha.gd` liga a cor do vértice nos materiais e recorta/fecha os ciclos das animações.
- **Malha:** 1 malha, 37.985 triângulos, 3 materiais (corpo, membrana, olhos).
- **Esqueleto:** 136 ossos (5 raízes: `pelvic_2` e 4 de pés/mãos).
- **Animações (todas em loop):** `Walk` 3,29 s, `Run` 1,63 s, `Idle` 22,75 s, `Fly` 2,5 s (recorte dos quadros 52 a 112 do clipe original, que é decolar/voar/pousar).
- **Estilo conferido:** parcial. Cores em paleta de ember pintada suave; a forma ainda é a de um dragão adulto, não "3D suave pintado" final.
- **Validação (21/11/2026):** `tools/fagulha/medir_loop.gd` (nomes, loop, cor, escala, emenda de ciclo) e capturas em `docs/validacao/fagulha/` e geradas por `tools/fagulha/captura.gd`. Sem revisor independente.
- **Pendências:**
  - Confirmar autor e termos da licença.
  - Proporção de filhote (cabeça maior, corpo mais curto): hoje só foi reduzido.
  - Animações de combate e reação: mordida, garra, cauda, fogo, rugido, dano, morte, decolar, pousar, pular, curvas.
  - Pesos nas juntas conferidos só em poucas poses.
  - Textura pintada à mão (hoje é cor de vértice).

## personagens/torin, vane, brenn (humanoides, Fase A)

- **O que são:** Torin (protagonista, traje Ranger sem capuz, cabelo castanho), Vane (líder do bando, traje Ranger com capuz e ombreira, 7% maior) e Brenn (ferreira, traje Peasant feminino, cabelo preso, 3% menor). Cada um tem 1 esqueleto de 65 ossos e 8 a 10 malhas (cabeça, olhos, sobrancelha, traje, cabelo).
- **Origem e licença:** pacotes do Quaternius em **CC0 (domínio público)**, texto de licença dentro de cada pacote em `~/jogo-trabalho/baixados/`: *Universal Base Characters* (corpo-base, pele), *Modular Character Outfits - Fantasy* (trajes Ranger e Peasant) e cabelos do pacote base. Os pacotes originais não estão no repositório.
- **Como foram gerados:** `tools/personagens/montar_personagem.py` (um personagem) e `tools/personagens/gerar_todos.sh` (os três + importação). O corpo-base é recortado para só cabeça e pescoço (o traje cobre o resto), as peças são presas ao mesmo esqueleto, as texturas caem de 4K para 1024 e saem em PNG (o Godot 4.7 recusou os JPEG de cor deste pacote).
- **Animações:** nenhuma no próprio arquivo. Vêm da biblioteca compartilhada abaixo, porque o esqueleto é idêntico (65 de 65 ossos com o mesmo nome, conferido).
- **Scripts e cenas:** `scripts/personagens/humanoide.gd` liga o modelo à biblioteca e tinge o cabelo; `scenes/personagens/{torin,vane,brenn}.tscn`.
- **Medido no Godot:** Torin com 1,84 m de altura e pé a -0,004 m do piso; elenco lado a lado e câmera rente ao chão em `docs/validacao/personagens/`.
- **Estilo conferido:** parcial. Texturas pintadas estilizadas do pacote, mais realistas que "suave pintado" final.
- **Pendências:** variações de pele (Torin saiu com a pele escura padrão do pacote de trajes), arma e escudo (nenhum modelo de espada ainda), rosto e cabelo mais variados para NPCs, peso de arquivo (cada .glb tem 9 a 13 MB).

## animacoes/ual (biblioteca compartilhada)

- **Origem e licença:** *Universal Animation Library (Standard)*, Quaternius, **CC0**. Texto em `assets/animations/ual/LICENSE_CC0_Quaternius.txt`.
- **Conteúdo:** 43 animações (19 em loop, 24 de disparo único). Loop: `Idle`, `Walk`, `Jog_Fwd`, `Sprint`, `Crouch_*`, `Jump`, `Idle_Talking`, `Sitting_*`, `Swim_*`, `Dance`, `Push`, `Pistol_Idle`, `Spell_Simple_Idle`... Disparo único: `Sword_Attack`, `Sword_Idle`, `Punch_Jab`, `Punch_Cross`, `Hit_Chest`, `Hit_Head`, `Death01`, `Roll`, `Jump_Start`, `Jump_Land`, `Interact`, `PickUp_Table`, `Spell_Simple_Shoot`...
- **Importação:** `scripts/importacao/post_importar_ual.gd` extrai a biblioteca para `ual1_biblioteca.res`. O Godot já tira o sufixo `_Loop` e liga o loop sozinho.
- **Pendência:** só existe um golpe de espada (`Sword_Attack`) e nenhuma animação de escudo, arco ou cavalgada.

## Cena de teste (cenário de depuração)

- `scenes/teste/cena_teste.tscn`: chão plano, céu procedural, 4 pilares `MARCO_*` (só para ver o movimento), câmera 3ª pessoa, Torin e Fagulha. O chão e os pilares são cenário de depuração, não arte final.

## cenario/vila_mv (kit de vila, Fase B)

- **Origem e licença:** *Medieval Village MegaKit (Standard)*, Quaternius, **CC0** (`assets/models/cenario/vila_mv/LICENSE_CC0_Quaternius.txt`). 176 peças modulares em glTF: paredes, cantos, pisos, portas, janelas, telhados, escadas, cercas, caixas, carroça, chaminé.
- **Ajuste feito:** texturas reduzidas de 4K para 1024 (de 153 MB para 22 MB). Medidas conferidas: parede de 2 m x 3,12 m, piso de 2 x 2 m, telhado `Roof_RoundTiles_LxP` em metros.
- **Uso:** `scripts/mundo/construtor_casa.gd` monta casas por módulos (porta no meio da fachada +Z, janelas intercaladas, cantos, telhado automático, colisão em bloco).
- **Casas (revisão 21/11/2026):** frontões fechados (`Roof_Front_BrickN`), janelas com esquadria e venezianas abertas, porta com batente e folha aberta, colisão só nas paredes com vão de 1,7 m na porta (dá para entrar), luz e móveis por dentro (moradia: cama, mesa, banco, caixas; forja: fornalha com brasa, bigorna, bancada). Teste de física: `tools/teste_casas.gd`.
- **Pendência:** os móveis são caixas simples (sem modelo); só os estilos madeira e pedra foram usados; as janelas não abrem; sem escadas nem segundo andar.

## Natureza procedural (Fase B)

- `scripts/mundo/fabrica_natureza.gd`: pinheiro, pedras, arbusto e toras gerados por código, pintados por vértice (sem textura), para manter um estilo só e permitir milhares de instâncias via MultiMesh. Não são arquivos de modelo; nada a baixar.
- `scripts/mundo/terreno.gd`: terreno com clareira plana e colinas por ruído, cor por vértice (grama, mata, terra de caminho, pedra nas encostas).
- **Pendência:** pinheiros e pedras são simples (poucos polígonos); sem variação de espécie, sem vento.

## personagens/gorath, kaelor, solon (chefes humanos) e NPCs menores

- **O que são:** Gorath (bruto, base Peasant escalada 1,75x, clava), Kaelor (traje Ranger tingido de aço, ombreira, espada longa, 1,2x), Solon (traje Ranger tingido de roxo imperial, ombreira, katana, 1,25x). NPCs: Dorn (lenhador), Orin (vigia), Tessa (cozinheira), Mira (caçadora, capuz).
- **Origem e licença:** mesmos pacotes CC0 do Quaternius (base, trajes, cabelos). Gerados por `tools/personagens/gerar_todos.sh`.
- **Tamanho de arquivo:** NPCs com texturas de 512 (3,7 a 6 MB), chefes com 768 (6,6 a 8,6 MB).
- **Pendência:** os chefes são variações de cor e escala dos mesmos corpos: falta silhueta própria (armadura pesada do Kaelor, coroa e manto do Solon, tamanho e feições do Gorath). Revisão visual manual recomendada.

## armas/ (shortsword, longsword, club, katana, simpleaxe)

- **Origem:** *MedievalPack* do Quaternius (a licença CC0 consta no catálogo `pacotes_livres/CATALOGO.md` do SSD; o pacote em si não traz arquivo de licença). Convertidas de OBJ para glb por `tools/criaturas/converter_animais_e_armas.py`, com a textura religada.
- **Calibração na mão (revisão 21/11/2026):** a primeira calibração estava errada: eu assumia o cabo no eixo Y, mas o importador gira o nó da malha 90° em X, então o cabo fica em **+Z da raiz** (espadas) e a katana é invertida (lâmina para +Z). Agora cada cena usa o **centro do punho medido na malha da luva** `(-0,017, 0,098, 0,006)` (`tools/medir_punho.gd`), o **centro do cabo medido na raiz da arma** (`tools/medir_arma.gd`) e o giro escolhido olhando 8 candidatos (`tools/calibrar_arma.gd`). Espada curta e guarda: giro (180,0,0), cabo (0,0,0,8), escala 0,25; espada longa: (180,0,0), cabo (0,0,0,78), 0,2; katana: (0,0,0), cabo (0,0,-0,65), 0,2; clava: (0,0,-90), cabo (0,0,1,0), 0,32. Os dedos não são animados, então o punho é o mesmo em todas as animações.
- **Pendência:** `simpleaxe.glb` foi convertida e não é usada; não há escudo.

## criaturas/ (Filhote de Asa, Ignis-Maw, Javali, Lobo)

- **Filhote de Asa e Ignis-Maw:** o mesmo dragão rigado do Fagulha (origem e licença ainda por confirmar, ver Fagulha) com outras paletas de cor de vértice (`PALETA=verde` e `PALETA=corrompido` em `tools/fagulha/preparar_fagulha.py`). Escalas medidas: Filhote de Asa 1,8 m de envergadura; Ignis-Maw 24,4 m de envergadura, 4,9 m de altura (escala_visual 8). Têm Idle, Walk, Run e Fly de verdade; não têm animação de ataque nem de morte (o ataque é uma investida, a morte é tombar e afundar).
- **Lobo-cinza e Javali Couraçado (versão 1, 21/11/2026; deixam de ser `PLACEHOLDER_`):** feitos sobre o cachorro (pug) e o porco do pacote *Farm Animals* (Quaternius, CC0) por `tools/criaturas/gerar_animais.py`. Têm Idle, Walk, WalkSlow, Run, Jump e Death (animação transplantada da vaca). O **lobo** ganhou focinho comprido, nariz escuro, orelhas pontudas e rabo, em cinza; o **javali** ganhou presas de marfim, crina de cerdas no dorso e corpo marrom escuro. As peças novas são presas aos ossos (Head, Torso, Hips), então acompanham a animação. Limite: o corpo do lobo ainda é atarracado como o do pug (parece um husky grande); um lobo magro e de pernas longas pede modelo novo.

## criaturas/ animais de vila e fazenda (vaca, cavalo, ovelha, porco, cão)

- **Origem e licença:** *Farm Animals* do Quaternius (CC0, catálogo `pacotes_livres/CATALOGO.md` do SSD), FBX convertido por `tools/criaturas/gerar_animais.py` (Blender, só leitura do original). Estilo: low-poly de cores chapadas, o mesmo do kit de cenário.
- **Animações:** vaca e cavalo vêm com Idle, Walk, WalkSlow, Run, Jump e Death. Ovelha, porco, cão, lobo e javali só vinham com Idle e Jump; como o esqueleto é o mesmo (muda só a cauda), a rotação de cada osso do Walk, WalkSlow, Run e Death da vaca é copiada quadro a quadro. Isso dá um andar de quadrúpede plausível, mas não é afinado para cada espécie (pé pode deslizar um pouco).
- **Correção necessária:** os materiais do FBX vêm com alfa 0 (o animal fica invisível no Godot); o script força alfa 1 e opaco.
- **Escala (`nodes/root_scale` no `.import`):** vaca 0,27 (1,4 m), cavalo 0,28 (1,9 m), ovelha 0,23 (1,0 m), porco 0,17 (0,8 m), cão 0,25 (corrigido no Marco 4: o esqueleto do cão tem escala própria de 0,4 e o cão posado era 2,1x maior que a medida da malha; hoje ~0,55 m), lobo 0,7, javali 0,2.
- **No jogo:** `scripts/criaturas/animal_vila.gd` (perambula e para, sem colisão), colocados em `refugio_do_pinhal.gd` (`_animais()`): 2 vacas e 3 ovelhas no pasto sul, 2 porcos a oeste da casa do Vane, 2 cavalos a oeste, 1 cão perto da forja. Velocidades de passo estimadas a olho, não calibradas contra o ciclo da animação.
- **Ainda não existem:** galinha, cervo, urso, coelho, aves, peixes, aranha, wyvern menor, cão de guerra do Império. No Downloads há `Free+Pack+-+Lowpoly+Animal` (urso, gato, cabra, canguru etc., sem rig nem animação, licença não conferida) e `horse.glb` do Sketchfab (28 animações, licença não conferida), ainda não usados.

## Jogo (Fases B a D): o que existe e o que é provisório

- **Áreas:** Refúgio do Pinhal (hub, 6 NPCs, 2 portais), Bosque Velado (Gorath), Fortaleza de Ferrogris (Kaelor), Cratera de Ignis (Ignis-Maw) e Valdoria (Solon). As quatro arenas são geradas pelo mesmo `scripts/mundo/arena_chefe.gd` com estilos diferentes. Valdoria é só um pátio murado com um salão, não uma cidade.
- **Progresso:** cada chefe derrotado libera o próximo caminho; sem o chefe a passagem fica bloqueada com aviso.
- **Interface:** barras de vida, nome da área, diálogo e mensagens desenhados por código com a fonte padrão do Godot. Provisório: falta fonte, arte e identidade visual.
- **Combate:** golpe de espada (J ou clique), rolamento com invulnerabilidade (Espaço), dano, reação, morte e recuperação lenta de vida. Um golpe só (`Sword_Attack`). Sem bloqueio, sem arco, sem magia, sem inventário nem forja.


## cenario/moveis/ (interior das casas)

- **Origem e licença:** *Fantasy Props MegaKit* (versão gratuita) do Quaternius, **CC0** (`License_Standard.txt` do pacote). Copiados do SSD (`pacotes_livres/comida_objetos_3d/quaternius_fantasy_props_megakit`), só os usados, em glTF com as texturas `T_Trim_*` (22 MB).
- **Peças usadas:** cama (Bed_Twin1/2), armário alto (Bookcase_2), cômoda (Cabinet), criado-mudo, baú, mesa grande, cadeira, banco, banquinho, barril, balde, saco, vela e candelabro, caneca, prato, panela, bigorna, bancada, arsenal (WeaponStand).
- **Uso:** `scripts/mundo/construtor_casa.gd` (`_moradia` e `_forja`). Cada móvel de porte tem uma caixa de colisão na camada 4 (o jogador colide, a câmera atravessa). A **forja** é geometria simples com a pedra do próprio kit (sem modelo de forja): base, borda, leito de carvão com brasas acesas, painel de fundo, pilares, coifa e chaminé até o teto, com chama baixa por dentro. Pode ganhar modelo próprio.
- **Validação:** `tools/teste_moveis.gd` (entrar pela porta, baú e mesa barram) e capturas do interior (casa de teste, forja e casa do Vane).

## Dano em animais e pessoas, e montaria (21/11/2026)

- **Dano:** o golpe do jogador (J ou clique) também acerta o grupo `atingiveis` (animais e NPCs). Animal: pisca em vermelho, perde vida, **foge** por 3 s e, a 0 de vida, toca Death e some depois de 12 s (vaca 40, cavalo 50, ovelha 20, porco 25, cão 20; golpe do Torin = 22). NPC: pisca, se encolhe (Hit_Chest) e protesta num balão de texto; **não perde vida nem morre** (são personagens da história). Código: `animal_vila.gd`, `npc.gd`, `efeitos.gd`.
- **Montaria (tecla E perto de um cavalo ou do Fagulha):** `scripts/criaturas/montaria.gd` + `jogador.gd` (`montar`, `desmontar`, `_mover_montado`). O corpo do jogador move a criatura; o cavaleiro fica sentado (Sitting_Idle) no osso do assento (`Torso` no cavalo, `paunch` no Fagulha). Cavalo: 6 m/s, galope com Shift a 13 m/s. Fagulha: no chão 6/12 m/s; **Espaço decola e sobe, C desce**, 16 m/s (28 com Shift) no ar; só desmonta pousado. Ao trocar de área o jogador desmonta do cavalo (ele fica na área velha); o Fagulha acompanha.
- **Limites conhecidos:** a colisão da montaria é a cápsula do jogador (o dragão atravessa copas de árvore e quinas de casa com as asas); sem sela nem rédeas; cavaleiro usa a pose de sentado genérica; sem pulo a cavalo.


## itens/ (drops dos animais) e efeitos (21/11/2026)

- **Itens de drop (carne, couro, lã, presa):** modelados por mim no Blender (`tools/itens/gerar_itens.py`), low-poly de cor chapada, ~0,25 m. Estilo conferido por captura (`tools/ver_itens.gd`). Origem própria, sem licença externa. O pacote Kenney de comida que eu pensava usar estava no SSD, que desmontou; por isso foram feitos à mão e podem ser trocados por modelos melhores. Carne e couro são os mais legíveis; a lã e a presa são formas muito simples.
- **Drops:** vaca (carne 2-3, couro 1), cavalo (carne, couro 1-2), ovelha (carne 1-2, lã 1-2), porco (carne 2-3), cão (couro 1), lobo (carne 1, couro 1-2), javali (carne 2-3, presa 1-2). Os itens giram e flutuam, o jogador os recolhe ao chegar a 1,8 m, e a lista aparece no canto direito da tela. Código: `scripts/jogo/pickup.gd`, `jogador.coletar`, `hud.item_coletado`. O inventário só conta; ainda não há uso (cozinhar, forjar, vender).
- **Corpo some:** 5 s depois da morte o corpo encolhe numa nuvem de poeira (`Efeitos.desintegrar`) e é liberado.
- **Pelagem:** `scripts/criaturas/variacao_de_cores.gd` troca, por indivíduo, as cores do pacote por uma escolha ao acaso de uma paleta por espécie (vaca, cavalo, ovelha, porco, cão, lobo, javali) e põe uma textura de pelo (ruído triplanar). Cavalos saem castanhos, pretos, cinzas, brancos, baios; vacas manchadas em várias cores; etc.
- **Fogo:** `scripts/mundo/fogo.gd` (partículas de CPU: labareda, miolo quente, fumaça, fagulhas e luz que tremula). Na fogueira queima o jogador (6 de dano a cada 0,7 s dentro de 0,8 m); na forja é só visual. Textura da bola de fogo é um gradiente radial gerado por código.
- **Portas:** `scripts/mundo/porta_casa.gd`. A folha gira na dobradiça (100°), abre sozinha a 2,8 m do jogador e fecha a 3,8 m; fechada, bloqueia o vão. Só o jogador (grupo `jogador`) as abre.
- **Chão vivo:** `scripts/mundo/vegetacao_rasteira.gd` (34 manchas de cor, moitas de capim, 14 anéis de flores e flores soltas) no Refúgio.
- **Montaria:** animação de subir (Sitting_Enter com salto até o assento) e de descer (Sitting_Exit), e o cavalo pula (Espaço, 1,7 m). Cavaleiro usa Sitting_Enter/Idle/Exit do pacote de animações.
- **Aviso de teste:** nos testes sem janela (`--headless`) o Godot mostra `Parameter "material" is null` do renderizador "dummy" ao carregar o Refúgio e o Bosque; nos testes com janela esse erro não aparece. Não foi suprimido; vale investigar se o aviso persistir.

- **Animais e obstáculos (21/11/2026):** os animais de vila olham à frente com três raios de física (camada 1: paredes, cercas, troncos, portas fechadas, terreno) e param ou desviam antes de bater; ao fugir de um golpe, desviam de lado. Teste: `tools/teste_animais_obstaculos.gd` (960 amostras, zero atravessamentos; o código antigo, sem raios, teve 112 nas mesmas amostras). Eles ainda não evitam uns aos outros nem o chão muito inclinado.
- **Desmontar do Fagulha:** vale perto do chão (raio de 1,5 m), não só com `is_on_floor`, para não ficar preso ao pousar numa ladeira.

## Inventário do jogador (21/11/2026)

- **Como usar:** tecla **I** abre e fecha (Esc também fecha). Com ele aberto o jogador fica parado, o mouse aparece, e não há mensagem por cima da grade (os avisos vão para o rodapé do painel). Clique num espaço para ver nome, quantidade e descrição; **Usar** (botão ou Enter) come a carne: +20 de vida, gasta uma unidade, não passa de 100 e não gasta com a vida cheia.
- **Código:** `scripts/jogo/itens.gd` (catálogo: nome, descrição, modelo, cura; ordem de exibição), `scripts/interface/painel_inventario.gd` (grade 6x4, ícones renderizados do modelo 3D em SubViewport), `jogador.coletar/usar_item` e os sinais `item_coletado` e `inventario_mudou`, `hud.gd` (lista rápida no canto direito e painel), `jogo.gd` (tecla I, travar o jogador).
- **Limites:** o inventário só guarda contagem (sem peso, capacidade, equipar, largar ou vender) e **não é salvo** ao fechar o jogo; couro, lã e presa ainda não têm uso. Para adicionar um item novo: uma entrada em `Itens.DADOS`/`ORDEM` e o modelo.
- **Teste:** `tools/teste_inventario.gd` (21 verificações com teclas de verdade e cliques) e capturas `inv_*.png`.

## Colisão de seres vivos e do cenário (22/11/2026)

- **O que passou a ser sólido para o jogador:** animais de vila (caixa do tamanho do corpo, 80%), as 6 pessoas, o Fagulha (só o tronco; as asas não bloqueiam), a carroça, os 5 caixotes, a pilha de lenha e as pedras da fogueira (com uma abertura de ~0,9 m para chegar ao fogo). Camadas: 1 = mundo, 4 = móveis, 8 = seres vivos e peças soltas; a câmera só vê 1 e 2, então não tropeça neles. Código: `scripts/mundo/solidos.gd`.
- **Regras:** animal morto ou montado perde o corpo sólido (o cavaleiro mora dentro dele); o Fagulha também, enquanto montado. Os animais agora desviam também uns dos outros, das pessoas e do Fagulha (os raios deles enxergam as camadas 1 e 8).
- **Armadilha corrigida:** `AnimatableBody3D` vem com `sync_to_physics` ligado e, quando o pai é movido por código, a posição física fica atrasada (0,4 a 0,6 m): o jogador atravessava os animais que já tinham andado. Desligado em `Solidos.corpo_movel`.
- **Auditoria:** `tools/auditar_colisao.gd` lista toda malha grande sem colisão por área. Sobra só as venezianas abertas das janelas de Ferrogris (decoração fina colada à parede).
- **Teste:** `tools/teste_solidos.gd` (jogador anda contra cada coisa e mede a menor distância; passou 3 vezes seguidas).

## Pessoas com vida: rotinas de trabalho (22/11/2026)

- **Sistema:** `scripts/personagens/npc.gd` ganhou `rotina`, uma lista de passos repetida para sempre: `ir` (anda até um ponto, toca Walk, desvia de gente e animal com raios), `fazer` (repete uma animação por N segundos, olhando para um ponto) e `esperar` (parado numa animação). A rotina para enquanto o jogador conversa com o NPC e quando ele leva um golpe, e retoma depois.
- **Rotinas no Refúgio:** Brenn martela a bigorna ao lado da forja (porrete como martelo), descansa, dá uma volta e volta; Dorn corta lenha no cepo (machado) e leva ao monte; Tessa mexe o caldeirão perto da fogueira e vai buscar ingredientes; Orin patrulha a cerca leste e vigia; Mira vai ao limite do bosque, agacha para rastrear e volta; Vane anda até a fogueira, conversa e volta à casa.
- **Peças novas:** bigorna e caldeirão do pacote de móveis (CC0), cepo (cilindro de madeira, geometria simples), porrete e machado já existentes. O **porrete faz papel de martelo** (não há modelo de martelo): trocar quando houver. O machado (`simpleaxe`) e o porrete foram calibrados para a mão com `tools/medir_arma.gd` (giro 0,0,-90, empunhadura no meio do cabo).
- **Corpo sólido móvel:** os NPCs agora usam `AnimatableBody3D` (como os animais), pois andam.
- **Limites:** os NPCs não entram nas casas (as portas só abrem para o jogador), não há ciclo de dia e noite, e não reagem uns aos outros. A animação de martelar/cortar é o golpe de espada repetido (não há animação própria de ofício).
- **Teste:** `tools/teste_rotinas.gd` (sem janela, tempo 8x, 50 s de jogo): cada NPC anda, toca as animações certas e não fica preso.

## Campanha: Bíblia expandida e sistema de missões (22/11/2026)

- **Documento-fonte:** a "Bíblia expandida do mundo" que o Cristian colou em 22/11/2026 (5 capítulos, missões C1-M1 a C5-M4, locais, NPCs, regras de implementação). É a referência da campanha; o jogo a segue por **marcos**: M1 sistema de missões e C1-M1 (feito); M2 Refúgio como vila completa; M3 Pomar Alto e C1-M2 a M4; M4 Bosque Velado e Mina; M5 Ruptura e Ferrogris; M6 Cratera de Ignis; M7 Valdoria e Castelo.
- **Conflito de nomes a resolver no Marco 2:** a Bíblia chama os moradores do Refúgio de Mara (curral), Oren (agricultor), Tessa (mensageira), Halk (guarda do portão) e Nilo (menino); o jogo já tem Orin (vigia), Dorn (lenhador), Tessa (cozinheira) e Mira (caçadora), criados antes. A Bíblia manda: no Marco 2 os papéis e nomes passam para os da Bíblia, reaproveitando os modelos. Brenn também muda (grisalha, prótese metálica no braço esquerdo) e Vane ganha a cicatriz no olho esquerdo.
- **Sistema (Marco 1):** `scripts/missoes/dados_missoes.gd` (catálogo; só missões que já dá para cumprir) e `gerenciador_missoes.gd` (ativas, progresso por contador, recompensa, sinais). Qualquer parte do jogo avisa com `GerenciadorMissoes.evento("tipo", "alvo")`; tipos: falar, golpear, interagir. **Nada conclui por proximidade.** O rastreador fica abaixo da vida; falas dos NPCs mudam com a missão ativa.
- **Interação (`Interagivel`):** objetos que o jogador aciona com E (grupo `interagiveis`, dica na tela): `TochaDeTreino`, `QuadroDeAvisos`. `BonecoDeTreino` leva golpe (grupo `atingiveis`) e conta para a missão. Servem de base para cestos de maçã, jaulas, âncoras e fornalhas dos próximos capítulos.
- **C1-M1 Rotina do Exílio (jogável):** falar com Vane, visitar Brenn, 3 golpes no boneco, acender 3 tochas; recompensa 2 carnes e liberação do quadro de avisos (que ainda diz "nenhum aviso novo" até o Marco 3). O pátio de treino fica a oeste da fogueira; o quadro, a leste.
- **Teste:** `tools/teste_missoes.gd` (fluxo real, sem janela, 11 verificações).
- **Ainda não existe (Bíblia):** salvamento/checkpoints, sons ambientes, ciclo de manhã/tarde/noite, evolução do Fagulha em 3 fases, comércio, chapter gating por missão.

## Marco 2: o Refúgio do Pinhal como vila (22/11/2026)

- **Construções novas** (`scripts/mundo/vila_refugio.gd`, geometria simples de madeira e pedra; o kit não tem esses itens): dois portões com **duas torres de vigia** cada (norte "Trilha do Bosque Velado", leste "Refúgio do Pinhal - Estrada de Ferrogris"), viga com placa e batentes abertos; **três currais** cercados (vacas e ovelhas ao sul com cocho e fardos de feno, porcos a oeste da casa do Vane, cavalos a oeste); **galinheiro** com casinha e 6 galinhas; **poço** de pedra com telhadinho, corda e balde; **horta** cercada com 4 canteiros e plantação (repolho, cenoura); **canil** no portão leste com 2 cães; **depósito de grãos** (casa com sacos, barris e caixotes); na praça, **3 bancos** virados para a fogueira e um **varal** com roupas. O quadro de avisos e o pátio de treino vieram no Marco 1. Currais têm colisão e os animais ficam dentro.
- **Interiores:** a casa do Vane ganhou um **mapa de Arvendal** na parede (relevo, trilha tracejada e um marcador por região). Placas de madeira acima de cada porta dizem a função: Casa do Vane, Forja, Casa do Oren, Casa da Tessa, Casa da Mara, Depósito de Grãos.
- **Galinha:** modelada por mim (`tools/criaturas/gerar_galinha.py`, ~0,4 m, cabeça em nó separado): bica o chão parada, tomba de lado ao morrer, solta 1 carne, cores variadas (`variacao_de_cores.gd`).
- **Moradores (nomes da Bíblia):** Halk (guarda do portão, patrulha entre as torres), Oren (agricultor, planta na horta), Mara (cuidadora do curral, leva ração ao cocho e ao feno), Tessa (agora **mensageira**: corre do Vane ao portão e volta), Nilo (menino que **segue o Torin** à distância e comenta o Fagulha); mais Vane, Brenn, Dorn (lenhador) e Mira (caçadora, que também cozinha no caldeirão). Os modelos são os mesmos corpos base com cabelo, traje e escala diferentes: **Oren se parece com o Dorn**, **Mara com a Mira**, e o **Nilo é um adulto a 62%** (não há modelo de criança).
- **Não feito (fica para os próximos marcos):** o portão não bloqueia: o Halk ainda não libera passagem (só quando a missão C1-M4 existir); a trilha do pomar e a trilha escondida do pinhal dependem do Pomar Alto (Marco 3); as mudanças da Brenn (cabelos grisalhos, prótese metálica) e do Vane (cicatriz no olho esquerdo) exigem ajuste de modelo; sem sons ambientes, sem ciclo de manhã/tarde/noite; nem toda cabana tem função visível por dentro além da placa (a casa do Oren, da Tessa e da Mara usam o mesmo interior de moradia).
- **Teste:** `tools/teste_rotinas.gd` (8 moradores) e capturas do panorama, portão, galinheiro e horta.

## Marco 3: Pomar Alto e as missões C1-M2 a C1-M4 (22/11/2026)

- **Pomar Alto das Macieiras** (`scenes/areas/pomar_alto.tscn`, `scripts/mundo/pomar_alto.gd`): encosta suave a oeste do Refúgio (entrada pelo novo **portão oeste**, "Trilha do Pomar Alto"), com **5 fileiras de 7 macieiras colhíveis** (35, cada uma com 4 maçãs visíveis que somem ao colher), cerca baixa, cestos, escada de colheita, **barracão de ferramentas** (interior de depósito), pedras com musgo e o **moinho de pedra** com roda d'água girando, riacho e **porta trancada** (o moleiro levou a chave: gancho para uma missão secundária futura). Rastros de botas imperiais aparecem junto à cerca quando a colheita passa de 3 maçãs.
- **Item novo:** maçã (modelo meu no Blender, cura 8). `Itens`, `Pickup` e o inventário a conhecem.
- **Tipos de objetivo novos:** `derrotar` (por espécie: lobo, batedor; vem de `Inimigo._morrer`), `visitar` (`ZonaDeEvento`, dispara ao ENTRAR no raio, também para grupos como o cavalo) e `entregar` (gasta item do inventário ao falar com o NPC ou interagir). O **quadro de avisos** agora oferece a próxima missão do capítulo na ordem (C1-M2, M3, M4).
- **C1-M2 Colheita no Pomar Alto:** colher 6 maçãs, endireitar o cesto, falar com Oren, entregar 3 maçãs à Mara. Recompensa: 2 carnes.
- **C1-M3 Guardião do Cercado e da Estrada:** 3 lobos aparecem perto do cercado; o cavalo fugido está na estrada leste (E para acalmar, depois **montar e levar ao curral dos cavalos**). Recompensa: 2 couros. As ovelhas não ficam sob ameaça de verdade (os lobos só perseguem o jogador): é só o pano de fundo.
- **C1-M4 Resgate nas Sombras do Pinhal:** trilha escondida ao norte leva a uma **clareira plana** (terreno aplanado, `Terreno.planos`) com círculo de pedras, **estaca de Ferro Negro** (3 puxadas, brilho azul enfraquece), correntes até a **Fagulha ferida** e **3 batedores imperiais**; alimentar a Fagulha com carne. Recompensa: 3 maçãs.
- **Fagulha (fase 1):** começa ferida e deitada na clareira, **não segue** o jogador nem pode ser montada até a C1-M4 (`Jogo.fagulha_livre`, `liberar_fagulha()`); fora do Refúgio ela some. Mantém o tamanho grande pedido (não há versão "filhote": a evolução em 3 fases fica para depois).
- **Portão norte:** o Halk barra a passagem para o Bosque Velado até a C1-M4 ser concluída (`REQUISITOS_MISSAO`).
- **Não feito:** missão secundária do moinho (chave), sons do pomar, ciclo do dia, aparência do dragão ferido (usa o modelo normal parado em Idle), efeito de "ferido" ou correntes animadas, e o portão leste (Ferrogris) segue pedindo o chefe Gorath. A casa do Oren/Tessa/Mara continua com o mesmo interior.
- **Testes:** `tools/teste_marco3.gd` (ponta a ponta, sem janela, 30 verificações). `teste_montaria_dano.gd` e `teste_solidos.gd` foram ajustados (chamam `liberar_fagulha()`) mas **não foram rodados de novo** depois da mudança.

## Marco 4: Bosque Velado e Mina das Correntes, Capítulo II (22/11/2026)

- **Área** (`scripts/mundo/bosque_velado.gd`, substitui o antigo arena_chefe "mata"; mantém `chefe_vida`/`chefe_morreu`): três zonas de sul a norte, com névoa azulada. **Trilha dos Caçadores** (acampamento com 4 tendas, fogueira, varais de couro, mesa com mapa, bancos, trilha de pegadas de lobo até a toca e de bota até um acampamento abandonado), **Riacho da Névoa** (riacho em meandro, pedras de travessia, 8 raízes medicinais colhíveis, Borin), **Encosta da Mina** (2 andaimes, trilhos, vagonete, elevador de carga, caixas imperiais, bandeiras negras, fachada com pilares e lintel), **corredor da mina** (Sala de Triagem, Galeria Alagada com passarela, Depósito de Minério, jaulas), **praça do obelisco** (anel de rochas, trilhos em cruz, 3 vagonetes, 2 plataformas).
- **Obelisco** (`obelisco.gd`, `ancora_de_obelisco.gd`): base circular com runas brilhantes, corpo rachado com veios azuis e **3 âncoras** com correntes. Destruição em etapas: 3 âncoras (3 golpes cada), o corpo desaba, a névoa recua (0,013 para 0,004), parte da caça foge, os filhotes ainda presos voam e saem 3 Ferros Negros brutos.
- **Jaulas** (`jaula_de_filhote.gd`): 3 jaulas de ferro, cada uma com um Filhote de Asa e um guarda com a chave; E abre com chave (gasta 1) e o filhote voa para longe. **Vagonetes** (`carrinho_de_minerio.gd`): E empurra 12 m ao longo do trilho e atropela inimigos (90 de dano): arma na arena do Gorath. O Gorath só surge na praça depois da C2-M3.
- **Animais novos:** cervo (cavalo menor com chifres), coelho (cão pequeno com orelhas longas), urso (cão grande com orelhas redondas; inimigo, 150 de vida, defende a margem do riacho), corvo (galinha preta pousada em postes: ao ver o jogador grasna, **alerta os inimigos num raio de 45 m** e foge voando). Cervos e coelhos **fogem** quando o jogador chega perto. Chifres e orelhas são peças presas ao osso da cabeça (`acessorios.gd`). Itens novos: raiz medicinal (cura 12), minério de Ferro Negro bruto e chave de jaula (modelos meus, Blender).
- **NPCs:** Elda (caçadora, passa a C2-M1), Borin (mineiro fugitivo, explica o obelisco) e Sava (prisioneira, passa a C2-M2). Mesmos corpos base com outro cabelo e roupa.
- **Missões:** C2-M1 Caçada e Rastreamento (pegadas de lobo até a toca, 4 couros ou presas, 4 raízes), C2-M2 Asas nas Gaiolas (3 chaves dos guardas, 3 jaulas), C2-M3 Queda do Primeiro Obelisco (ouvir Borin, 3 âncoras, 3 minérios; começa sozinha depois da M2) e C2-M4 O Capataz da Mina (derrotar o Gorath; começa sozinha depois da M3). Objetivos podem ter vários alvos (couro ou presa), e NPCs podem oferecer missões (`oferece_missao`).
- **Mudança de regra:** com um NPC e um objeto interativo ao alcance, o E atende o que estiver **mais perto** (antes o NPC sempre ganhava e a Sava impedia abrir a jaula ao lado dela).
- **Correção de escala (cão e lobo):** o esqueleto do pug tem escala 0,4 própria, então a malha em repouso media 0,4 m mas o cão animado tinha ~0,85 m. Importações ajustadas (cão 0,25, lobo 0,36): cão ~0,55 m, lobo ~0,8 m.
- **Limites:** o Gorath usa o modelo e os ataques de antes (sem a clava com corrente da Bíblia); os guardas são o mesmo modelo repetido; não há som, ciclo do dia nem salvamento; as pegadas são marcas simples; sem checkpoint antes do chefe; a névoa é um único ajuste de densidade (sem volume de névoa por zona); o riacho não retarda o jogador.
- **Teste:** `tools/teste_marco4.gd` (ponta a ponta, sem janela, 27 verificações) e capturas `m4_*.png`.

## Marco 5: Acampamento da Ruptura e Fortaleza de Ferrogris, Capítulo III (22/11/2026)

- **Base nova** (`scripts/mundo/area_aberta.gd`): terreno, borda, floresta e ajudantes de cenário (rocha, placa, tenda, bandeira, fogueira, muralha, torre de vigia) e de gente (NPC, inimigo). As duas áreas novas herdam dela; o Bosque Velado continua com os ajudantes próprios.
- **Acampamento da Ruptura** (`acampamento_ruptura.gd`, a leste do Refúgio): acampamento do Vane com 6 tendas, fogueira, mesa, bancos, bandeiras, rio com ponte quebrada (pilares e tábuas só até a metade) e vau a norte, 3 pilhas de Ferro Negro bruto. NPCs: Vane, um seguidor e o vigia do vau. Ao chegar perto do Vane com a C3-M1 ativa, a **cena do confronto** roda sozinha (`Jogo.cena_dialogo`, E avança) e conta o objetivo.
- **Fortaleza de Ferrogris** (`fronteira_ferrogris.gd`, substitui o arena_chefe): muralha externa com a Brecha e 4 torres com arqueiros; Pátio Externo (Quartel, Depósito de Aço com 4 pilhas, Canil com 2 cães de guerra, 4 guardas); muralhas internas; Prisão (cela dos civis e cela dos soldados, com 2 presos cada), Jaulas dos Dragões (1 dragão jovem), Pátio Central (8 braseiros, 3 bonecos de treino), Sala de Comando e Portão dos Fundos. 3 guardas carregam chave (carcereiro, domador, oficial de comando).
- **Kaelor:** surge no pátio quando a C3-M3 termina. Fase 2 (66% da vida) solta 2 cães de guerra; fase 3 (33%) chama 2 guardas; já enfurece aos 50%. Ao morrer, o Portão dos Fundos abre e o caminho da Cratera de Ignis fica livre; o retorno da Cratera cai no portão dos fundos (`DaCratera`).
- **Objetos novos:** `PilhaDeItem` (aço imperial ou Ferro Negro, E recolhe), `CelaTrancada` (precisa de chave; origem na porta, para o E não falar com os presos em vez de abrir), `Portao` (duas folhas), flecha visual do arqueiro (`Efeitos.flecha`). Inimigos novos: `arqueiro.tscn` (parado, 26 m de alcance, desenha a flecha), `cao_de_guerra.tscn` (cão grande e escuro, corre rápido). Item novo: Aço Imperial (modelo meu, Blender). NPCs novos (cenas): cativo, cativa, soldado rebelde e soldado ferido (mesmos corpos base).
- **Missões:** C3-M1 A Quebra do Juramento (ouvir o Vane, levar 3 Ferro Negro à Brenn no Refúgio; ela reforça o equipamento: golpe +8 e vida máxima +20), C3-M2 Brecha nas Muralhas (4 guardas, 2 cães, 3 aços), C3-M3 Libertação dos Cativos (3 chaves, 3 setores) e C3-M4 O Comandante de Ferrogris (derrotar Kaelor). Encadeadas sozinhas. O portão leste do Refúgio leva ao Acampamento (exige o Gorath); o vau para a Fortaleza exige a C3-M1.
- **Limites:** os arqueiros ficam parados nas torres e não se movem; os cativos soltos andam até o portão e ficam lá (sem animação de agradecimento nem recompensa por NPC); o dragão jovem é o modelo do Filhote de Asa maior; o Kaelor usa o modelo de antes; sem som, sem checkpoint antes do chefe; o chão do pátio é liso e cinza (sem pavimentação nem texturas).
- **Teste:** `tools/teste_marco5.gd` (ponta a ponta, sem janela, 31 verificações) e capturas `m5f_*.png`/`m5a_*.png`. A ferramenta `tools/ver_area.gd` agora espera mais antes da 1ª foto e força o desenho antes de cada captura (antes todas saíam iguais).

## Marco 6: Cratera de Ignis, Capítulo IV (22/11/2026)

- **Área** (`scripts/mundo/cratera_ignis.gd`, substitui o arena_chefe "cratera"; usa `AreaAberta`): complexo industrial sobre um vulcão, céu e névoa vermelhos, chão plano e escuro com paredões de rocha. De sul a norte: **Ponte de Basalto** sobre a fenda de lava, zona de calor com 2 guindastes, lingotes, patrulhas (2 guardas, cão de guerra, arqueiro em torre), **Passarela A**, pátio das forjas (**Alojamento dos Trabalhadores**, **Depósito de Lingotes**, **Sala de Controle das Correntes**, 2 guindastes, **3 fornalhas negras**), **Passarela B**, arena de Ignis-Maw com a **Caldeira Ancestral** (poço de lava cercado de pedra).
- **Lava** (`zona_de_calor.gd`): retângulo emissivo que queima (12 de dano a cada 0,8 s) quem pisa no chão; pontes e passarelas ficam 0,16 m acima e são seguras. **Focos de calor** (`Fogo` com dano) em volta de cada minério.
- **Fornalhas negras** (`fornalha_negra.gd`), três mecanismos: **Sopro** (3 válvulas de vapor em 25 s, senão a pressão volta), **Canos** (quebrar 2 canos de lava a golpes) e **Runas** (tocar 1, 2, 3 em ordem; erro reinicia). Cada fornalha apagada conta como `fornalha_apagada`. `Gatilho` (`gatilho.gd`) é o interagível genérico novo.
- **Ignis-Maw:** acorda quando a C4-M2 termina e as 4 âncoras (110 de vida, com correntes até o peito dele) aparecem. Ele **não morre a golpes** (a vida volta ao máximo); a barra de chefe mostra as âncoras restantes. Cada âncora que cai o deixa 12% mais rápido. Ataques: golpe corpo a corpo (a "cauda"), **onda de calor** a cada 9 s (anel que se expande, 18 de dano a quem está no chão: pule) e **chuva de brasas** a cada 12 s (3 focos de fogo em volta do jogador). Ao quebrar a 4ª âncora ele ruge, voa para longe, as 3 fornalhas desabam em chamas e deixa uma **escama ancestral** na arena; o sinal `chefe_morreu("ignis_maw")` libera Valdoria.
- **Missões:** C4-M1 Travessia da Brasa (4 minérios vulcânicos + chegar ao alojamento), C4-M2 Desativar as Forjas Negras (3 fornalhas), C4-M3 O Colosso Acorrentado (4 âncoras) e C4-M4 A Lâmina Forjada no Fogo (entregar 4 minérios e a escama à Brenn, que monta uma **forja de campo** na Cratera depois da C4-M3; recompensa: golpe +14). Valdoria só abre com a C4-M4. NPCs novos: Tarn (trabalhador), Trabalhador Cansado e Operário da Fornalha.
- **Itens novos:** Minério vulcânico e Escama ancestral (modelos meus, Blender).
- **Mudanças de apoio:** `_edificio` (prédio com placa) foi para `AreaAberta` e passou de 4x3 para 4x4 módulos (o telhado 8x6 não existe e saía sem telhado); `AreaAberta._montar_terreno` aceita raio de clareira grande para chão plano; o retorno de Valdoria cai em `DeValdoria` (norte da Cratera).
- **Limites:** o Ignis-Maw usa o modelo e as animações de antes (sem cauda nem sopro de fogo animados; o ataque é o mesmo corpo a corpo); a onda de calor e as brasas são efeitos simples; sem som de forja, lava ou alarme; sem checkpoint antes da arena; o dano da lava é só no chão (voando com o Fagulha não queima).
- **Teste:** `tools/teste_marco6.gd` (ponta a ponta, sem janela, 29 verificações) e capturas `m6_*.png`. `tools/ver_area.gd` aceita o argumento `acordar` para mostrar o Ignis-Maw e as âncoras.

## Marco 7: Valdoria e o Castelo Imperial, Capítulo V (22/11/2026)

- **Valdoria** (`scripts/mundo/valdoria.gd`, substitui o arena_chefe; usa `AreaAberta`, luz dourada e opressiva): muralha com 6 torres e bandeiras de Drakkar, **Portão Principal** com **fila de 6 carroças**, **Rua dos Artesãos** (Ferraria, Carpintaria, Curtume, Ateliê de Tecidos, lampiões), **Praça Central** com a fonte seca e bancos, **Distrito do Comerciante** (6 barracas com bancada, toldo, estoque e caixa de moedas), **bairro residencial com 16 casas** e becos (com muretas sem saída), **Quartel da Guarda**, **Armazém de Suprimentos**, **Capela Abandonada** (sem uso, com entulho), estábulo da cidade (cavalo e vaca) e **escadaria monumental** até o castelo (rampa lisa por baixo, degraus só no desenho).
- **Gente:** 15 pessoas com rotina: 4 mercadores (Miro, Lena, Darrik, Suri, cada um com falas e rumores), 4 artesãos (Hobb, Rurik, Yara, Pim), varredora, carregador, tratador de animais, dois discutindo preço, um fregues e o menino Tico (segue o jogador e comenta o Fagulha). Guardas comuns e **4 guardas de elite** (160 de vida) diante da escadaria.
- **Trocas** (`Gatilho` nas bancadas, sem dinheiro no jogo): Miro 2 raízes por carne ou 3 maçãs por raiz; Lena 2 maçãs por carne ou 1 couro por 3 carnes; Darrik 1 presa por 2 maçãs ou 2 lãs por 2 carnes; Suri 1 Ferro Negro bruto por 1 chave. Qualquer troca vale como "obter suprimentos" na C5-M1.
- **Castelo Imperial** (`castelo_imperial.gd`, área nova, plataforma 3 m acima, com `altura_em` próprio): **escadaria monumental**, pátio externo (**Estábulos Reais** com 3 cavalos, **Sala de Armas**, guardas e arqueiros), **Galeria de Estandartes** (colunata com 6 estandartes), **Prisão Subterrânea** (cela com um preso e um carcereiro que leva a chave), **Pátio do Duelo** (círculo de 24 m com 8 braseiros), **Salão do Trono** (tapete, 10 colunas, estrado e trono) e **Grande Obelisco** (espiral negra de 46 m atrás do trono, com luz azul e 4 focos de energia ligados por correntes).
- **Duelo do Vane** (`vane_duelista.tscn`, 380 de vida): só acorda depois de uma conversa de 3 falas. A 50% da vida entra em fúria e passa a jogar **brasas corrompidas** em volta do jogador a cada 10 s. Ao cair, abre o portão do salão e diz suas últimas falas.
- **Solon:** surge depois que os 4 focos caem (a luz do obelisco apaga). **Fase 1**: escudo do obelisco absorve 70% do dano. A 50% da vida a **Fagulha mergulha**, quebra o escudo e causa 80 de dano (fase 2, sem proteção; ele também enfurece). Ao cair roda o **epílogo** (obeliscos se apagando, Fagulha sobre Valdoria, Brenn desmontando armas, conselho, luz de Ferro Negro ao longe) e o jogo emite `fim_de_jogo`.
- **Missões:** C5-M1 Portões e Ruas de Valdoria (atravessar o mercado, uma troca, 4 guardas de elite), C5-M2 O Duelo de Vane, C5-M3 Quebrar o Grande Obelisco (4 focos) e C5-M4 A Queda do Imperador Solon. Encadeadas sozinhas; o castelo só abre depois da C5-M1.
- **Limites:** a Capela, a Prisão e as casas têm só o interior padrão do kit (sem móveis próprios); a Prisão Subterrânea não é subterrânea (prédio térreo); o Vane e o Solon usam o modelo e as animações de antes (sem golpes únicos); sem som, sem checkpoint antes do duelo, do obelisco e do Solon, e sem dinheiro (só troca). O epílogo é texto em caixas de diálogo, sem cena animada.
- **Teste:** `tools/teste_marco7.gd` (ponta a ponta, sem janela) e capturas `m7v_*.png`/`m7c_*.png`.

## Auditoria do mundo (22/11/2026)

Pedida pelo Cristian depois do Marco 7: casas sem teto, plantação que não parecia plantação, atravessar objetos, áreas sem ligação, missões sem encadeamento, mapa, estradas, montanhas, texturas do chão e conversa com NPC.

**O que a auditoria mediu (scripts novos, sem janela):**
- `tools/auditoria_mundo.gd`: para cada uma das 8 áreas confere (1) se toda casa tem telhado, (2) se há furo nas paredes (raios a cada 0,5 m a 1 m de altura) e (3) se dá para ANDAR, com a cápsula do jogador numa grade de 1 m, de cada spawn até cada portal, NPC, objeto interativo e a entrada de cada casa (portões e portas abertos; lava conta como bloqueio).
- `tools/auditoria_portais.gd`: todo portal leva a uma área e a um spawn que existem, e a área de destino tem portal de volta.
- `tools/teste_cadeia.gd`: começa do zero, cumpre os objetivos de cada missão pelos eventos reais e confere que a próxima começa sozinha, da C1-M1 à C5-M4.

**Defeitos achados e consertados:**
- **Atravessava árvores:** só 300 a 500 troncos por área tinham colisão (de 840 a 3100 árvores). Hoje todas têm.
- **Escadaria do Castelo ao contrário:** a rampa subia para o sul, então a entrada do castelo ficava com um degrau de 3 m e quem chegava não passava. Corrigida (o jogo só funcionava porque o teste teleporta).
- **Buraco de 1 m na escadaria de Valdoria** entre a rampa e a plataforma do alto: quem descia ou subia caía na vala. A plataforma agora cobre a emenda.
- **Missões não encadeavam:** C1-M2, C1-M3, C1-M4, C2-M1 e C2-M2 dependiam do quadro de avisos ou de falar com um NPC. Agora cada missão começa 6 s depois da anterior, até o fim.
- **Pomar Alto sem o spawn "Entrada"** que o Refúgio pede (caía no spawn padrão): criado.
- **Casas sem telhado:** os prédios 4x3 da Fortaleza e da Cratera não tinham telhado (peça 8x6 não existe); passaram a 4x4 no Marco 6. A auditoria mede telhado em todas as casas das 8 áreas.

**O que melhorou:**
- **Plantação** (`plantacao.gd`, no Refúgio): terra lavrada em sulcos, 8 fileiras de trigo (espigas), milho (folhas e espigas), repolho, verduras e abóboras; trigo, milho e verduras balançam ao vento (shader); espantalho, 3 fardos de feno, bebedouro, 2 corvos na cerca.
- **Chão com capim, flores e manchas** (`VegetacaoRasteira.decorar_zonas`) também no Pomar Alto, Bosque Velado e Acampamento da Ruptura (antes só o Refúgio).
- **Horizonte e montanhas** (`horizonte.gd`) em todas as 8 áreas: chão até o fim da vista e duas fileiras de montanhas (neve em algumas, vulcão vermelho na Cratera, colinas ocres em Valdoria).
- **Mapa do mundo** (`mapa_do_mundo.gd`, tecla M): 8 regiões, estradas (tracejadas quando trancadas), "você está aqui", anel dourado na região da missão ativa e o motivo de cada região trancada.
- **Conversa com NPC:** texto aparece letra a letra (E completa), número da fala ("2/3"), aviso "E continuar / E fechar", prompt "E Falar com Nome, papel" e marcador sobre a cabeça: "?" quando a missão ativa pede para falar ou entregar a ele, "!" quando ele passa uma missão.

**Ainda não feito:** vales e rios entre as regiões (as áreas continuam separadas por portais, não por um mundo contínuo; as estradas existem dentro de cada área e no mapa), textura de chão com arte (o chão ainda é cor com manchas), sons, checkpoints.
