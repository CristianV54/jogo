STATUS: APROVADA
COMMIT: ver `git log` (Etapa 8)
ALTERAÇÕES:
- Novo `tools/teste_missoes_dados.gd`: valida as 20 missões contra o mundo construído: cadeia C1-M1 a C5-M4 com pré-requisito e início automático; para cada objetivo, se o que o cumpre existe no mundo (NPC, objeto interagível, zona, inimigo, fonte de item, fornalhas, trocas dos mercadores, raízes); recompensas com itens válidos; cada barreira (bosque, ruptura, ferrogris, valdoria, castelo) só abre com a missão ou o chefe certo.
- Nenhuma mudança de jogo foi necessária: as missões já funcionavam; o teste novo é a prova de dados que faltava.
TESTES EXECUTADOS:
- teste_missoes_dados: PASS (todos os objetivos têm fonte no mundo; barreiras ligadas às missões certas)
- teste_missoes, teste_cadeia, marcos 3 a 7: PASS (fluxo real de cada capítulo, sem proximidade)
- auditoria_cercos: PASS (barreiras fechadas selam; abertas ligam as 8 regiões e os 21 povoados)
FALHAS ENCONTRADAS: nenhuma no jogo (3 achados do teste novo eram alvos dinâmicos: cavalo perdido nasce com a C1-M3, fornalhas/trocas/raízes têm classe própria; o teste foi ensinado a contá-los).
PENDÊNCIAS NÃO BLOQUEADORAS:
- Recompensas ainda são em maioria carne, maçã e couro (revisão de recompensas está na etapa 5 do plano de história).
- O "confronto do Vane" (C3-M1) e a fala dos chefes só são exercitados pelos testes de marco, não por teste de diálogo.
PRÓXIMA ETAPA PERMITIDA: Etapa 9 (três fases do Fagulha).
