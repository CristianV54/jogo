# Peça 2: a RUA de Valdoria

Kit: `scripts/mundo/pecas_da_rua.gd`. Bancada: `tools/bancada_construcao.gd -- rua`.

## Critério de pronto

1. A rua não é um chão só: tem CALÇADA de lajes junto às casas (com meio-fio claro) e SARJETA escura no meio.
2. Toda porta tem um degrau de pedra.
3. Há luz na rua: lampião de parede nas ruas de casas, lampião de poste nas avenidas; a lanterna tem armação, vidro aceso e chapéu (não é um cubo amarelo).
4. Há sinal de vida junto às fachadas: placa de loja pendurada, barris e caixotes, banco, vasos de flor.
5. Nada disso tranca a passagem: o meio da rua fica livre (teste com raio ao longo do eixo da rua).
6. Tamanho certo contra o Torin: lanterna acima da cabeça, banco na altura do joelho, barril na cintura.
7. No mundo: teste_mundo e auditoria_reino passam; fotos de uma rua de casas e da avenida.

## Resultado (25/11/2026)

- Bancada `-- rua`: 9 fotos em `docs/construcoes/rua/`, 2 testes passando (meio da rua livre; banco e carga com colisão).
- No mundo: 197 lampiões de parede, 127 placas; `teste_mundo` TUDO PASSOU e `auditoria_reino` 0 defeito (rodados com a rua e a casa novas, antes da feira). Fotos `20_` e `21_`.
- Casa (em `casario_do_reino.gd`, sem bancada própria ainda): porta em relevo, janelas com peitoril e venezianas, pontas de viga, cumeeira, água-furtada, chapéu de chaminé.
- Feira (`-- feira`): barraca e carroça, fotos em `docs/construcoes/feira/`. Ligadas ao mercado e às avenidas; AINDA NÃO conferidas dentro do mundo.

## Pontos fracos anotados (atacar depois, pedido do usuário)

- Braseiro do portão é um bloco laranja; topo da muralha faz degrau em ladeira.
- Só a fachada da rua tem relevo; laterais e fundos das casas só pintados; casas de esquina mostram a lateral para a avenida.
- Sem calçada nas esquinas e travessas; sem varal entre casas.
- A casa não tem bancada própria (foi conferida só dentro do mundo).
