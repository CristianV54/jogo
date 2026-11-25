# Plano: o reino de Valdoria pronto (aprovado pelo Cristian em 25/11/2026: "faz, aprovado, monta o plano")

Pedido: entregar o reino inteiro, sem precisar aprovar etapa por etapa: castelo, textura, muralhas, NPCs, comerciantes,
cavalos, casas, rei, soldados, comércio, ruas e local de treino. "Igual um castelo."

Cada bloco só conta como feito com: teste do mundo passando, foto de perto do que mudou e defeito visto corrigido.

| # | Bloco | Critério de pronto | Estado |
|---|---|---|---|
| 1 | Muralha grande com 4 portões (sul, oeste, leste e norte), Rua do Anel, 17 bairros, mercados e feiras | teste conta 3 portões; fotos | feito (reino_v1) |
| 2 | Adensar: casas de rua, Rua do Meio, chão plano e de cidade, nomes dos bairros pela posição | 100+ casas de rua; fotos da rua e do portão oeste | feito: 393 casas de rua, Rua do Meio, 20 travessas (reino_v2) |
| 3 | Textura de pedra nas muralhas e torres (do reino, de Valdoria e do Castelo) | foto de perto mostra blocos de pedra, não cor chapada | feito: cantaria pintada (`scripts/mundo/pedra.gd`), foto 6g |
| 4 | Castelo com cara de castelo: quatro torres altas com telhado e bandeira em volta do Salão do Trono | o castelo aparece por cima da muralha, visto do portão sul | feito: torres de 30 e 36 m, fotos 6d e 6i |
| 5 | Soldados: quartel com campo de treino (bonecos, alvos, soldados treinando, capitão) e sentinelas nos 3 portões | fotos; soldados não atacam o Torin | feito: teste confere 6 bonecos, 4 soldados e 8 sentinelas; fotos 6d, 6f, 6f2 |
| 6 | Cavalos: Estábulos do Reino (cavalos que dá para montar, feno, bebedouro, cavalariço) | foto; montar um cavalo no teste | feito: teste confere 4 cavalos montáveis; foto 6e |
| 7 | Comércio de verdade: cada mercado e feira troca itens (couro, lã, presa, carne, maçã) | teste faz uma troca e confere o inventário | feito: teste troca 1 couro por 3 carnes |
| 8 | Auditoria de perto do reino: cada bairro, mercado e portão fotografado; casa enterrada, flutuando ou sobre rua corrigida | relatório em docs/auditoria/ com zero defeito aberto | feito: `docs/auditoria/REINO_2026-11-25.md`, 509 casas e 122 seres, 0 defeito (a 1ª rodada achou 3, corrigidos) |
| 9 | Registro: ASSETS.md, MAPA-DO-TRABALHO.md, CLAUDE.md (estado atual) e suíte de testes revista para a ilha | documentos atualizados | parcial: ASSETS, MAPA-DO-TRABALHO e CLAUDE.md atualizados; a suíte antiga ainda não foi revista para a ilha |

## Fica de fora (precisa de decisão do Cristian, não de aprovação de etapa)
- **O rei.** Hoje quem manda no castelo é o Imperador Solon, chefe final da história antiga, que só aparece na luta.
  Um rei que recebe o Torin (amigo? vilão? outro nome?) é decisão de história, que o Cristian disse que vai pensar.
- **Castelo no alto de um morro.** A plataforma do castelo tem 3 m. Erguer mexe na rampa, no viaduto e nos testes do
  capítulo final; entra junto com a história nova.
- **Muralha antiga de Valdoria no miolo.** As missões do capítulo final dependem dela.
- **Nomes.** Todos os bairros, mercados e povoados novos têm nomes provisórios.
