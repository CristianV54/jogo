# Inventário de defeitos (24/11/2026)

Lista única do que está errado no jogo, montada olhando fotos e medindo. Nada foi corrigido nesta etapa.
Fotos de prova em `docs/inventario/`. Medidas de movimento em `docs/inventario/MEDIDAS-DE-MOVIMENTO.md`.

Como ler a coluna "Como vi": **foto** = abri a imagem; **medi** = rodei um script e li o número; **teste** = um teste automático falhou; **li** = só li o código.

Aviso sobre as fotos: foram tiradas num servidor sem placa de vídeo, com o renderizador OpenGL (o jogo no Mac usa o `mobile`/Metal). Forma, tamanho, posição e animação valem. **Cor da água, névoa e brilho podem sair diferentes do Mac** e não entram como defeito aqui sem conferência no Mac.

## A. Quebram o jogo (corrigir primeiro)

| # | Defeito | Como vi | Causa |
|---|---|---|---|
| A1 | **NÃO ERA DEFEITO DO JOGO (24/11).** As 46 violações vinham do teste desatualizado: uma vaca de teste nascia dentro do Depósito de Grãos e outra saía pelo portão oeste, ambos criados depois do teste. Teste corrigido: 0 violações em 3 rodadas de 1240 amostras. Animais atravessam parede de casa e cerca: 46 violações em 1280 amostras (40 em casa, 6 em cerca) | teste `teste_animais_obstaculos` | não investigada |
| A2 | **CORRIGIDO em 24/11.** Causa: o chão do mundo descia 0,2 m exatamente na linha da borda oeste e norte de cada região e a beirada do chão da região virava um degrau. Não era só o Refúgio: o Torin ficava preso em 18 de 96 entradas (Refúgio, Pomar, Bosque, Ferrogris, Cratera, Castelo); depois da correção em `terreno_mundo.gd`, 0 de 96 (`tools/teste_bordas.gd`). O percurso real Refúgio→Castelo ainda não foi repetido. O Torin trava em x=-160 na entrada oeste do Refúgio, vindo do Pomar. O percurso real Refúgio→Castelo está reprovado | relatório da sessão anterior (não repeti) | não confirmada |
| A5 | **CORRIGIDO em 24/11.** Não dava para entrar no Castelo Imperial a pé: a rampa da escadaria chegava ao alto 2 m depois da face da plataforma (degrau de 0,33 m) e um mastro de bandeira ficava no meio do portão | percurso real (o agente parou em (584, -2191,6)); medi andando em 3 faixas | `castelo_imperial.gd`; os testes de marco teleportam e não pegavam |
| A6 | **Percurso real Refúgio→Castelo coberto em 24/11**, em 6 trechos com retomada (não numa rodada só): ver `docs/auditoria/PERCURSO_REAL_2026-11-24.md`. Falta repetir numa rodada única num computador com placa de vídeo | rodei | servidor a 2 a 5 quadros por segundo |
| A3 | 158 peças grandes sem colisão (60 na Cratera, 19 em Valdoria, 16 em casas, 9 no Refúgio, resto em prédios) | medi (`auditar_colisao`) | falta separar o que é decoração fina do que é parede |
| A4 | "Cair no fim do nada e morrer": as varreduras dizem 0 buracos, mas você viu acontecer. Falta achar o lugar | não reproduzi | desconhecida. Preciso que você diga a região, ou eu ando o mapa todo com o agente |

## B. Lógica e comportamento

| # | Defeito | Como vi | Causa |
|---|---|---|---|
| B1 | **CORRIGIDO em 24/11.** O lobo caçava, mas às vezes escolhia a ovelha vizinha (o teste só olhava a vaca) e às vezes ficava encostado na vaca no limite do alcance sem morder. O alcance da mordida agora conta a partir do corpo da vítima (`inimigo.gd`) e o teste vale qualquer bicho do curral: 5 de 5 rodadas passam. O lobo não ataca a vaca no curral (vida 40 → 40) | teste `teste_caca` | não investigada |
| B2 | Lobo "ataca de costas": nesta versão a cabeça aponta para onde ele anda (0,94). O ataque em si ainda não foi filmado | medi (`diag_frente_lobo`) | pendente de filme do ataque |
| B3 | **CORRIGIDO em 24/11** (persegue sempre com a animação de correr). Inimigo persegue a menos de 10 m com a animação de ANDAR na velocidade de CORRER | li (`inimigo.gd`, linha 108) | regra de escolha da animação |
| B4 | NPC foge de inimigo: o teste passa, mas só cobre um caso (lobo solto perto de 3 civis) | teste `teste_medo` | cobertura fraca do teste |

