# Reino de Cinzas (subtítulo: Sangue e Escamas)

Jogo de ação e exploração em 3ª pessoa, medieval, com dragões. Godot 4.7.2 (GDScript). Idioma do projeto: português do Brasil.

Hoje é um mundo aberto numa ilha de 7,45 x 5,6 km: o reino de Valdoria no centro (muralha, cidade, catedral, cidadela no penhasco), 119 povoados ligados por estradas, a Montanha dos Dragões, as Terras do Gelo no norte e o mar em volta. Não há história nem missões ligadas: explora-se, caça-se, come-se, compra-se, forja-se e doma-se um dragão.

## Se você é outro Claude (ou pessoa) abrindo este repositório

Leia nesta ordem, antes de mexer em qualquer coisa:

1. `CLAUDE.md`: regras de trabalho, como o usuário quer trabalhar e o **Estado atual**. É obrigatório.
2. Este arquivo: como rodar e onde está cada coisa.
3. `docs/MAPA-DO-TRABALHO.md`: índice de scripts, ferramentas e documentos, quais testes valem e as pendências.
4. `docs/LEIS-DO-JOGO.md`: o que nunca pode quebrar.
5. `assets/ASSETS.md`: origem e licença de cada modelo e som.

`docs/historico/` são registros de fases anteriores; não descrevem o jogo de hoje.

## Rodar o jogo

Na primeira vez depois de baixar (ou de trocar de branch), importe os arquivos uma vez:

```bash
godot --headless --path . --import
```

Depois:

```bash
godot --path . --resolution 1280x720
```

A cena principal é `scenes/jogo.tscn`. **A primeira abertura demora vários minutos**: o jogo calcula o chão da ilha inteira e guarda em cache; nas seguintes abre mais rápido. O jogo nunca foi rodado no Mac do usuário: desempenho, tempo de abertura, som e cor da água ainda precisam ser conferidos lá.

O jogo salva sozinho a cada 20 segundos e ao fechar a janela (arquivo `jogo_salvo.json` na pasta de dados do Godot) e continua de onde parou. Apagar esse arquivo recomeça do Refúgio do Pinhal.

## Teclas

| Tecla | O que faz |
|---|---|
| W A S D, Shift | andar, correr |
| Espaço | pular (no dragão: subir) |
| C | no dragão: descer |
| J ou clique | golpe |
| K | rolar |
| E | falar, montar e desmontar, usar balcão, bigorna, veio de ferro, domar |
| F | manda a Fagulha voar ou pousar |
| I | inventário (comer, equipar arma e armadura) |
| M | mapa (roda do mouse aproxima, arrastar move, clique marca destino) |
| Esc | solta o mouse; fecha janelas |
| F1 a F6, F9, F10, F11 | teste: teleporte às 6 regiões, hora, tempo, câmera livre (`scripts/jogo/admin.gd`) |

## Onde está cada coisa

| Pasta | O que tem |
|---|---|
| `scenes/` | `jogo.tscn` (cena principal), `areas/` (as 6 regiões antigas), `personagens/`, `inimigos/`, `criaturas/`, `jogador/` |
| `scripts/` | um sistema por pasta: `jogo`, `jogador`, `camera`, `personagens`, `criaturas`, `inimigos`, `interface`, `som`, `mundo`, `missoes` (desligado), `importacao` |
| `assets/` | modelos, animações e sons; `ASSETS.md` registra a origem e a licença de cada um |
| `tools/` | testes, auditoria, bancadas, ferramentas de foto e geradores de assets |
| `docs/` | leis do jogo, índice do trabalho, uma pasta por peça construída (`construcoes/`), galeria de fotos de tudo (`galeria/`), histórico |

## Conferir depois de mexer

| Para quê | Comando |
|---|---|
| Teste do mundo inteiro (sem janela) | `godot --headless --path . --script res://tools/teste_mundo.gd` |
| Auditoria de Valdoria (casas, portões, gente) | `godot --headless --path . --script res://tools/auditoria_reino.gd` |
| Fotos dentro do jogo (o filtro é opcional) | `godot --path . --resolution 1280x720 --script res://tools/capturar_reino.gd -- 02_ 08_` |
| Uma peça de construção sozinha, com o Torin de régua | `godot --path . --resolution 1280x720 --script res://tools/bancada_construcao.gd -- muralha` |
| Cada item do jogo sozinho (frente, lado, costas) | `godot --path . --resolution 1280x720 --script res://tools/bancada.gd -- depois lobo` |
| Folhas de fotos de tudo | `python3 tools/montar_galeria.py` (depois de rodar as bancadas e as capturas) |

Peças da bancada de construção: `muralha`, `rua`, `feira`, `catedral`, `quartel`, `acampamento`, `tubarao`, `dragoes`, `armaduras`.

Depois de criar um script com `class_name` novo, rode `godot --headless --path . --import`, senão o Godot não acha a classe.
