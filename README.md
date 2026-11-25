# Reino de Cinzas (subtítulo: Sangue e Escamas)

Jogo de ação/RPG em 3ª pessoa, medieval, com dragões. Godot 4.7.2 (GDScript), renderizador mobile (Metal no Mac). Idioma do projeto: português do Brasil.

Torin, um batedor sem título, descobre que o Império de Drakkar escraviza dragões com ferro negro, salva o dragão jovem Fagulha e enfrenta o Império e a traição do próprio bando (Vane). História e nomes: `CLAUDE.md` e `docs/HISTORIA-E-MISSOES.md`.

## Se você é outro Claude (ou pessoa) abrindo este repositório

**Leia nesta ordem, antes de mexer em qualquer coisa:**
1. `CLAUDE.md`: regras de trabalho, nomes aprovados e estado do projeto. É obrigatório.
2. O fim da seção "Estado atual" do `CLAUDE.md` (o que vale hoje) e `docs/construcoes/` (as peças de Valdoria, com fotos e pontos fracos anotados). `docs/SESSAO-2026-11-23.md` é histórico.
3. `docs/MAPA-DO-TRABALHO.md`: índice de cada ferramenta de `tools/`, cada documento de `docs/` e as pendências abertas.
4. `docs/LEIS-DO-JOGO.md`: regras do mundo que nunca podem ser quebradas e o teste de cada uma.
5. `assets/ASSETS.md`: origem e licença de cada modelo, mais o registro do que foi construído por marco.

O usuário não é engenheiro: explique em português direto, mostre prova (foto, número, saída de teste) e nunca declare "pronto" sem rodar. Ele se irrita quando se age sem ele mandar e quando se corrige só o ponto que ele aponta. Ver a seção "Regras de trabalho" do `CLAUDE.md`.

## Rodar o jogo

Na primeira vez depois de baixar (ou de trocar de branch), importe os arquivos uma vez:

```bash
godot --headless --path . --import
```

Depois é só rodar:

```bash
godot --path . --resolution 1280x720          # cena principal: scenes/jogo.tscn
```

Teclas: WASD andar, Shift correr, Espaço pular, J golpe, K rolar, I inventário, M mapa, E falar/montar/interagir, F Fagulha voar, Esc solta o mouse.
Modo Admin (nó `scripts/jogo/admin.gd`): F1 a F8 teleportam para cada região, F9 muda a hora, F10 muda o tempo, F11 liga o Drone (câmera livre sem o Torin).

Depois de criar um script com `class_name` novo, rode uma vez `godot --headless --path . --import`, senão o Godot não acha a classe.

## Onde está cada coisa

| Pasta | O que tem |
|---|---|
| `scenes/` | `jogo.tscn` (cena principal), `areas/` (regiões; `valdoria.tscn` e `castelo_imperial.tscn` não aparecem mais no mundo), `inimigos/`, `personagens/`, `criaturas/`, `jogador/` |
| `scripts/` | um sistema por pasta: `jogador`, `camera`, `inimigos`, `personagens`, `criaturas`, `mundo`, `missoes`, `jogo`, `interface`, `importacao` |
| `assets/` | modelos `.glb`/`.gltf` (CC0 na maioria), animações; `ASSETS.md` registra a origem de cada um |
| `tools/` | testes, auditorias e ferramentas (cada arquivo começa com um comentário dizendo para que serve) |
| `docs/` | leis do jogo, história, relatórios de auditoria, fotos dos ajustes |

O mundo é uma ilha aberta de 7,45 x 5,6 km: 6 regiões antigas (Refúgio do Pinhal, Pomar Alto, Bosque Velado, Acampamento da Ruptura, Fortaleza de Ferrogris, Cratera de Ignis), o reino de Valdoria no centro (muralha, cidade, catedral, cidadela no penhasco) e 118 povoados ligados por estradas. A história e as missões estão desligadas (`Jogo.historia = false`). Na primeira vez que o jogo abre ele calcula o chão do mundo e guarda em cache: demora vários minutos; depois abre bem mais rápido.

## Ferramentas que importam

| Para quê | Comando |
|---|---|
| Fotografar cada item num mundo plano (frente, lado, costas, parado e andando) | `godot --path . --resolution 1280x720 --script res://tools/bancada.gd -- depois lobo,vaca` |
| Varredura do mundo sem o Torin (buraco, água, seres no chão) | `godot --headless --path . --script res://tools/drone_auditoria.gd -- nome_da_etapa` |
| Peça de construção sozinha, com o Torin de régua (muralha, rua, feira, catedral) | `godot --path . --resolution 1280x720 --script res://tools/bancada_construcao.gd -- muralha` |
| Fotos de Valdoria dentro do jogo (com filtro opcional) | `godot --path . --resolution 1280x720 --script res://tools/capturar_reino.gd -- 02_ 08_` |
| Auditoria do reino (casas, portões, gente) | `godot --headless --path . --script res://tools/auditoria_reino.gd` |
| Testes sem janela | `godot --headless --path . --script res://tools/teste_mundo.gd` (e os outros `teste_*.gd`) |

## Estado em 24/11/2026 (resumo; o detalhe está em `docs/SESSAO-2026-11-23.md`)

Funciona: campanha principal jogável do início ao fim por testes de marco, mundo contínuo, 3 fases do Fagulha, montaria, clima, NPCs com rotina e medo, Drone/Admin.

**Problemas conhecidos, não resolvidos:**
- O mundo ainda é um corredor norte-sul. O usuário pediu mundo aberto com diversidade, e mandou uma referência de mapa que ainda não foi localizada.
- Textura e animação de todos os animais continuam ruins (cor chapada). Só os olhos foram feitos (11 espécies).
- O lobo ainda tem o corpo alongado demais e olhos levemente assimétricos.
- O percurso real Refúgio→Castelo está **REPROVADO**: o Torin trava em x=-160 indo para o leste vindo do Pomar.
- `tools/teste_caca.gd` é instável (o lobo às vezes não ataca a vaca no curral), já no commit anterior.
- Árvores, grama, drops no chão, casas repetidas e vilas: só foram fotografados, não ajustados.
- A branch `reconstrucao` **não foi fundida** na `fundacao`.

## Branches

`fundacao` é a base aprovada. `reconstrucao` é o trabalho atual (baseline na tag `baseline-reconstrucao`, ver `BASELINE.md`). Nunca commitar direto na `main`/`fundacao`; commits em português, descritivos.
