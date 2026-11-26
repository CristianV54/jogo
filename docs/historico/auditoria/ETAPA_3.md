STATUS: APROVADA (com 2 pendências VISUAIS não bloqueadoras)
COMMIT: ver `git log` (Etapa 3)
ALTERAÇÕES:
- Fita de água nunca mais larga que o leito escavado (antes 17 m de largura sobre um leito de 14: a água pendia sobre o chão que descia).
- Perfil de margem novo: fundo do rio, barranca íngreme de 1,4 m que sobe 0,4 m acima da água, e margem que nunca fica abaixo da água, nem no lado em que o terreno desce.
- Terreno do mundo com malha de 4 m (era 8 m): um rio de 7 m de largura cabia em 2 células e a margem virava serrilhado. 60 fps mantidos.
- Pontas livres de rio afinam e somem em 14 m (sem corte reto); pontas que encontram outro rio, a borda de uma região ou o mar ficam inteiras.
- O Rio Cinzento Fim começava 26 m fora do Acampamento, sem tocar em nenhum rio: ligado à borda da região (dado corrigido).
- Água esmaece nas bordas da fita.
- Pontas das pontes agora ficam já fora da margem do rio, no chão sem mexida.
- Rampa dos platôs de povoado mais larga (metade do raio): a malha de 4 m transformou 2,8 m de desnível em 10 m num degrau na estrada dos Campos Altos.
- Auditoria do Drone: a verificação de água agora testa a borda da fita e 1,5 m além (antes contava o fundo do leito como erro).
TESTES EXECUTADOS:
- compilação: PASS
- varredura do Drone: PASS (0 bloqueadores, 0 críticos, 2 VISUAL)
- testes de cena: PASS (rio, mundo, sono, medo, cadeia, queda, marcos 4 a 7)
- colisões/alcance: PASS (cercos, buracos, contínua)
- auditoria de lógica: PASS (1 aviso falso conhecido: bigorna da forja)
- desempenho: PASS (60 fps mínimos nos 7 pontos medidos)
FALHAS ENCONTRADAS:
- R-01 VISUAL água em faixa pendurada sobre chão mais baixo x10 → 2 (confluências em (-308.7, 87.0) e (-337.4, -54.2): 1,1 m e 0,8 m). Aberto, não bloqueador.
- R-02 CRITICO degrau de 0,76 m na estrada dos Campos Altos em (330, 4): rampa curta do platô do povoado. Corrigido.
- R-03 VISUAL rio sem fim (Cinzento Fim, (716,-337)): corrigido. Rio do Pomar nasce do nada em (-371,-420): agora afina como nascente.
REGRESSÕES: 1 achada e corrigida durante a etapa (R-02).
PENDÊNCIAS NÃO BLOQUEADORAS:
- As duas confluências acima mostram manchas de água soltas nas fotos (tools/capturas/pontos_confluencias.png).
- As serras (cristas) cruzam alguns rios; a água passa por baixo das rochas.
- Capturas: tools/capturas/rios_etapa3b_*.png (7 folhas), pontos_margens.png, pontos_costa_e_rio.png.
PRÓXIMA ETAPA PERMITIDA: Etapa 4 (terreno, grama, árvores, pedras e biomas).
