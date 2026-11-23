STATUS: APROVADA COM RESSALVAS (ver pendências)
COMMIT: ver `git log` (Etapa 10)
ALTERAÇÕES: nenhuma de jogo. Campanha completa verificada por testes e documentação final (`docs/LEIS-DO-JOGO.md`, `CLAUDE.md`).
TESTES EXECUTADOS (campanha do começo ao epílogo):
- teste_cadeia: as 20 missões C1-M1 a C5-M4 começam sozinhas e concluem pelos objetivos reais (41 verificações PASS).
- teste_marco3 a teste_marco7: cada capítulo jogado no mundo real, com chefes, barreiras, Fagulha, ferreira, mercadores e o epílogo que termina o jogo (marco 7: "C5-M4 concluída e o epílogo termina o jogo"): PASS.
- teste_missoes_dados, teste_fagulha, teste_simulacao, teste_medo, teste_sono, teste_cartaz, teste_rio, teste_queda, teste_rotinas, teste_mundo: PASS.
- Varredura final do Drone: 0 bloqueadores, 0 críticos, 2 VISUAL (água).
- Desempenho: 60 fps mínimos em 7 pontos.
O QUE NÃO FOI FEITO NESTA CAMPANHA:
- Nenhuma partida jogada por uma pessoa na janela do início ao fim. A campanha foi percorrida por testes que movem o Torin e disparam os eventos; sensação de jogo, ritmo e dificuldade não foram medidos.
- Tempo de campanha, "missões presas" e "objetos não encontrados" foram conferidos por teste de dados (cada objetivo tem fonte), não por cronômetro numa partida.
PENDÊNCIAS NÃO BLOQUEADORAS (somadas das etapas):
- 2 VISUAL de água em confluências do Rio Cinzento ((-308,87) e (-337,-54)).
- Lobo não ataca NPC nem bicho doméstico; persegue sem navegação.
- Cavalo sem olhos e com modelo simples; lobo e cavalo precisam de modelo/animação melhor.
- Povoados de ambientação usam os mesmos modelos de casa (só muda a paleta); sem carpintaria/praça/torres próprias.
- Fases do Fagulha só mudam escala e cor; faltam animação e partículas de transformação.
- Recompensas ainda em maioria carne/maçã/couro; cenas-chave do duelo do Vane (escolha) e do final do Solon seguem como no texto antigo.
- Mundo continua um corredor norte-sul (mapa vertical); redesenhar para mundo aberto de verdade é decisão de design.
- teste_solidos e teste_montaria_dano já falhavam no baseline: reescrever para o mundo contínuo.
PRÓXIMA ETAPA PERMITIDA: nenhuma pendente do plano. Itens acima dependem de decisão do Cristian.
