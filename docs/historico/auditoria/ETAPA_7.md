STATUS: APROVADA (pendências listadas)
COMMIT: ver `git log` (Etapa 7)
ALTERAÇÕES:
- Cavalo montado ganhou corpo físico (caixa do tamanho do bicho presa ao Torin enquanto monta): antes só a cápsula fina do Torin colidia e o cavalo atravessava parede e pedra. Teste de simulação prova: sem a caixa o centro do cavalo chegava a 0,4 m da parede; com ela para a 1,4 m.
- Inimigos: o golpe só acerta quem está à frente (cone de ~70°) e sem parede entre os dois (arqueiros: viram para o alvo e a flecha passa por cima do muro). Giram mais rápido ao atacar (14/s, antes 6/s).
- Porta de casa: barreira invisível só para monstros (camada 16) no vão, sempre fechada para eles; o jogador e a câmera não a enxergam.
- NPCs: lobo/javali/urso/cão de guerra parado a menos de 16 m também assusta (antes só perseguindo); a fuga prefere a casa do lado oposto ao monstro; a reserva de cama feita na fuga é solta quando passa o susto (as camas ficavam presas).
- NPCs andam pela porta até a cama (quando o jogador está a menos de 40 m), em vez de aparecerem deitados.
- Chuva: gotas finas e curtas, que somem coladas na câmera (antes viravam barras brancas enormes na ponte).
TESTES EXECUTADOS:
- teste_simulacao (NOVO: cavalo contra parede, lobo contra porta, golpe de frente/de costas/através de parede): PASS, e o teste do cavalo FALHA sem a correção (verificado).
- teste_medo (estendido: lobo parado, camas soltas), teste_sono (estendido: espera a caminhada), teste_rotinas, marcos 3 a 7, cadeia, mundo, cercos, buracos, contínua, queda: PASS.
- varredura do Drone: 0 bloqueadores, 0 críticos, 2 VISUAL (água, da Etapa 3).
- teste_montaria_dano: 1 falha (NPC protestou), JÁ EXISTIA no baseline (verificado no commit baseline-reconstrucao): não é regressão.
FALHAS ENCONTRADAS: R-04 CRITICO arqueiros pararam de atirar (a linha de visão batia no chão/torre): corrigido. R-05 teste do sono media durante a caminhada: teste corrigido.
PENDÊNCIAS NÃO BLOQUEADORAS:
- O lobo nunca ataca NPC nem bicho doméstico (só o Torin): o medo dos NPCs continua sem perigo real.
- O lobo persegue em linha reta (sem navegação); contorna só pelo deslize de colisão.
- Cavalo sem olhos e modelo simples (pede modelo novo).
- teste_montaria_dano: falha do baseline (balão de protesto do NPC).
PRÓXIMA ETAPA PERMITIDA: Etapa 8 (missões e barreiras).