## C. Animais e criaturas: aparência

| # | Defeito | Como vi | Causa |
|---|---|---|---|
| C1 | **CORRIGIDO em 24/11** (fotos em `docs/ajustes/2026-11-24_cor_e_olhos/`). Vaca, cavalo, ovelha, porco, cervo e javali saem **brancos puros**, sem pelagem. Cão, coelho, urso e cão de guerra saem coloridos | foto (`bancada_A1`, `A2`, `A4`, `A5`), também nas fotos do Mac | `variacao_de_cores.gd`: a regra feita para o lobo ("malha com cor por vértice mantém") pega também os bichos de fazenda, cujas malhas têm cor de vértice branca, e apaga a pelagem |
| C2 | **CORRIGIDO em 24/11** (olho assentado na pele; mesmas fotos). Olhos nas laterais e saltados para fora da cabeça (ovelha, cão de guerra, urso, lobo); de frente só aparece um, ou nenhum | foto (`bancada_A2`, `A5`, `A6`, `lobo_bancada`) | `olhos.gd` posiciona pelo osso, não pela superfície da cabeça |
| C3 | **CORRIGIDO em 24/11**. Porco e javali sem olho visível; vaca com olho minúsculo | foto (`bancada_A2`, `A5`) | mesma tabela de olhos |
| C4 | **Olhos CORRIGIDOS em 24/11** (falta a animação). Galinha sem olhos e sem nenhuma animação | foto e medi | modelo feito sem esqueleto |
| C5 | Coelho é o cachorro pug com duas varetas na cabeça e rabo de porco | foto (`bancada_A3`) | falta modelo de coelho |
| C6 | Urso é o pug marrom com orelhas de bola e rabo enrolado | foto (`bancada_A5`) | falta modelo de urso |
| C7 | Cão de guerra é o pug cinza de olho vermelho | foto (`bancada_A6`) | falta modelo de cão de guerra |
| C8 | Cervo é o cavalo pequeno com dois palitos | foto (`bancada_A4`) | falta modelo de cervo |
| C9 | Javali é o porco com espinhos e presas | foto (`bancada_A5`) | falta modelo de javali |
| C10 | **Cor variada em 24/11** (cinza comum; pardo, preto e branco raros). Lobo: corpo comprido (2,16 m), pelagem em duas cores chapadas | foto (`lobo_bancada`) | modelo simples |
| C11 | Todos os bichos são de cor chapada, sem textura de pelo, crina, focinho ou casco pintados | foto | pacote low-poly sem textura |
| C12 | Fagulha, Filhote de Asa e Ignis-Maw são o mesmo dragão em três cores e tamanhos | foto (`bancada_A6`) | um modelo só |

| C13 | **CORRIGIDO em 24/11.** Galinha com a cabeça solta no ar, 5 cm acima do corpo (sem pescoço); cabeça e corpo de cores diferentes | apontado pelo Cristian; foto | modelo sem pescoço; cor sorteada por peça |
| C14 | **CORRIGIDO em 24/11.** Pupila e brilho do lobo e do cão de guerra eram bolas saltadas para fora do olho, apontando para os lados | apontado pelo Cristian; foto ampliada | pupila feita com esfera |
| C15 | **CORRIGIDO em 24/11.** Olho do lobo baixo demais, na linha onde a testa encontra o focinho | apontado pelo Cristian; foto ampliada | posição calibrada baixa; agora fica no meio da face da testa (`olho_do_lobo_na_testa.jpg`) |
| C16 | **CORRIGIDO em 24/11.** Olho do porco e do javali baixo, na bochecha (no javali, junto da base da presa) | revisão ampliada dos 10 bichos (`docs/ajustes/2026-11-24_revisao_ampliada/`) | posição calibrada baixa; agora fica na face, acima do focinho e abaixo das orelhas |

## D. Animais e criaturas: movimento

