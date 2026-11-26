# Reino de Cinzas (subtítulo: Sangue e Escamas; pasta: ReinoDeCinzas)

Título oficial: **Reino de Cinzas**. "Sangue e Escamas" é só o subtítulo e não deve aparecer sozinho em código, diálogos ou documentos.

Jogo de ação/RPG em 3ª pessoa, medieval, com dragões. Combate no centro, com evolução de armas e armaduras.
Idioma de trabalho: português do Brasil. Explicar arquitetura em linguagem direta.

## Comece por aqui (para quem abre este repositório pela primeira vez)

1. Este arquivo inteiro: as regras de trabalho e, no fim, o **Estado atual** (o que o jogo é hoje).
2. `README.md`: como rodar, as teclas e onde está cada coisa.
3. `docs/MAPA-DO-TRABALHO.md`: índice de cada script, ferramenta e documento, os testes que valem e a lista de pendências.
4. `docs/LEIS-DO-JOGO.md`: o que nunca pode quebrar e o teste de cada lei.
5. `assets/ASSETS.md`: origem e licença de cada modelo e som.

`docs/historico/` guarda os registros das fases anteriores (ver `docs/historico/LEIA.md`); eles citam coisas que não existem mais e **não** descrevem o jogo de hoje.

## Fundação (aprovada)

- **Motor:** Godot 4.7.2 (GDScript), instalado via Homebrew. Comando `godot` no terminal.
- **Blender:** 5.3.0 em `/Applications/Blender.app` (para modelar e ajustar assets).
- **Estilo visual único:** 3D suave pintado. Nenhum outro estilo misturado (nada de low-poly chapado, voxel ou realista).
- **Câmera:** 3ª pessoa.
- **Gênero:** ação/RPG com combate central, forja de armas e armaduras, libertação de territórios, chefes colossais.
- **Referências de tom (só inspiração, nunca cópia de personagem, cena ou nome):** lealdade e ruptura de bando (Red Dead Redemption 2), vínculo com dragão (Como Treinar o Seu Dragão), evolução e território (ARK), combate e chefes (God of War, Ne Zha 2).

## História

Esta é a história aprovada no começo do projeto. A campanha que a contava está DESLIGADA a pedido do usuário, que vai pensar numa história nova (ver Estado atual).

- **Mundo:** o Império de Drakkar caça e acorrenta os dragões antigos com artefatos de ferro negro para alimentar uma máquina de guerra. Os dragões não são monstros irracionais: são enlouquecidos e escravizados pelos obeliscos e pelos generais do Império.
- **Protagonista:** Torin, jovem comum, sem título nem linhagem, criado como batedor e lenhador num bando de exilados na fronteira selvagem.
- **Bando:** vive nas florestas e montanhas. Liderado por Vane, que começa protegendo o grupo, mas enlouquece de ambição por roubar o poder dos dragões para si.
- **Virada:** numa caçada, Torin encontra um dragão jovem ferido, Fagulha, e descobre a verdade sobre os dragões.
- **Escalada:** Torin começa do zero, evolui armas e armaduras, liberta territórios selvagens, enfrenta chefes colossais (generais encouraçados, bestas guardiãs, dragões corrompidos) e desafia tanto o Império quanto a traição dentro do bando.

## Nomes

- **Protagonista:** Torin
- **Local inicial:** Refúgio do Pinhal (acampamento do bando)
- **Líder do bando (mentor que vira rival):** Vane
- **Ferreira e aliada:** Brenn
- **Dragão aliado jovem:** Fagulha
- **Império:** Império de Drakkar
- **Chefes principais, em ordem:**
  1. Brutamontes Gorath (guardião da floresta/mina inicial)
  2. General Kaelor (comandante da fronteira do Império)
  3. Ignis-Maw (dragão ancestral corrompido pelo ferro negro)
  4. Imperador Solon (chefe final, castelo central)

Mudou um nome? Atualizar aqui e varrer o projeto inteiro. Nomes de outros lugares, bestas comuns e NPCs menores ainda não foram definidos: propor e aprovar antes de usar.

## Leis do jogo e conferência

