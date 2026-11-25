# Plano: o reino de Valdoria pronto

Aprovado pelo Cristian em 25/11/2026 ("faz, aprovado, monta o plano") e ampliado no mesmo dia com as decisões dele:
**rei como NPC; tirar a história e as missões; castelo lá em cima e o povo morando embaixo; muralha normal de castelo
(sem a muralha interna da cidade velha); os nomes eu posso criar.** Trabalho contínuo, sem aprovação etapa por etapa.

Cada bloco só conta como feito com: teste do mundo passando, auditoria do reino sem defeito e foto de perto do que mudou.

| # | Bloco | Critério de pronto | Estado |
|---|---|---|---|
| 1 | Muralha grande com 4 portões, Rua do Anel, bairros, mercados e feiras | teste conta 4 portões | feito |
| 2 | Casas de rua, Rua do Meio, 20 travessas, calçada de pedra, chão plano | fotos de rua | feito |
| 3 | Textura de pedra nas muralhas e torres | foto de perto com blocos | feito |
| 4 | Torres altas no castelo | castelo aparece por cima das casas | feito |
| 5 | Quartel com campo de treino e sentinelas nos portões | teste | feito |
| 6 | Estábulos com cavalos montáveis | teste | feito |
| 7 | Trocas nos mercados | teste troca couro por carne | feito |
| 8 | Auditoria de perto (`tools/auditoria_reino.gd`) | 0 defeito | feito na 1ª versão; repetir a cada bloco |
| 10 | **História e missões desligadas** (`Jogo.historia = false`): sem lista de missão, Fagulha companheira e montável desde o começo, sem duelo nem chefe no castelo, sem guardas hostis na cidade | teste: nenhuma missão ativa, nenhum inimigo dentro da muralha | escrito, a conferir |
| 11 | **Castelo no alto**: a região do castelo sobe 24 m, o chão do mundo vira morro em volta, o viaduto sobe da cidade até a porta | teste: 24 m no castelo, ~0 m na Rua do Anel; foto de baixo | escrito, a conferir |
| 12 | **O rei**: Rei Aldren no Salão do Trono, com o Conselheiro Meren, 8 guardas reais e sentinelas no portão do castelo | teste acha o NPC; foto | escrito, a conferir |
| 13 | **Muralha normal**: sai a muralha interna da cidade velha; fica a do reino e a do castelo | foto da entrada da cidade velha | escrito, a conferir |
| 14 | **Miolo dos quarteirões**: casas de fundo, hortas, quintais com árvores e poços entre as ruas | teste: 600+ casas, 100+ hortas; foto | escrito, a conferir |
| 15 | Vida nas ruas: gente andando de um bairro ao outro, carroças, cavalos amarrados, lampiões, placas de rua | fotos | a fazer |
| 16 | Miolo do castelo: telhado e paredes do Salão, cozinha, pátio de armas, jardim do rei | fotos | a fazer |
| 17 | Desempenho: medir quadros por segundo no reino e o tempo de carga com cache; guardar casas e floresta em cache | números | a fazer |
| 18 | Suíte antiga revista para a ilha (o que ainda vale, o que sai) e registro final nos documentos | lista em docs | a fazer |

## Nomes criados (com autorização do Cristian; trocar é só avisar)
Rei Aldren, Conselheiro Meren, Castelo de Valdoria, Rua do Anel, Rua do Meio, Estrada do Norte, Estrada da Costa;
bairros do Nascente, dos Tecelões, dos Oleiros, do Moinho, do Poente, da Muralha, dos Ferreiros, da Torre, do Sino, das
Flores, da Fonte, do Mercado Velho, da Ponte Velha, do Castelo; Quartel da Guarda, Estábulos do Reino, Mercado do Poente,
Mercado do Nascente, feiras do Portão Sul, do Poente e do Nascente; e os 51 povoados sorteados (lista em
`tools/mundo/encher_o_mundo.py`).

## Sobre a história
O código das missões e dos chefes continua no projeto, desligado pela chave `Jogo.historia`. Os testes antigos da
campanha ligam a chave para continuarem valendo. Apagar esse código de vez fica para quando a história nova existir.

## Virada de 25/11 (tarde): a planta do Reino de Aethelgard
O Cristian mandou uma pintura de referência e depois o pacote do reino que ele tinha feito em blocos. Valdoria foi refeita
com a mesma composição e as mesmas proporções (ver o cabeçalho de `scripts/mundo/mundo_dados.gd`). Os blocos 1 a 14 acima
descrevem a versão anterior (círculo com castelo ao norte, depois círculo com castelo no centro) e ficam como histórico.

| Feito e conferido (teste do mundo passa, auditoria com 0 defeito, fotos em `reino_v4/`) |
|---|
| Penhasco de 64 m com rampa subível a pé e mureta |
| Cidadela: 28 torres (topo a 164 m), palácio, torreão, capela, quartel, cavalariça, poço, árvores |
| Salão do Trono oco com o Rei Aldren, o Conselheiro Meren e a guarda real; sentinelas no portão |
| Muralha oval irregular com 3 portões, 33 torres redondas, guaritas |
| 612 casas em 87 quarteirões: térreo, sobrado em enxaimel, vigas, telhado, chaminé |
| Chão calçado de pedra; fonte, lampiões, barris, carroças; jardins ao pé do penhasco |
| Praça do mercado, feiras nos portões, quartel com campo de treino, estábulos, catedral, 8 lavouras |

| Catedral gótica: nave, naves laterais com contrafortes, vitrais que brilham, torres gêmeas com rosácea, torre do cruzeiro |
| 1.116 janelas acesas, 26 forjas com a fornalha acesa, 19 lampiões (avenidas sul, oeste e leste) |
| 27 pessoas circulando pelas ruas, 545 rochas no paredão do penhasco |
| Pular do penhasco não devolve mais o Torin ao alto (a rede de segurança só age abaixo do chão) |

**Entrega de 25/11/2026:** teste do mundo passa inteiro, auditoria do reino com 0 defeito (641 casas, 110 pessoas e bichos),
23 fotos em `docs/mapa-novo/reino_v4/`.

Em aberto: desempenho no Mac (não medido), tempo de carga, tubarão ainda provisório, nos sobrados do casario não se
entra, suíte antiga não revista para a ilha (os testes que passavam por Valdoria e pelo Castelo antigos deixaram de valer).
