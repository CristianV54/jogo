# Peça: a MONTANHA DOS DRAGÕES (pedido do Cristian)

- Chão: `MundoDados.montanha()` (cone de 240 m ao norte de Valdoria, centro em (-200, -1500), raio de 380 m, trilha em espiral de volta e meia do pé, a oeste, até o platô do ninho). A Trilha dos Dragões liga a Estrada da Serra ao pé.
- Objetos: `scripts/mundo/montanha_dos_dragoes.gd` com peças de `pecas_do_ninho.gd` (roda de pedras, leito de galhos, cinco ovos, brasa, ossada, marcos da trilha, arcos de ossos).
- Dragões: `scripts/criaturas/dragao_selvagem.gd` (o modelo rigado da Fagulha em outras cores e tamanhos): 5 voando em roda do pico, 3 pousados na borda do platô e 1 DOMÁVEL no ninho.
- Domar: `scripts/criaturas/domar_dragao.gd`. Com E, perto do dragão cinza do ninho; custa 3 carnes (de caça ou do mercado). Domado, chama-se **Cinza** (nome criado por mim, a aprovar) e vira montaria que voa (E monta; Espaço sobe; C desce).

## Critério de pronto

1. Sobe-se a pé do pé ao ninho pela trilha, sem degrau que trave (teste em `tools/teste_mundo.gd`).
2. 200 m ou mais de subida.
3. 8 ou mais dragões, 5 voando.
4. O dragão do ninho só se doma com 3 carnes e vira montaria que voa.
5. Vê-se a montanha de longe; fotos de longe, da trilha e do ninho.

## Resultado (26/11/2026)

- `teste_mundo`: os itens 1 a 4 passam (sobe 245 m; 9 dragões, 5 voando; domar testado sem carne e com carne).
- Fotos em `docs/construcoes/montanha/`. Na primeira rodada a montanha não se via de longe (névoa do pinhal) e as pedras do ninho saíam com desenho de muro; foram corrigidos o ar em volta dela (`Mundo.estilo_em`) e a rocha do ninho.

## Pontos fracos anotados

- Os dragões selvagens só voam em círculo ou ficam parados: não atacam nem reagem ao Torin.
- Cinza, depois de domado, fica onde o Torin desmonta (não segue como a Fagulha).
- A encosta é lisa de perto (cor por faixas, sem pedras soltas nem vegetação de altitude).
- O mapa da tecla M ainda não desenha a montanha.
