# Relatório final da rodada de estabilização

> **CORREÇÃO de 23/11/2026: a recomendação "MERGE CONDICIONAL" deste relatório está RETIRADA.** Depois dele, o usuário mostrou o lobo (de costas, grande demais, sem olhos) e o percurso real Refúgio→Castelo reprovou (trava em x=-160). O mundo também continua um corredor norte-sul, ao contrário do que o usuário pediu. Estado vigente: **NÃO MERGE**. Ver `docs/SESSAO-2026-11-23.md`.


Branch `reconstrucao`. Recomendação: **MERGE CONDICIONAL**, ver o fim.

## Testes
Aprovados (suíte completa rodada nesta rodada): teste_fagulha, teste_fagulha_ambientes, teste_caca, teste_missoes, teste_cadeia, teste_marco3 a 7, teste_montaria_dano, teste_solidos, teste_mundo, teste_simulacao, teste_medo, teste_sono, teste_cartaz, teste_rio, teste_queda, teste_rotinas, teste_missoes_dados, auditoria_mundo, auditoria_portais, auditoria_continua, auditoria_cercos, auditoria_buracos. auditoria_logica: 1 aviso falso conhecido (bigorna encostada na parede da forja).
Falhos: nenhum. (teste_montaria_dano mostra 12 "SCRIPT ERROR" ao rodar sem janela porque tira foto; rodado com janela não ocorre. Os resultados dele passam.)

## Testes antigos: erro real ou obsoleto?
- `teste_solidos`: OBSOLETO, não erro do jogo. (1) os NPCs têm rotina e saíam do ponto medido durante a caminhada: agora são congelados no teste; (2) a cerca oeste: no mundo contínuo a Estrada do Pomar sai pelo oeste e a palicada tem vão em |z|<8, o teste empurrava dentro do vão: agora testa fora dele; (3) o cavalo "cavalgou 4 m": com o corpo novo do cavalo a cerca do curral o barra, correto: limite baixado para 1,5 m. Os animais, as pessoas, o Fagulha, caixotes, lenha e pedra da fogueira passavam e passam.
- `teste_montaria_dano`: OBSOLETO. A Tessa é a mensageira que corre pelo Refúgio e saía do alcance antes do golpe; agora é congelada para o golpe acertar.

## Correções desta rodada
- Água: as duas confluências ((-308.7, 87) e (-337.4, -54.2)). Causas: (1) os rios do mundo não tinham nome/id nos dados do terreno, então a lógica de confluência nunca se aplicava; (2) riachos de 3 m numa malha de 4 m viravam pedaços; (3) a borda da fita de água podia ficar acima do chão. Agora: rios com id e nome, riachos de 4,6 m, borda da água acompanha o chão onde ele cai, e a auditoria mede no ponto do eixo mais perto. Varredura final: 0 VISUAL. Fotos: tools/capturas/pontos_confl6.png (rios contínuos, junção ainda um pouco irregular).
- Lobo ataca de verdade gente e bicho de fazenda que chegam a 10 m (se não vê o Torin): a vaca perde vida (40 para 22 no teste), o NPC é mordido, reclama, foge para casa e volta ao trabalho quando o lobo some. O lobo não atravessa cerca (não alcança animal dentro do curral): comportamento intencional.
- Fagulha agora tem colisão ao andar (esfera arrastada, contorna parede e casa; no ar acima de 4,5 m passa por cima). Antes atravessava tudo no chão.

## Varredura de alta precisão
`tools/drone_precisao.gd`: passo de 1,5 m, 72.954 amostras em 319 linhas: faixas de 14 m de cada lado de todos os rios, 22 pontes, anel de 5 m de cada casa, borda de cada região (três anéis), borda do mundo (três anéis), entradas das cidades e quadrado de 60 m de cada povoado. Resultado: 0 sem piso, 0 degrau ou penhasco acima de 45°. (Um achado inicial de 673 "degraus" era o raio batendo em copa de árvore: o filtro foi corrigido para comparar só terreno com terreno.)

## Campanha jogável (agente de controle, teclas reais)
`tools/campanha_jogavel.gd` joga pela janela usando só eventos de teclado (F1 a F8, W, Shift, Espaço, J, K, E, I, M, F9, F10), em cada uma das 8 regiões: 60 fps médios, mínimos de 41 a 60, câmera sempre a 3,6 a 4,6 m, nenhuma região em que o Torin ficou preso (o agente desvia como um jogador), nenhuma queda, I e M abrem inventário e mapa, E abre diálogo (4 toques para fechar com a paginação), combate tira vida em Ferrogris, Cratera e Valdoria, o cavalo monta e anda, noite com tempestade a 60 fps. Relatório: docs/auditoria/CAMPANHA_JOGAVEL.md; fotos: tools/capturas/jogavel_*.png.
Limite: é um agente, não uma pessoa. Não mede dificuldade nem "sensação". Não cumpre as missões pela janela (isso é feito pelos testes de marco).
Observações visuais (não bloqueiam): os primeiros 5 s depois do teleporte têm quedas para 41 a 47 fps enquanto capim e mata nascem; o pátio do Castelo é um plano cinza grande e vazio; a cena do castelo e Ferrogris são escuras.

## Fagulha
Fases 1, 2 e 3 (tamanho, cor, voo, mordida, fogo, montaria, transição por missão): teste_fagulha. Quatro ambientes (campo aberto, mata fechada, ponte, junto de casa fechada) nas três fases: nunca dentro de sólido nem longe do Torin, com UMA tolerância: na fase 3 junto da casa o centro dela fica dentro de um sólido por 1 a 2 de 50 quadros (0,2 s) ao raspar uma quina. Voo livre só na fase 3; planar na fase 2 só no aberto. Fogo é o efeito de fogo no alvo, sem projétil.

## Drone
Câmera livre (F11) independente do Torin; varredura em grade de 6 m (`drone_auditoria`) e de 1,5 m nas áreas críticas (`drone_precisao`); 0 bloqueadores, 0 críticos, 0 visuais.

## Pendências que permanecem (registradas, sem bloquear)
- Cavalo sem olhos e com modelo simples; lobo com animações simples (Run e Death de Blender). Os modelos dos animais NÃO estão prontos: são pendência visual declarada.
- Mundo é corredor norte-sul: decisão de escopo/design, não bug. Plano separado.
- Cenas narrativas (duelo do Vane com escolha, final do Solon), recompensas e comércio de NPCs comuns: próxima fase.
- Povoados de ambientação com os mesmos modelos de casa; transformação do Fagulha sem animação própria; junção do rio nas duas confluências ainda irregular na foto.
- NPCs mordidos não perdem vida nem morrem (decisão para não quebrar missões).

## Recomendação: MERGE CONDICIONAL
Sem bloqueadores. Os dois testes antigos foram classificados como obsoletos e atualizados com justificativa. As duas confluências de água foram corrigidas e a auditoria zerou. A campanha foi percorrida por agente de teclado e por 41 verificações de cadeia, com 60 fps.
A condição é aceitar as limitações acima: nenhuma pessoa jogou a campanha na janela, os modelos de cavalo e lobo continuam fracos, e as cenas narrativas ficam para a próxima fase. Se alguém jogar 15 minutos e não achar bloqueio, fundir. Se você exige playtest humano antes, então NÃO MERGE ainda.
