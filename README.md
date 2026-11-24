# Reino de Cinzas (subtítulo: Sangue e Escamas)

Jogo de ação/RPG em 3ª pessoa, medieval, com dragões. Godot 4.7.2 (GDScript), renderizador mobile (Metal no Mac). Idioma do projeto: português do Brasil.

Torin, um batedor sem título, descobre que o Império de Drakkar escraviza dragões com ferro negro, salva o dragão jovem Fagulha e enfrenta o Império e a traição do próprio bando (Vane). História e nomes: `CLAUDE.md` e `docs/HISTORIA-E-MISSOES.md`.

## Se você é outro Claude (ou pessoa) abrindo este repositório

**Leia nesta ordem, antes de mexer em qualquer coisa:**
1. `CLAUDE.md`: regras de trabalho, nomes aprovados e estado do projeto. É obrigatório.
2. `docs/SESSAO-2026-11-23.md`: o que foi feito na última sessão, os erros cometidos e o que falta. **Estado atual: NÃO MERGE.**
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
| `scenes/` | `jogo.tscn` (cena principal), `areas/` (8 regiões), `inimigos/`, `personagens/`, `criaturas/`, `jogador/` |
| `scripts/` | um sistema por pasta: `jogador`, `camera`, `inimigos`, `personagens`, `criaturas`, `mundo`, `missoes`, `jogo`, `interface`, `importacao` |
| `assets/` | modelos `.glb`/`.gltf` (CC0 na maioria), animações; `ASSETS.md` registra a origem de cada um |
| `tools/` | testes, auditorias e ferramentas (cada arquivo começa com um comentário dizendo para que serve) |
| `docs/` | leis do jogo, história, relatórios de auditoria, fotos dos ajustes |
| `wip/` | laboratório fora do Godot (`.gdignore`); não apagar |

O mundo é contínuo: 8 regiões (Refúgio do Pinhal, Pomar Alto, Bosque Velado, Acampamento da Ruptura, Fortaleza de Ferrogris, Cratera de Ignis, Valdoria, Castelo Imperial) ligadas por estradas, com 21 povoados. As posições estão em `scripts/mundo/mundo_dados.gd`.

## Ferramentas que importam

| Para quê | Comando |
|---|---|
| Fotografar cada item num mundo plano (frente, lado, costas, parado e andando) | `godot --path . --resolution 1280x720 --script res://tools/bancada.gd -- depois lobo,vaca` |
| Varredura do mundo sem o Torin (buraco, água, seres no chão) | `godot --headless --path . --script res://tools/drone_auditoria.gd -- nome_da_etapa` |
| Agente que anda do Refúgio ao Castelo com teclas reais | `godot --path . --resolution 1280x720 --script res://tools/percurso_real.gd` |
| Abrir o jogo com um lobo ao lado do Torin | `godot --path . --resolution 1280x720 --script res://tools/abrir_com_lobo.gd` |
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