Ler `docs/LEIS-DO-JOGO.md` antes de mexer no mundo. Depois de qualquer mudança no mundo, rodar `tools/teste_mundo.gd` e `tools/auditoria_reino.gd` e fotografar o que mudou com `tools/capturar_reino.gd -- <filtro>`. Peça nova de construção ou criatura nova passa primeiro pela bancada (`tools/bancada_construcao.gd`, `tools/bancada.gd`). Nunca declarar pronto por uma foto só.

Branch de trabalho: `claude/brave-wozniak-fu9kif`. O branch `reconstrucao` e a tag `baseline-reconstrucao` são o ponto de partida antigo (ver `docs/historico/BASELINE.md`).

## Regras de trabalho

### Arquitetura
- Modular e limpa: um sistema por vez (jogador, câmera, combate, inimigo, inventário, forja...). Cada sistema numa pasta própria, com uma responsabilidade clara.
- Sem código morto, sem remendo em cima de remendo. Achou código morto? Avisar, não apagar sozinho.
- Mínimo de código que resolve. Nada de abstração para coisa usada uma vez.
- Comunicação entre sistemas por sinais do Godot, não por referência direta a nós distantes.
- Antes de tocar em código, ler o que já existe. Nunca presumir estrutura.

### Modelos 3D e animações
- Só entram no jogo assets **validados**, dentro de `assets/models/` (um subdiretório por tipo: `personagens/`, `criaturas/`, `armas/`, `cenario/`).
- Cada asset novo ganha uma linha em `assets/ASSETS.md`: origem (Blender, baixado de onde, gerado), licença, estilo conferido, e se tem rig/animações.
- Formato preferido: `.glb`. Animações embutidas no arquivo, **ativadas de forma explícita no código** (nome da animação no `AnimationPlayer`, nunca depender do autoplay).
- Nunca improvisar geometria complexa por conta própria. Se faltar um asset, parar e dizer: "falta o modelo X". Proibido placeholder escondido (caixa, cápsula) fingindo ser o modelo final.
- Se for preciso um stand-in temporário, ele fica **visível e nomeado** como `PLACEHOLDER_...`, listado em `assets/ASSETS.md` como pendência, e nunca conta como tarefa concluída.
- Modelar no Blender e pesquisar modelos no navegador é permitido. Baixar arquivo só com OK do usuário. Todo asset novo tem que passar no estilo "3D suave pintado" antes de entrar.

### Animais e criaturas: bancada isolada (regra do usuário, pedida mais de 5 vezes)
- Todo animal ou criatura nova ou alterada (lobo, cavalo, javali...) é aberta e testada SOZINHA numa cena de bancada: chão plano, sem mundo, sem NPCs, o Torin ao lado como régua. Só depois de aprovada ali ela entra no jogo.
- Na bancada, fotografar de frente, de lado e de costas, parada e andando: textura e cor, tamanho contra o Torin, e se o modelo OLHA para onde anda (frente do modelo = direção da velocidade; nunca andar de costas).
- Critério de anatomia, conferido em foto AMPLIADA da cabeça e das juntas (a folha geral não mostra): o olho fica na face da cabeça, acima da linha onde começa o focinho e abaixo das orelhas, com os dois olhos visíveis de frente e a pupila rente ao olho, olhando para a frente; cabeça, pescoço, rabo e patas ficam ligados ao corpo, sem vão.
- Testar também correr, atacar e morrer, e abrir a janela para o usuário ver. Teste de lógica sozinho não vale como prova de aparência.
- Defeito visual conhecido não vira "pendência visual": é bug e entra na lista antes de qualquer outra coisa.

### Construções: uma peça por vez, em bancada (regra do usuário, 26/11/2026)
- O usuário achou os animais "incríveis" e as construções sem detalhe, e pediu o mesmo método: **focar numa peça só até ficar pronta, depois a seguinte** (primeiro a muralha, depois a rua, depois a casa...). Nada de mexer em muralha, rua, casa e castelo na mesma rodada.
- Cada peça é construída e fotografada SOZINHA em `tools/bancada_construcao.gd` (chão plano, sem mundo, o Torin ao lado como régua; roda em segundos). Só depois de aprovada ali ela entra em Valdoria.
- Antes de começar a peça, escrever o critério de pronto em `docs/construcoes/<peca>.md`. Conferir em foto AMPLIADA (de longe, de perto, de cima, por dentro, as emendas com o chão). Defeito visto na foto é corrigido e fotografado de novo antes de mostrar.
- A prioridade do usuário agora é o jogo ficar BONITO; desempenho e carregamento ficam para depois (palavras dele).

