# Lista dos ajustes (item por item)

Fotos: cada pasta `<categoria>/<item>/` tem `antes.jpg` (estado original, commit 456cf7d, tirado numa cópia limpa) e, se o item foi ajustado, `depois.jpg` (+ `cabeca_antes.jpg` e `cabeca_depois.jpg` para animais). Itens **NÃO AJUSTADOS** só têm `antes.jpg` e um `NAO_AJUSTADO.txt`.
Cada foto: frente, lado e costas, parado e andando (quando tem animação), e o Torin ao lado como régua nos itens grandes. A cor da pelagem dos animais é sorteada a cada foto, então `antes` e `depois` podem ter cores diferentes sem que isso seja ajuste.
As medidas escritas nas fotos (c x l x a, em metros) incluem uma margem de 6% e, nos animais, são a caixa dos ossos.

**O que ESTE trabalho ajustou:** olhos em 11 espécies e o lobo (giro, tamanho). **Nada mais foi ajustado**: nenhuma textura, cor, animação, árvore, grama, drop, casa, móvel ou arma.

**Total:** 11 itens ajustados, 260 NÃO ajustados, 271 no inventário.

| Categoria | Item | Estado | O que estava ruim | O que mudei | Como está |
|---|---|---|---|---|---|
| animais | cao | **AJUSTADO** | sem olhos | olhos presos ao osso da cabeça (`olhos.gd`) | olhos visíveis nas 3 vistas da cabeça; textura, cor e animação NÃO mexidas |
| animais | cavalo | **AJUSTADO** | sem olhos | olhos presos ao osso da cabeça (`olhos.gd`) | olhos visíveis nas 3 vistas da cabeça; textura, cor e animação NÃO mexidas |
| animais | cervo | **AJUSTADO** | sem olhos | olhos presos ao osso da cabeça (`olhos.gd`) | olhos visíveis nas 3 vistas da cabeça; textura, cor e animação NÃO mexidas |
| animais | coelho | **AJUSTADO** | sem olhos (olho pequeno: calibrar) | olhos presos ao osso da cabeça (`olhos.gd`) | olhos visíveis nas 3 vistas da cabeça; textura, cor e animação NÃO mexidas |
| animais | galinha | NÃO AJUSTADO | sem olhos, textura chapada | nada | igual ao antes |
| animais | ovelha | **AJUSTADO** | sem olhos | olhos presos ao osso da cabeça (`olhos.gd`) | olhos visíveis nas 3 vistas da cabeça; textura, cor e animação NÃO mexidas |
| animais | porco | **AJUSTADO** | sem olhos | olhos presos ao osso da cabeça (`olhos.gd`) | olhos visíveis nas 3 vistas da cabeça; textura, cor e animação NÃO mexidas |
| animais | vaca | **AJUSTADO** | sem olhos | olhos presos ao osso da cabeça (`olhos.gd`) | olhos visíveis nas 3 vistas da cabeça; textura, cor e animação NÃO mexidas |
| armas | club | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| armas | katana | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| armas | longsword | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| armas | shortsword | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| armas | simpleaxe | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| criaturas | fagulha | NÃO AJUSTADO | sem olhos conferidos; textura e animação não avaliadas | nada | igual ao antes |
| drops | aco_imperial | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| drops | carne | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| drops | chave | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| drops | couro | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| drops | escama_ancestral | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| drops | la | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| drops | maca | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| drops | minerio_bruto | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| drops | minerio_vulcanico | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| drops | presa | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| drops | raiz | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| inimigos | arqueiro | NÃO AJUSTADO | sem olhos conferidos; textura e animação não avaliadas | nada | igual ao antes |
| inimigos | cao_de_guerra | **AJUSTADO** | sem olhos | olhos presos ao osso da cabeça (`olhos.gd`) | olhos visíveis nas 3 vistas da cabeça; textura, cor e animação NÃO mexidas |
| inimigos | filhote_de_asa | NÃO AJUSTADO | sem olhos conferidos; textura e animação não avaliadas | nada | igual ao antes |
| inimigos | gorath | NÃO AJUSTADO | sem olhos conferidos; textura e animação não avaliadas | nada | igual ao antes |
| inimigos | guarda_imperial | NÃO AJUSTADO | sem olhos conferidos; textura e animação não avaliadas | nada | igual ao antes |
| inimigos | ignis_maw | NÃO AJUSTADO | sem olhos conferidos; textura e animação não avaliadas | nada | igual ao antes |
| inimigos | javali | **AJUSTADO** | sem olhos | olhos presos ao osso da cabeça (`olhos.gd`) | olhos visíveis nas 3 vistas da cabeça; textura, cor e animação NÃO mexidas |
| inimigos | kaelor | NÃO AJUSTADO | sem olhos conferidos; textura e animação não avaliadas | nada | igual ao antes |
| inimigos | lobo | **AJUSTADO** | de costas (a "frente" da bancada mostrava o rabo), ~3,9 m de comprimento com a cabeça na altura do Torin, sem olhos | modelo girado 180° (`lobo_visual.tscn`), escala visual 1,0 para 0,55 (`lobo.tscn`), olhos (`olhos.gd`) | olha para onde anda; 2,2 x 1,0 m; olhos âmbar (levemente assimétricos); corpo ainda alongado; textura e animação NÃO mexidas |
| inimigos | solon | NÃO AJUSTADO | sem olhos conferidos; textura e animação não avaliadas | nada | igual ao antes |
| inimigos | urso | **AJUSTADO** | sem olhos | olhos presos ao osso da cabeça (`olhos.gd`) | olhos visíveis nas 3 vistas da cabeça; textura, cor e animação NÃO mexidas |
| inimigos | vane_duelista | NÃO AJUSTADO | sem olhos conferidos; textura e animação não avaliadas | nada | igual ao antes |
| moveis | Anvil | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Bag | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Barrel | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Bed_Twin1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Bed_Twin2 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Bench | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | BookGroup_Medium_1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Bookcase_2 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Bucket_Wooden_1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Cabinet | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | CandleStick_Triple | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Candle_1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Cauldron | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Chair_1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Chest_Wood | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Lantern_Wall | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Mug | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Nightstand_Shelf | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Peg_Rack | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Pot_1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Scroll_1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Shelf_Simple | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Shield_Wooden | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Stool | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Sword_Bronze | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Table_Large | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Table_Plate | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | WeaponStand | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Workbench | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| moveis | Workbench_Drawers | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| natureza | arbusto | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| natureza | arvore_morta | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| natureza | cogumelo | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| natureza | folhosa | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| natureza | pedra | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| natureza | pinheiro | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| natureza | toras | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Balcony_Cross_Corner | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Balcony_Cross_Straight | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Balcony_Simple_Corner | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Balcony_Simple_Straight | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Corner_ExteriorWide_Brick | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Corner_ExteriorWide_Wood | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Corner_Exterior_Brick | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Corner_Exterior_TopDown | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Corner_Exterior_TopOnly | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Corner_Exterior_Wood | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Corner_Interior_Big | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Corner_Interior_Small | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | DoorFrame_Flat_Brick | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | DoorFrame_Flat_WoodDark | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | DoorFrame_Round_Brick | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | DoorFrame_Round_WoodDark | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Door_1_Flat | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Door_1_Round | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Door_2_Flat | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Door_2_Round | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Door_4_Flat | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Door_4_Round | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Door_8_Flat | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Door_8_Round | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Floor_Brick | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Floor_RedBrick | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Floor_UnevenBrick | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Floor_WoodDark | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Floor_WoodDark_Half1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Floor_WoodDark_Half2 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Floor_WoodDark_Half3 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Floor_WoodDark_OverhangCorner | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Floor_WoodDark_OverhangCorner2 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Floor_WoodLight | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Floor_WoodLight_OverhangCorner | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Floor_WoodLight_OverhangCorner2 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | HoleCover_90Angle | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | HoleCover_90Half | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | HoleCover_90Stairs | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | HoleCover_Straight | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | HoleCover_StraightHalf | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_Plaster_Corner | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_Plaster_Corner_Front | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_Plaster_Long | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_Plaster_Short | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_RoofIncline_Plaster | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_RoofIncline_UnevenBricks | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_Roof_Plaster | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_Roof_UnevenBricks | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_Side_Plaster_Long_L | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_Side_Plaster_Long_R | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_Side_Plaster_Short_L | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_Side_Plaster_Short_R | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_Side_UnevenBrick_Long_L | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_Side_UnevenBrick_Long_R | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_Side_UnevenBrick_Short_L | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_Side_UnevenBrick_Short_R | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_UnevenBrick_Corner | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_UnevenBrick_Corner_Front | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_UnevenBrick_Long | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Overhang_UnevenBrick_Short | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_Brick1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_Brick2 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_Brick3 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_Brick4 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_Chimney | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_Chimney2 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_Crate | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_ExteriorBorder_Corner | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_ExteriorBorder_Straight1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_ExteriorBorder_Straight2 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_MetalFence_Ornament | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_MetalFence_Simple | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_Support | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_Vine1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_Vine2 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_Vine4 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_Vine5 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_Vine6 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_Vine9 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_Wagon | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_WoodenFence_Extension1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_WoodenFence_Extension2 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Prop_WoodenFence_Single | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_2x4_RoundTile | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Dormer_RoundTile | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_FrontSupports | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Front_Brick2 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Front_Brick4 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Front_Brick4_Half_L | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Front_Brick4_Half_R | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Front_Brick6 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Front_Brick6_Half_L | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Front_Brick6_Half_R | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Front_Brick8 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Front_Brick8_Half_L | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Front_Brick8_Half_R | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Log | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Modular_RoundTiles | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_RoundTile_2x1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_RoundTile_2x1_Long | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_RoundTiles_4x4 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_RoundTiles_4x6 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_RoundTiles_4x8 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_RoundTiles_6x10 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_RoundTiles_6x12 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_RoundTiles_6x14 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_RoundTiles_6x4 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_RoundTiles_6x6 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_RoundTiles_6x8 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_RoundTiles_8x10 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_RoundTiles_8x12 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_RoundTiles_8x14 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_RoundTiles_8x8 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Support2 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Tower_RoundTiles | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Wooden_2x1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Wooden_2x1_Center | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Wooden_2x1_Center_Mirror | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Wooden_2x1_Corner | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Wooden_2x1_L | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Wooden_2x1_Middle | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Roof_Wooden_2x1_R | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stair_Interior_Rails | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stair_Interior_Simple | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stair_Interior_Solid | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stair_Interior_SolidExtended | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stairs_Exterior_NoFirstStep | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stairs_Exterior_Platform | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stairs_Exterior_Platform45 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stairs_Exterior_Platform45Clean | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stairs_Exterior_PlatformU | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stairs_Exterior_SidePlatform | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stairs_Exterior_Sides | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stairs_Exterior_Sides45 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stairs_Exterior_SidesU | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stairs_Exterior_SingleSide | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stairs_Exterior_SingleSideThick | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stairs_Exterior_Straight | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stairs_Exterior_Straight_Center | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stairs_Exterior_Straight_L | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Stairs_Exterior_Straight_R | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_Arch | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_BottomCover | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_Plaster_Door_Flat | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_Plaster_Door_Round | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_Plaster_Door_RoundInset | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_Plaster_Straight | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_Plaster_Straight_Base | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_Plaster_Straight_L | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_Plaster_Straight_R | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_Plaster_Window_Thin_Round | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_Plaster_Window_Wide_Flat | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_Plaster_Window_Wide_Flat2 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_Plaster_Window_Wide_Round | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_Plaster_WoodGrid | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_UnevenBrick_Door_Flat | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_UnevenBrick_Door_Round | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_UnevenBrick_Straight | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_UnevenBrick_Window_Thin_Round | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_UnevenBrick_Window_Wide_Flat | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Wall_UnevenBrick_Window_Wide_Round | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | WindowShutters_Thin_Flat_Closed | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | WindowShutters_Thin_Flat_Open | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | WindowShutters_Thin_Round_Closed | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | WindowShutters_Thin_Round_Open | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | WindowShutters_Wide_Flat_Closed | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | WindowShutters_Wide_Flat_Open | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | WindowShutters_Wide_Round_Closed | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | WindowShutters_Wide_Round_Open | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Window_Roof_Thin | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Window_Roof_Wide | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Window_Thin_Flat1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Window_Thin_Round1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Window_Wide_Flat1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| pecas_de_casa | Window_Wide_Round1 | NÃO AJUSTADO | não avaliado item a item | nada | igual ao antes |
| personagens | borin | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | brenn | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | cativa | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | cativo | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | dorn | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | elda | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | gorath | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | guarda_imperial | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | kaelor | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | mara | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | mira | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | nilo | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | oren | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | orin | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | sava | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | soldado_ferido | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | soldado_rebelde | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | solon | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | tessa | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | torin | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
| personagens | vane | NÃO AJUSTADO | não avaliado (humanos) | nada | igual ao antes |
