#!/bin/zsh
# Gera os humanoides jogáveis e de história a partir dos pacotes CC0 do Quaternius (só leitura) e importa no Godot.
# Uso (na raiz do projeto):  zsh tools/personagens/gerar_todos.sh
set -e
BLENDER=/Applications/Blender.app/Contents/MacOS/Blender
MONTAR=tools/personagens/montar_personagem.py
DEST=assets/models/personagens

# nome  sexo  pele  partes do traje  cabelo
$BLENDER -b -P $MONTAR -- torin Male Light "Male_Ranger_Body,Male_Ranger_Arms,Male_Ranger_Legs,Male_Ranger_Feet_Boots" "Hair_SimpleParted" $DEST/torin/torin.glb | grep -E "EXPORTADO"
$BLENDER -b -P $MONTAR -- vane Male Dark "Male_Ranger_Body,Male_Ranger_Arms,Male_Ranger_Legs,Male_Ranger_Feet_Boots,Male_Ranger_Head_Hood,Male_Ranger_Acc_Pauldron" "" $DEST/vane/vane.glb | grep -E "EXPORTADO"
$BLENDER -b -P $MONTAR -- brenn Female Dark "Female_Peasant_Body,Female_Peasant_Arms,Female_Peasant_Legs,Female_Peasant_Feet" "Hair_Buns" $DEST/brenn/brenn.glb | grep -E "EXPORTADO"

# NPCs menores do Refúgio do Pinhal (texturas de 512 para não pesar o repositório)
export TEXLIM=512
$BLENDER -b -P $MONTAR -- dorn Male Light "Male_Peasant_Body,Male_Peasant_Arms,Male_Peasant_Legs,Male_Peasant_Feet" "Hair_Buzzed" $DEST/dorn/dorn.glb | grep -E "EXPORTADO"
$BLENDER -b -P $MONTAR -- orin Male Dark "Male_Ranger_Body,Male_Ranger_Arms,Male_Ranger_Legs,Male_Ranger_Feet_Boots,Male_Ranger_Acc_Pauldron" "Hair_Buzzed" $DEST/orin/orin.glb | grep -E "EXPORTADO"
$BLENDER -b -P $MONTAR -- tessa Female Light "Female_Peasant_Body,Female_Peasant_Arms,Female_Peasant_Legs,Female_Peasant_Feet" "Hair_Long" $DEST/tessa/tessa.glb | grep -E "EXPORTADO"
$BLENDER -b -P $MONTAR -- mira Female Light "Female_Ranger_Body,Female_Ranger_Arms,Female_Ranger_Legs,Female_Ranger_Feet,Female_Ranger_Head_Hood,Female_Ranger_Acc_Pauldrons" "" $DEST/mira/mira.glb | grep -E "EXPORTADO"
unset TEXLIM

# primeira importação cria os .import; depois ajusta como as texturas embutidas são tratadas
godot --headless --path . --import >/dev/null 2>&1 || true
for n in torin vane brenn dorn orin tessa mira; do
  sed -i '' 's|^gltf/embedded_image_handling=.*$|gltf/embedded_image_handling=3|' $DEST/$n/$n.glb.import
  rm -rf .godot/imported/$n.glb*
done
godot --headless --path . --import >/dev/null 2>&1 || true
echo "personagens gerados e importados"