### Verificação (nada é "pronto" sem prova)
- Nunca marcar tarefa como concluída sem verificação real: rodar o jogo/cena, ler os **logs** e tirar **captura de tela direcionada** do que foi mudado.
- Mostrar a saída ao usuário. "Parece pronto" não é pronto.
- Declarar sempre o método: li o código, rodei, ou olhei a captura.
- Erro? Atacar a causa raiz. Nunca suprimir erro ou aviso para o build passar.
- Achou defeito na captura? Corrigir e capturar de novo antes de entregar.

### Ritmo
- Trabalhar em **blocos pequenos e testáveis**. Cada bloco tem critério de sucesso escrito antes de começar.
- Salvar o progresso a cada etapa aprovada (commit em português, descritivo). Nunca commitar direto na `main`: criar branch antes de mexer.
- Trabalho que toca vários arquivos: plano primeiro, esperar aprovação.
- Se existir mais de uma interpretação do pedido, apresentar todas. Nunca escolher em silêncio.

## Como o usuário quer trabalhar (decisões dele, em ordem; a mais nova vale)

- Não é engenheiro: responder em português do Brasil, curto, com prova (foto, número, saída de teste).
- 25/11: prioridade é o jogo ficar BONITO; desempenho e tempo de carregamento ficam para depois.
- 25/11: construir tudo primeiro e atacar os pontos fracos depois; não parar para aprovar peça por peça. Os pontos fracos ficam anotados em `docs/construcoes/<peca>.md`. A bancada continua obrigatória antes de a peça entrar no mundo.
- 25/11: ficar só o que o jogo usa, com os arquivos organizados.
- 26/11: não quer atualização no meio do trabalho nem mensagem longa; quer "pronto" ou "não pronto", e que eu olhe as fotos. Só dizer "pronto" e "pode baixar" quando estiver de verdade.
- Pode criar nomes (ficam marcados "a aprovar"). Baixar modelo: ele autorizou para o tubarão e para os dragões; para outro tipo de asset, pedir de novo.
- A história e as missões estão desligadas a pedido dele; ele vai pensar numa história nova.

## Estrutura do projeto

```
CLAUDE.md, README.md, project.godot
assets/      modelos (.glb, .gltf, .fbx, .dae), animações, sons; ASSETS.md registra a origem de cada um
scenes/      jogo.tscn (cena principal), areas/ (as 6 regiões antigas), personagens/, inimigos/, criaturas/, jogador/, teste/casa_teste.tscn
scripts/     um sistema por pasta: jogo, jogador, camera, personagens, criaturas, inimigos, interface, som, mundo, missoes, importacao
tools/       testes, auditoria, bancadas, ferramentas de foto e geradores (audio/, criaturas/, itens/, mundo/, personagens/, fagulha/)
docs/        LEIS-DO-JOGO.md, MAPA-DO-TRABALHO.md, HISTORIA-E-MISSOES.md, construcoes/, galeria/, mapa-novo/, validacao/, auditoria/, historico/
```

## Estado atual (26/11/2026)

**O que o jogo é hoje:** mundo aberto em 3ª pessoa numa ilha de 7,45 x 5,6 km cercada de mar. Sem história: `Jogo.historia = false`. O Torin começa no Refúgio do Pinhal com a espada curta, 2 pães e 15 moedas, e a Fagulha já o acompanha crescida e montável.

**O mundo** (planta em `scripts/mundo/mundo_dados.gd`; quem constrói é `scripts/mundo/mundo.gd`):
- 6 regiões antigas (cenas em `scenes/areas/`): Refúgio do Pinhal, Pomar Alto, Bosque Velado, Acampamento da Ruptura, Fortaleza de Ferrogris, Cratera de Ignis.
- Valdoria no centro: muralha com 27 torres e 3 portões (`muralha_do_reino.gd`, kit `pecas_da_muralha.gd`), 610 casas com rua (`casario_do_reino.gd`, `pecas_da_rua.gd`), praça do mercado, catedral (`catedral.gd`), quartel, estábulos, cidadela no penhasco de 64 m com o Rei Aldren (`cidadela.gd`).
- 119 povoados (vilas, fazendas, cabanas, pescadores, postos; `povoado.gd`), 32 estradas com marcos e pousos, pontes com cabeceiras.
- Montanha dos Dragões (240 m, trilha em espiral, ninho, 9 dragões de 4 modelos; o cinza do ninho doma-se com 3 carnes e vira a montaria Cinza).
- Terras do Gelo no extremo norte (bioma "gelo", Lago Congelado, Vila Geada).
- Mar com tubarão (mata quem passa do raso).
- O chão é feito em blocos e fica em cache em `user://chao_do_mundo_<hash>.bin`. Mexer em `mundo_dados.gd`, `terreno_mundo.gd`, `terreno.gd`, `costa.gd` ou `biomas.gd` recalcula tudo (aqui, ~7 a 10 minutos); com cache a carga leva ~3 a 4 minutos neste ambiente.

