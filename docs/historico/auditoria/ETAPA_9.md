STATUS: APROVADA (visual simples, ver pendências)
COMMIT: ver `git log` (Etapa 9)
ALTERAÇÕES:
- Fagulha em 3 fases (`scripts/criaturas/fagulha.gd`), trocadas pelas missões C1-M4 (resgate), C2-M3 (queda do Primeiro Obelisco) e C3-M4 (Kaelor/Ferrogris), cada uma com cena de transformação em diálogo:
  - Fase 1 ferido: tamanho 0,7, escamas cinzentas (marcas do Ferro Negro), segue no chão, F não faz voar (aviso na tela), morde de leve (dano 4, alcance 3 m, a cada 2,2 s), não pode ser montado.
  - Fase 2 jovem: tamanho 0,85, mais claro, F faz planar a 3 m por 6 s, depois pousa e descansa 4 s, morde mais forte (dano 9, 4,5 m), ainda não pode ser montado.
  - Fase 3 alado: tamanho 1,0, cor plena, voo livre a 8 m, pode ser montado, cospe fogo (dano 16, 9 m, fogo visível, a cada 4 s).
- Só defende o Torin: ataca quem está perseguindo ou atacando a menos de alcance+6 m dele.
TESTES EXECUTADOS:
- teste_fagulha (NOVO, jogo real): 12 verificações PASS (fase, escala, cor, voo, planar e pouso, descanso, montaria, mordida, fogo, troca por missão).
- marco3 atualizado (fase 1 não pode ser montada); marco4 ensinado a fechar a cena da fase 2; testes de montaria passam pela fase 3.
- Fotos das 3 fases em 3 ambientes (campo aberto, mata, perto de casa): tools/capturas/fagulha_fases.png.
- Varredura do Drone: 0 bloqueadores, 0 críticos.
FALHAS ENCONTRADAS: R-06 o marco 4 falhou: a cena da fase 2 abria no meio da luta com o Gorath e o E do teste avançava o diálogo em vez de empurrar o vagonete (teste corrigido; no jogo o jogador fecha o diálogo).
PENDÊNCIAS NÃO BLOQUEADORAS:
- Visual das fases é só escala e cor; faltam animações e partículas próprias de transformação, e o modelo de asas não muda.
- O sopro de fogo é o Fogo existente no alvo (sem cone nem projétil).
- Fase 2 não passa por estrutura fechada nem túnel (planar é só no aberto).
- teste_solidos (4 falhas) e teste_montaria_dano (NPC protestou) JÁ FALHAVAM no baseline (verificado): são testes antigos do mundo pré-contínuo, não regressões. O primeiro conferir se o Torin atravessa NPC/cerca; precisa ser reescrito para o mundo contínuo.
PRÓXIMA ETAPA PERMITIDA: Etapa 10 (campanha completa).
