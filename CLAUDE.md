# Reino de Cinzas (subtítulo: Sangue e Escamas; pasta: ReinoDeCinzas)

Título oficial: **Reino de Cinzas**. "Sangue e Escamas" é só o subtítulo e não deve aparecer sozinho em código, diálogos ou documentos.

Jogo de ação/RPG em 3ª pessoa, medieval, com dragões. Combate no centro, com evolução de armas e armaduras.
Idioma de trabalho: português do Brasil. Explicar arquitetura em linguagem direta.

## Comece por aqui (para quem abre este repositório pela primeira vez)

Leia `README.md`, depois `docs/SESSAO-2026-11-23.md` (o que foi feito, os erros e o que falta; **estado atual: NÃO MERGE**) e `docs/MAPA-DO-TRABALHO.md` (índice de ferramentas, documentos e pendências). Fotos dos ajustes: `docs/ajustes/`.

## Fundação (aprovada)

- **Motor:** Godot 4.7.2 (GDScript), instalado via Homebrew. Comando `godot` no terminal.
- **Blender:** 5.3.0 em `/Applications/Blender.app` (para modelar e ajustar assets).
- **Estilo visual único:** 3D suave pintado. Nenhum outro estilo misturado (nada de low-poly chapado, voxel ou realista).
- **Câmera:** 3ª pessoa.
- **Gênero:** ação/RPG com combate central, forja de armas e armaduras, libertação de territórios, chefes colossais.
- **Referências de tom (só inspiração, nunca cópia de personagem, cena ou nome):** lealdade e ruptura de bando (Red Dead Redemption 2), vínculo com dragão (Como Treinar o Seu Dragão), evolução e território (ARK), combate e chefes (God of War, Ne Zha 2).

## História

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

## Leis do jogo e auditoria

Ler `docs/LEIS-DO-JOGO.md` antes de mexer no mundo: as regras que nunca podem ser quebradas e o teste de cada uma. A varredura do mundo todo sem o Torin é `tools/drone_auditoria.gd` (relatórios em `docs/auditoria/`, um por etapa). Branch de trabalho da reconstrução: `reconstrucao` (baseline na tag `baseline-reconstrucao`, ver `BASELINE.md`). Nunca declarar uma etapa pronta por uma foto só: rodar a suíte inteira e a varredura.

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

## Estrutura prevista (criada só quando o bloco precisar)

```
ReinoDeCinzas/
  CLAUDE.md
  project.godot
  assets/
    ASSETS.md
    models/{personagens,criaturas,armas,cenario}/
    audio/
  scenes/
  scripts/
  docs/
```

## Estado atual

