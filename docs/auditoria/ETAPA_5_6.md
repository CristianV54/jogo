STATUS: APROVADA (escopo reduzido, ver pendências)
COMMIT: ver `git log` (Etapas 5 e 6)
ALTERAÇÕES:
- Campos já em talhões (trigo maduro e novo, milho, repolho, verduras, abóbora, pousio) com cerca no eixo do campo, portão, espantalho no meio; agora também com trechos de cerca quebrada (8%).
- Pescador: tipo próprio com cabana sobre toras de palafita, fogueira, barris, cão, pescador Edu e doca de tábuas sobre o rio mais perto, com barco amarrado, rede e caixas de peixe. O povoado foi movido para a margem do Rio Cinzento (era a 48 m dele).
- Paletas de casa por tipo (fazenda palha/taipa, vila pedra, cabana, pescador, posto imperial pedra escura) e por região (Ferrogris, Cratera, Castelo), de etapas anteriores.
- Auditoria nova no Drone: "povoado incompleto" confere, por tipo, casas, campos e NPCs.
TESTES EXECUTADOS:
- compilação: PASS; varredura do Drone: PASS (0 bloqueadores, 0 críticos, 2 VISUAL de água); testes de cena/colisão/missões: PASS (mundo, cercos, buracos, contínua, cadeia, marcos 4/5/7, sono, medo, queda); auditoria de lógica: 1 aviso falso conhecido.
FALHAS ENCONTRADAS: nenhuma nova. O pescador estava a 48 m do rio (a doca ficava longe da cabana): corrigido.
PENDÊNCIAS NÃO BLOQUEADORAS:
- Povoados de ambientação (Névoa Azul, Brumosa, Pinhal Escuro etc.) usam os mesmos modelos de casa com paleta diferente; não há variação de planta.
- Não existem ainda postos imperiais com torres e bandeiras próprias, nem vilas com carpintaria e praça distintas (só ferraria e taverna).
- As palafitas são toras sob a cabana, não uma plataforma elevada sobre a água.
- Capturas: tools/capturas/povoado_etapa5_*.png e povoado_etapa5b_pescador.png.
PRÓXIMA ETAPA PERMITIDA: Etapa 7 (NPCs, animais, colisões e rotinas).
