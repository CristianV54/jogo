# Item 5: candidatos a modelo novo (avaliação de 24/11/2026)

Baixados com o OK do Cristian para uma pasta fora do repositório (`/opt/baixados/` no servidor) e fotografados por
`tools/bancada_candidatos.gd`. **Nenhum entrou no jogo.** Fotos em `docs/inventario/candidatos/`.
Nas fotos os modelos de arquivo `.blend` antigo saem brancos: a textura existe no arquivo mas não veio na conversão; é ajuste meu, não defeito do modelo.

| Candidato | Origem e licença | Esqueleto e animações | Avaliação |
|---|---|---|---|
| Galinha (Snabisch, OpenGameArt `chicken-animated`) | CC0 (autor Čestmír Dammer) | 40 ossos; andar, bicar (3), comer, parada (3), morrer | **Boa.** Galinha de verdade, com as animações que faltam. Precisa: tirar uma malha extra que vem junto, religar a textura, acertar o tamanho |
| Coelho (Snabisch, OpenGameArt `rabbit-0`) | CC0 | 37 ossos; correr, pular, sentado, de guarda, morrer (2) | **Boa.** Coelho de quatro patas de verdade. Não tem "andar" (coelho pula); precisa religar a textura e acertar o tamanho |
| Urso branco (OpenGameArt `white-bear-low-poly`) | CC0 (Phelippeau Rudy) | **Sem esqueleto, sem animação**; 929 triângulos | Forma boa de urso de quatro patas. Só serve se eu puser nele o esqueleto da vaca e refizer o andar com as ferramentas de 24/11 |
| Urso e coelho (Jugger, itch.io) | Licença própria: uso comercial liberado, **crédito obrigatório e proibido redistribuir os arquivos** | 16 a 17 ossos; parado, andar, correr | **Não serve.** São bonecos de pé, estilo pelúcia; e a licença não deixa guardar o arquivo no repositório |
| Javali e cabra (Gobkit Pack B, itch.io) | CC0 | 16 ossos; uma trilha só com parado, atacar, morrer e andar | **Não serve.** São bichos-bola de desenho, não combinam com o resto |
| Coelho "bunny" e "Lucky Bunny" (OpenGameArt) | CC0 | Um sem esqueleto; o outro é boneco de pé | Não servem |
| Cavaleiro (Quaternius, LowPoly Animated Knight) | CC0 | 42 ossos; 12 animações com espada | **Não serve para chefe.** É um boneco antigo, de cabeça grande e 956 triângulos, bem mais simples que os corpos que o jogo já usa |
| Ultimate Animated Animal Pack (Quaternius) | CC0 | 12 animais: Alpaca, Bull, Cow, Deer, Donkey, Fox, Horse, Horse_White, Husky, ShibaInu, Stag, Wolf; mais de 12 animações cada | **Não consegui baixar:** a pasta do Google Drive do autor estourou a cota de downloads ("tente de novo em até 24 horas"). É o que resolveria cervo, cão de guerra e lobo |

## Aprovados e já no jogo (24/11)

Galinha e coelho do Snabisch: preparados por `tools/criaturas/preparar_galinha_e_coelho.py`, bancada em `docs/ajustes/2026-11-24_galinha_e_coelho/`, registro em `assets/ASSETS.md`.

## O que continua sem solução

- **Urso com animação** em CC0: não achei. Caminhos: pôr esqueleto no urso branco (trabalho meu) ou comprar o kit pago de 10 dólares.
- **Javali:** nenhum candidato serve. Fica o porco com presas, com o andar já refeito.
- **Chefes:** nenhum candidato serve. O caminho é o pacote de trajes que o jogo já usa (Modular Character Outfits - Fantasy, 280 MB, ainda não baixado aqui).
