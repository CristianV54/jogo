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

## PLACEHOLDER_Torin (provisório, NÃO é asset final)

- **O que é:** cápsula magenta de 1,8 m com uma caixa na frente, só para testar câmera e movimento. Nó `PLACEHOLDER_Torin` e `PLACEHOLDER_Torin_frente` em `scenes/jogador/jogador.tscn`.
- **Por que existe:** o modelo do Torin ainda não foi decidido (de onde vem). A cor é magenta de propósito, para ninguém confundir com modelo final.
- **Pendência:** substituir por um humanoide real, com rig e animações (parado, andando, correndo), validado e registrado aqui. Enquanto isso, nenhuma tarefa que dependa do Torin conta como concluída.

## Cena de teste (cenário de depuração)

- `scenes/teste/cena_teste.tscn`: chão plano, céu procedural, 4 pilares `MARCO_*` (só para ver o movimento), câmera 3ª pessoa, Torin provisório e Fagulha. Nada disso é arte final.