| # | Defeito | Como vi | Causa |
|---|---|---|---|
| D1 | **CORRIGIDO em 24/11** (`tools/criaturas/consertar_andar_do_lobo.py`). Lobo: andar e correr **não mexem as pernas** (ele desliza como estátua). Só o bote e a morte animam | foto (`movimento_lobo`) | as animações mexem ossos de controle que não puxam a malha |
| D2 | **CORRIGIDO em 24/11** (respiração, cabeça e rabo). Lobo: parado não tem animação nenhuma (amplitude 0,00 m) | medi | animação vazia |
| D3 | **CORRIGIDO em 24/11** (Idle, Walk e Run repetem, ligado em `lobo_visual.tscn`). Lobo: nenhuma animação está marcada para repetir (andar e correr tocam uma vez e param) | medi | `gerar_lobo.py` não marcou o loop |
| D4 | **Lobo CORRIGIDO em 24/11** (corrida tocada 3,2x, velocidade 5,0 m/s; os outros bichos seguem abertos). Pé desliza em quase todos: o corpo anda muito mais rápido que as patas. Lobo ~10x, ovelha ~10x, porco ~13x, coelho ~13x, cão ~7x, javali ~13x, urso ~3x (números aproximados) | medi | velocidade do jogo escolhida a olho; andar copiado da vaca para outros bichos |
| D5 | **Melhorado em 24/11** (montado ele usa a corrida como trote e galope, no ritmo da velocidade; no galope ainda desliza ~1,5x). Cavalo montado galopa a 13 m/s com uma corrida que pede ~3,6 m/s | medi e li | idem |
| D6 | **CORRIGIDO em 24/11** (`tools/criaturas/refazer_andar_emprestado.py`; fotos em `docs/ajustes/2026-11-24_movimentos/`): andavam agachados, de pernas dobradas ou finas e compridas. Ovelha, porco, cão, coelho, javali e urso usam o andar da vaca copiado: passo curto e duro | foto (`movimento_ovelha`, `movimento_urso`) | animação transplantada |
| D7 | Sem animação de levar dano: lobo, javali, urso, cão de guerra, dragões | medi | não existe no modelo |
| D8 | Dragões sem ataque nem morte (o ataque é a corrida; a morte é tombar e afundar) | medi | não existe no modelo |
| D9 | Guardas e chefes andam com o pé deslizando ~3x (andar a 3,6 a 4,6 m/s com passo de 1,3 a 1,6 m/s) | medi | mesma regra do B3 |
| D10 | Torin correndo (Shift) desliza ~1,6x | medi | velocidade 7 m/s contra passo de ~4,4 m/s |
| D11 | Cavalo: andar, correr, pular e morrer animam bem | foto (`movimento_cavalo`) | (não é defeito; serve de referência) |
| D12 | **Aberto.** Depois do ajuste de 24/11 o andar calmo de todos os bichos casa com o passo. Correndo ainda deslizam: coelho ~8x, cão ~4x, cão de guerra ~3,4x, porco ~2,4x, javali ~2,2x, urso ~1,7x, Torin no Shift ~1,6x, Filhote de Asa ~14x | medi (`docs/ajustes/2026-11-24_movimentos/MEDIDAS.md`) | passada curta dos modelos de cão e porco; pede modelo e animação próprios (item 5) |
| D13 | **Não reproduzido (24/11): depois das 2 falhas iniciais, passou 10 vezes seguidas rodando sozinho (6 com depuração: montou, corpo do cavalo sem colisão, nenhum NPC por perto). Causa das 2 falhas desconhecida; fica em observação.** Aberto. `teste_solidos` falhou 2 vezes em 6 em "Montou o cavalo" depois das mudanças de 24/11 e passou nas outras 4; sem as mudanças passou 1 de 1 | teste | não investigada |

### Quem está sem animação (anotado em 24/11 a pedido do Cristian)

| Ser | O que falta |
|---|---|
| Galinha | Tudo: não tem esqueleto. Só bica (a cabeça gira) e tomba de lado ao morrer |
| Lobo | Levar dano |
| Javali | Levar dano |
| Urso | Levar dano |
| Cão de guerra | Levar dano |
| Fagulha | Atacar (morder, fogo), levar dano, morrer, decolar e pousar |
| Filhote de Asa | Atacar (usa a corrida), levar dano, morrer |
| Ignis-Maw | Atacar (usa a corrida), levar dano, morrer (tomba e afunda) |
| Vaca, cavalo, ovelha, porco, cão, cervo, coelho | Levar dano (só piscam em vermelho) e comer/pastar |
| Corvo | Voar (some para longe sem bater asas) |
| Gente e chefes | Só um golpe de espada; ofícios (martelar, cortar lenha, cozinhar) usam o golpe de espada; sem bloqueio, arco ou cavalgada própria |