**O que o jogador faz:** andar, correr, pular, rolar, golpear (um golpe só), montar cavalo, Fagulha e Cinza (os dragões voam), caçar e pegar itens, comer (há FOME: cai com o tempo, a zero tira vida), equipar arma (espada curta, machado, espada longa, katana) e armadura (couro, ferro; aparecem no corpo), comprar, vender e pechinchar nos balcões, forjar nas bigornas, minerar ferro com picareta, abrir o mapa (M) e marcar destino, inventário (I). O jogo salva sozinho (`scripts/jogo/salvar_jogo.gd`) e tem som (`scripts/som/sons.gd`).

**Como conferir:** `tools/teste_mundo.gd` (cobre mundo, Valdoria, montanha, gelo, som, salvar, fome, equipar, comércio, forja, mineração), `tools/auditoria_reino.gd`, `tools/capturar_reino.gd`, as bancadas. O estado de cada teste antigo está na tabela de `docs/MAPA-DO-TRABALHO.md`.

**Nunca conferido:** o jogo no Mac do usuário (desempenho, tempo de abertura, cor da água) e o SOM (este ambiente não tem saída de áudio: os sons foram gerados por síntese e só testados por contagem).

**Código que existe e está desligado ou sem uso** (decisão pendente do usuário, não apagar sem ele pedir):
- A campanha antiga: `scripts/missoes/` e as partes de missão nas 6 regiões e em `scripts/jogo/jogo.gd`. As regiões dependem de `GerenciadorMissoes` para chefes, eventos e avisos na tela; tirar é reescrever essas regiões. As missões do Capítulo V citam Valdoria e o Castelo antigos, que saíram: a campanha não é mais jogável até o fim.
- `docs/HISTORIA-E-MISSOES.md` descreve essa campanha antiga.
- Animações `dragon_walk.dae` e `dragon_attack.dae` do dragão de espinhos: instaladas, sem uso.

**Não existe ainda:** nadar (o Torin anda no fundo do mar), cortar árvore, lança, elmo e perneira, neve caindo, dragões que atacam ou reagem, minimapa, mais de um golpe, bloqueio, arco, história nova. Modelo próprio para cervo (usa o do cavalo), arqueiro/guarda/Kaelor (mesmo boneco) e chefes.

**Nomes criados por mim, a aprovar pelo usuário:** Rei Aldren, Conselheiro Meren, o dragão Cinza, Vila Geada, Lago Congelado, Terras do Gelo, Trilha dos Dragões, Trilha do Gelo, e os nomes de bairros, mercados e povoados da ilha (lista em `docs/mapa-novo/PLANO-REINO-100.md`).

**Armadilhas deste ambiente (contêiner sem placa de vídeo):**
- Classe nova (`class_name`): rodar `godot --headless --path . --import` e depois SEMPRE `git checkout -- assets/animations/ual/ual1_biblioteca.res` (a importação mexe nesse arquivo).
- Fotos: `xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 1280x720 --script res://tools/<x>.gd`. A cor do céu e da água não é confiável aqui.
- Não editar script enquanto uma sequência de testes roda em segundo plano (cada etapa recarrega os scripts).
- `:=` com valor vindo de Array ou laço sem tipo dá "Cannot infer the type": declarar o tipo.
- Arquivo `.blend` baixado da internet NÃO se abre (o sistema bloqueia). Modelos baixados entram por FBX, DAE ou glTF, importados pelo Godot.
- `tools/bancada.gd` grava em `/Users/faresrames/Desktop/ajustes` quando essa pasta existe, senão em `tools/capturas/bancada`.
