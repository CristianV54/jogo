# Registro de assets

Regra: só entra em `assets/models/` o que foi validado. Todo asset tem origem, licença, estilo conferido e o que tem de rig/animação. O que faltar fica listado como pendência.

## criaturas/fagulha/fagulha.glb

- **O que é:** Fagulha, dragão jovem aliado do Torin. Hoje é um corpo de dragão adulto, reduzido (envergadura 3,05 m).
- **Origem:** arquivo `Dragon_Baked_Actions.blend`, vindo de `~/Downloads` (usuário). Autor e página de origem **não conhecidos**. O arquivo original não está no repositório (só o `.glb` derivado).
- **Licença:** "gratuita", segundo o usuário (informado em 21/11/2026). **Termos exatos não confirmados** (uso comercial, crédito ao autor, redistribuição). Pendência: confirmar antes de publicar o jogo.
- **Como foi gerado:** `tools/fagulha/preparar_fagulha.py` abre o `.blend` (só leitura), pinta a cor por região em cor de vértice (o original não tinha nenhuma textura ligada), renomeia as ações com sufixo `-loop` e exporta o `.glb` sem aplicar escala.
- **Importação (Godot 4.7):** `fagulha.glb.import` com `nodes/root_scale=0.02`; `scripts/importacao/post_importar_fagulha.gd` liga a cor do vértice nos materiais e recorta/fecha os ciclos das animações.
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