- Fundação, história e nomes aprovados. Godot e Blender conferidos.
- Projeto Godot criado na raiz (`project.godot`). Primeiro asset validado: `assets/models/criaturas/fagulha/fagulha.glb` (movimento base: Walk, Run, Idle, Fly em loop). Detalhes e pendências em `assets/ASSETS.md`. Ferramentas em `tools/fagulha/`, evidências em `docs/validacao/fagulha/`.
- `wip/` é laboratório e fica fora do Godot (`wip/.gdignore`): ali ficam o esboço de dragão esculpido por código (descartado em favor da base rigada) e os testes antigos. Não apagar sem o usuário pedir.
- Referências de anatomia (só leitura, nunca copiar a malha): dragões em `/Volumes/Extreme SSD/JOGO/modelos-3d/baixados_usuario/dragoes/` e em `~/Downloads`.
- Cena de teste montada e validada (`scenes/teste/cena_teste.tscn`): câmera em 3ª pessoa (`scripts/camera`), jogador com WASD e Shift (`scripts/jogador`), Fagulha que segue o jogador e voa com a tecla F (`scripts/criaturas`). Teste automático: `godot --path . --resolution 1280x720 --script res://tools/teste_cena.gd` (log e capturas em `docs/validacao/cena_teste/`).
- Fase A concluída: Torin, Vane e Brenn são humanoides reais (pacotes CC0 do Quaternius: base, trajes, animações), com o mesmo esqueleto de 65 ossos e 43 animações compartilhadas. O `PLACEHOLDER_Torin` foi substituído. Registro em `assets/ASSETS.md`; geração em `tools/personagens/`.
- Fases B a D (21/11/2026): mundo jogável de ponta a ponta. `scenes/jogo.tscn` é a cena principal (jogador, Fagulha, câmera, interface); as áreas ficam em `scenes/areas/`; inimigos em `scenes/inimigos/`. Teste de jogada completa: `godot --path . --resolution 1280x720 --script res://tools/teste_jogo.gd` (evidências em `docs/validacao/jogo/`).
- NPCs menores propostos por mim (não aprovados antes): Orin (vigia), Tessa (cozinheira), Dorn (lenhador), Mira (caçadora). Criaturas comuns: Lobo-cinza e Javali Couraçado (ver `assets/ASSETS.md`) e Filhote de Asa.
- Animais (21/11/2026): vaca, cavalo, ovelha, porco e cão povoam o Refúgio (`scripts/criaturas/animal_vila.gd`, gerados por `tools/criaturas/gerar_animais.py`). Faltam galinha, cervo, urso, coelho, aves, peixes, aranha, wyvern e cão de guerra.
- Lobo e javali têm silhueta própria (versão 1, ver `assets/ASSETS.md`).
- Interiores com móveis reais (Fantasy Props MegaKit, CC0), dano em animais e NPCs, montaria no cavalo e no Fagulha (E para montar; no dragão, Espaço sobe e C desce). Testes: `tools/teste_montaria_dano.gd` e `tools/teste_moveis.gd`.
- Drops (carne, couro, lã, presa) com inventário, pelagens variadas, fogo que queima, portas que abrem e fecham, chão com capim e flores, cavalo que pula e animação de montar (ver `assets/ASSETS.md`). Teste: `tools/teste_montaria_dano.gd`.
- Inventário do jogador (tecla I): grade com ícones, descrição e uso (carne cura 20). Teste: `tools/teste_inventario.gd`.
- Colisão de seres vivos (animais, pessoas, Fagulha) e peças do cenário: ver `assets/ASSETS.md`. Testes só quando a mudança pedir e uma vez (o usuário reclamou de demora).
- NPCs com rotinas de trabalho (ferreiro, lenhador, cozinheira, vigia, caçadora, líder): ver `assets/ASSETS.md`.
- Campanha por marcos segundo a Bíblia expandida (ver `assets/ASSETS.md`, seção Campanha). Marcos 1 (missões), 2 (Refúgio como vila), 3 (Pomar Alto, C1-M2 a M4, Fagulha ferida), 4 (Bosque Velado e Mina, C2-M1 a M4) 5 (Acampamento da Ruptura e Fortaleza de Ferrogris, C3-M1 a M4) 6 (Cratera de Ignis, C4-M1 a M4) e 7 (Valdoria e o Castelo Imperial, C5-M1 a M4, com epílogo) feitos: a campanha principal está jogável do início ao fim. Auditoria do mundo feita em 22/11 (ver `assets/ASSETS.md`, seção Auditoria): rodar `tools/auditoria_mundo.gd`, `tools/auditoria_portais.gd` e `tools/teste_cadeia.gd` ao fim de cada marco; mapa do mundo na tecla M. Rios e vales escavados no terreno com pontes (ver `assets/ASSETS.md`, seção Vales e rios). Mundo contínuo sem portais (regiões ligadas por estradas, rios, pontes, povoados e fazendas), clima com dia e noite, tempestade e NPCs com horário (ver seção Mundo contínuo). Ao fim de cada marco rodar também `tools/auditoria_continua.gd` e `tools/teste_mundo.gd`. Mundo aberto (cristas de rocha com vão só nas barreiras, 21 povoados, NPCs que fogem de monstros): ver `assets/ASSETS.md`, seção Mundo aberto; rodar também `tools/auditoria_cercos.gd`, `tools/auditoria_buracos.gd`, `tools/auditoria_logica.gd` (construção sobre construção, coisa dentro de campo, casa flutuando, gente na parede, porta bloqueada) e `tools/teste_medo.gd`. Regra de layout (pesquisada): casas e quintal junto à estrada, campo atrás da casa com cerca no eixo do próprio campo e portão para o quintal, feno junto ao celeiro, bebedouro dentro do curral, espantalho no meio do campo. Pendências gerais: sons de verdade, ciclo do dia, salvar/checkpoints, evolução do Fagulha, modelos próprios para os chefes.
- Próximo: dar uso a couro/lã/presa (forja da Brenn, vender), salvar o inventário, corpo de lobo mais magro, dar silhueta própria aos chefes, mais golpes e animações de combate, interface com arte, interiores, mais regiões e a cidade de Valdoria de verdade.
- 22 e 23/11/2026 (estabilização e correções visuais): relatório e erros em `docs/SESSAO-2026-11-23.md`. Criados `tools/bancada.gd` (fotografa cada item num mundo plano), `scripts/criaturas/olhos.gd` (olhos de 11 espécies), `tools/percurso_real.gd` (agente que anda do Refúgio ao Castelo; **reprovado**, trava em x=-160). Lobo girado e reduzido. Abertos: textura e animação dos animais, mapa aberto (o usuário mandou uma referência ainda não localizada), árvores, drops, vilas, `teste_caca` instável. A recomendação de merge foi retirada.
- 24 e 25/11/2026 (RUMO NOVO, pedido pelo usuário): o jogo virou MUNDO ABERTO numa ilha de 7,45 x 5,6 km (medida do mapa de Red Dead Redemption 2), cercada de mar com tubarão (`scripts/criaturas/tubarao.gd`, ainda `PLACEHOLDER_Tubarao`). Sem serras nem barreiras. Reino de Valdoria no centro com muralha de 1,1 km, 4 portões, bairros, mercados, quartel, estábulos e ~390 casas de rua. 117 povoados, 52 estradas. Mapa da tecla M interativo, em estilo de mapa antigo (`scripts/interface/mapa_do_mundo.gd` e `pintura_do_mapa.gd`). O chão do mundo é feito em blocos e fica em cache em `user://` (primeira carga depois de mexer na planta: vários minutos). Planta em `scripts/mundo/mundo_dados.gd`; povoados sorteados e Estrada da Costa por `tools/mundo/encher_o_mundo.py`. Ler `docs/mapa-novo/PLANO-REINO-100.md`. Depois de mexer no mundo rodar `tools/teste_mundo.gd` e `tools/auditoria_reino.gd`; fotos com `tools/capturar_reino.gd`, `capturar_mapa.gd` e `capturar_ilha.gd`. A história e as missões antigas continuam ligadas e serão repensadas pelo usuário; NOMES de bairros, mercados e povoados novos são provisórios (a aprovar). As auditorias antigas do corredor (portais, cercos, contínua, percurso real) ainda NÃO foram revistas para a ilha.
- 25/11/2026 (VALDORIA, estado atual): o reino foi refeito na planta e nas proporções do "Reino de Aethelgard" que o usuário tinha feito em blocos (referência dele, só composição; o estilo continua o do jogo). Penhasco de 64 m no centro (`MundoDados.penhasco`), rampa em volta dele (leste -> face sul -> portão da cidadela a oeste), cidadela branca com 28 torres e Salão do Trono com o Rei Aldren (`scripts/mundo/cidadela.gd`), muralha oval irregular com 3 portões (`muralha_do_reino.gd`), casario em faixas (`casario_do_reino.gd`, casas em MultiMesh com fachadas pintadas de `fachadas.gd`; não se entra nelas), calçamento de pedra (`calcamento_do_reino.gd`), fonte, lampiões e jardins (`vida_das_ruas.gd`), praças como povoados (mercado, quartel, estábulos, catedral, guaritas, lavouras). As regiões antigas `valdoria` e `castelo_imperial` SAÍRAM do mundo (as cenas continuam no projeto). A HISTÓRIA e as missões estão DESLIGADAS por `Jogo.historia = false` (pedido do usuário); os testes antigos da campanha ligam a chave, e os que passavam por Valdoria e pelo Castelo deixaram de valer. Nomes novos foram criados com autorização dele (lista em `docs/mapa-novo/PLANO-REINO-100.md`). Conferir sempre com `tools/teste_mundo.gd`, `tools/auditoria_reino.gd` e `tools/capturar_reino.gd` (fotos em `docs/mapa-novo/reino_v4/`).
