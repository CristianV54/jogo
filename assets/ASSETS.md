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
- **Escala (`nodes/root_scale` no `.import`):** vaca 0,27 (1,4 m), cavalo 0,28 (1,9 m), ovelha 0,23 (1,0 m), porco 0,17 (0,8 m), cão 0,57 (0,6 m), lobo 0,7, javali 0,2.
- **No jogo:** `scripts/criaturas/animal_vila.gd` (perambula e para, sem colisão), colocados em `refugio_do_pinhal.gd` (`_animais()`): 2 vacas e 3 ovelhas no pasto sul, 2 porcos a oeste da casa do Vane, 2 cavalos a oeste, 1 cão perto da forja. Velocidades de passo estimadas a olho, não calibradas contra o ciclo da animação.
- **Ainda não existem:** galinha, cervo, urso, coelho, aves, peixes, aranha, wyvern menor, cão de guerra do Império. No Downloads há `Free+Pack+-+Lowpoly+Animal` (urso, gato, cabra, canguru etc., sem rig nem animação, licença não conferida) e `horse.glb` do Sketchfab (28 animações, licença não conferida), ainda não usados.

## Jogo (Fases B a D): o que existe e o que é provisório

- **Áreas:** Refúgio do Pinhal (hub, 6 NPCs, 2 portais), Bosque Velado (Gorath), Fortaleza de Ferrogris (Kaelor), Cratera de Ignis (Ignis-Maw) e Valdoria (Solon). As quatro arenas são geradas pelo mesmo `scripts/mundo/arena_chefe.gd` com estilos diferentes. Valdoria é só um pátio murado com um salão, não uma cidade.
- **Progresso:** cada chefe derrotado libera o próximo caminho; sem o chefe a passagem fica bloqueada com aviso.
- **Interface:** barras de vida, nome da área, diálogo e mensagens desenhados por código com a fonte padrão do Godot. Provisório: falta fonte, arte e identidade visual.
- **Combate:** golpe de espada (J ou clique), rolamento com invulnerabilidade (Espaço), dano, reação, morte e recuperação lenta de vida. Um golpe só (`Sword_Attack`). Sem bloqueio, sem arco, sem magia, sem inventário nem forja.
