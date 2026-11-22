STATUS: APROVADA
COMMIT: ver `git log` (Etapa 2)
ALTERAÇÕES:
- Costa: a terra se achata até a praia e só desce nos últimos 14 m (antes 86 penhascos de 4,5 a 6,4 m em 6 m).
- `Mundo.chao_em(x, z)`: altura do chão onde de fato se pisa (região ou mundo). A fauna usava a altura do chão do mundo dentro de regiões que têm chão próprio (77 bichos flutuando ou enterrados no Pomar).
- Fauna espera a física antes de nascer, evita pedras, e cada bicho, ao ficar ativo pela primeira vez, sai de dentro de pedra ou tronco (`AnimalVila._desencravar`).
- Animais e NPCs: o "caminho livre" passou de 3 raios finos para uma esfera arrastada (`Solidos.caminho_livre`), que pega quinas de tronco e pedra.
TESTES EXECUTADOS:
- compilação: PASS (0 erros de script)
- varredura do Drone (`drone_auditoria`): PASS (0 bloqueadores, 0 críticos; restam 10 VISUAL de água no ar, da Etapa 3)
- testes de cena: PASS (teste_mundo, teste_sono, teste_medo, teste_cadeia, teste_queda)
- colisões/alcance: PASS (auditoria_cercos, auditoria_buracos, auditoria_continua)
- missões: PASS (cadeia)
FALHAS ENCONTRADAS (já corrigidas):
- C-01 CRITICO penhasco costeiro x86, (-736..-706, -2062..26): costa descia 15 m em 24 m. Corrigido.
- C-02 CRITICO ser flutuando/enterrado x77, Pomar (-460,-284 e arredores): altura do chão errada. Corrigido.
- C-03 CRITICO ser dentro de parede x2, Pomar (-504,-300) e Acampamento (639,-387): coelho/animal nasceu dentro de tronco. Corrigido.
REGRESSÕES: nenhuma.
PENDÊNCIAS NÃO BLOQUEADORAS:
- A foto aérea do Acampamento mostra a água em faixa serrilhada sobre chão mais baixo: é o item da Etapa 3.
- Capturas do Drone ficam em tools/capturas/drone_etapa2_<regiao>.png (aérea, entrada, centro, borda).
PRÓXIMA ETAPA PERMITIDA: Etapa 3 (rios, água, margens e costa).