## E. Gente e chefes

| # | Defeito | Como vi | Causa |
|---|---|---|---|
| E1 | Kaelor e Solon são o mesmo corpo com cor diferente; Gorath é o camponês careca aumentado; Vane no duelo é o Vane comum | foto (`bancada_A8`) | sem modelo próprio de chefe |
| E2 | Mara, Mira, Elda e a cativa são iguais (mesmo capuz verde). Borin, Dorn, Oren e o cativo são iguais | foto (`personagens`) | mesmos corpos base |
| E3 | Machado do Dorn branco, sem textura | foto (`personagens`) | `simpleaxe` sem material |
| E4 | Um golpe de espada só; ofícios (martelar, cortar lenha) usam o golpe de espada | li (`ASSETS.md`) | biblioteca de animação |

## F. Objetos

| # | Defeito | Como vi | Causa |
|---|---|---|---|
| F1 | Drops muito pobres: aço imperial é uma caixa com fita, couro é um disco, lã são duas pedras brancas, presa é um cone, escama é uma placa | foto (`objetos`) | feitos à mão, formas simples |
| F2 | Árvores, pedra, arbusto e toras: forma simples e cor chapada escura | foto (`objetos`, regiões) | geradas por código |

## G. Castelo, cidades e vilas

| # | Defeito | Como vi | Causa |
|---|---|---|---|
| G1 | Castelo Imperial é um pátio murado baixo e vazio: sem torre de menagem, sem prédio alto, torres de canto pequenas | foto (`castelo_portao`, `regiao_castelo_imperial`) | construído como área plana murada |
| G2 | Salão do Trono parece uma caixa de muros **sem teto** | foto aérea (`regiao_castelo_imperial`); falta conferir de perto | a confirmar |
| G3 | Valdoria é um retângulo murado quase vazio: poucas casas soltas, chão de terra nu, sem ruas calçadas nem quarteirões; torres do portão são caixas lisas | foto (`regiao_valdoria`) | idem |
| G4 | Vilas: 5 ou 6 casas iguais soltas no capim, sem rua, sem quintal, sem caminho entre as portas | foto (`vila_campos_altos`) | `povoado.gd` |
| G5 | Chão do mundo é cor lisa, sem textura (capim, terra, pedra, calçamento) | foto | terreno pintado por vértice |
| G6 | Montanhas do horizonte são cones lisos | foto | `mundo.gd::_horizonte` |

## H. Rios, água e mapa

| # | Defeito | Como vi | Causa |
|---|---|---|---|
| H1 | Rio que acaba em lugar errado, sem queda nem foz: não consegui julgar daqui (a água sai esbranquiçada neste renderizador). A varredura diz 0, e ela não mede "tem queda/foz bonita" | foto inconclusiva | precisa de conferência no Mac ou de nova medição por geometria |
| H2 | Junção dos rios em (-308, 87) e (-337, -54) irregular | relatório anterior | aberta |
| H3 | Mapa ainda é corredor norte-sul; falta a referência de mapa aberto | relatório anterior | decisão de desenho |

## I. Ferramentas de prova que enganam

| # | Defeito | Como vi |
|---|---|---|
| I1 | Drone e varredura de precisão dão "0 achados" com todos os defeitos acima presentes | medi |
| I2 | `drone_fotos`: a foto de "entrada" sai de dentro das árvores e a de "borda" sai de dentro da orelha do Torin | foto (`regiao_refugio_do_pinhal`) |
| I3 | Bancada: árvores, pedra e toras saem cortadas (a caixa do item é lida como 1 x 1 x 1 m) | foto (`objetos`) |
| I4 | Bancada fotografava parado, andando e correndo no mesmo instante: não mostrava movimento. Criei `tools/bancada_movimento.gd` (6 quadros por animação e medidas) | foto |
| I5 | As ferramentas do Drone quebravam fora do Mac (formato da imagem). Corrigido nesta etapa | rodei |

## O que ainda NÃO foi olhado

- 176 peças de casa e 30 móveis (são de pacote pronto; fotografados, não revisados um a um).
- 20 das 21 folhas de povoados e 5 das 6 folhas de rios (fotografadas; olhei uma de cada).
- Interiores das casas, interface, mapa (tecla M), clima à noite.
- Filme do ataque do lobo, do javali e do urso contra o Torin, NPC e bicho de fazenda no mundo plano.
- Cor real da água e da névoa (só no Mac).
