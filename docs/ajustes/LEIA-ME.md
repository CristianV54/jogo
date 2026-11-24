# Fotos dos ajustes (itens ajustados)

Aqui estão só os 11 itens ajustados na sessão de 22 e 23/11/2026, cada um com `antes.jpg`, `depois.jpg` e (animais) `cabeca_antes.jpg` e `cabeca_depois.jpg`. `LISTA.md` tem a lista dos 271 itens do inventário (o que estava ruim, o que mudou, como está).

As fotos dos outros 260 itens (todos NÃO AJUSTADOS) ficam fora do repositório por peso (~20 MB). Para refazer qualquer uma: `godot --path . --resolution 1280x720 --script res://tools/bancada.gd -- antes nome_do_item` (a saída vai para `~/Desktop/ajustes/`).

As fotos "antes" foram tiradas numa cópia limpa do commit 456cf7d. A cor da pelagem dos animais é sorteada a cada foto, então a cor pode diferir entre "antes" e "depois" sem ser ajuste.
