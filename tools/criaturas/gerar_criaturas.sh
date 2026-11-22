#!/bin/zsh
# Gera criaturas e armas. Uso (na raiz do projeto): zsh tools/criaturas/gerar_criaturas.sh
set -e
BLENDER=/Applications/Blender.app/Contents/MacOS/Blender
ORIGEM=~/Downloads/Dragon_Baked_Actions.blend
PREP=tools/fagulha/preparar_fagulha.py
PALETA=corrompido $BLENDER -b -P $PREP -- $ORIGEM assets/models/criaturas/ignis_maw/ignis_maw.glb | grep -E "EXPORTADO"
PALETA=verde $BLENDER -b -P $PREP -- $ORIGEM assets/models/criaturas/filhote_de_asa/filhote_de_asa.glb | grep -E "EXPORTADO"
$BLENDER -b -P tools/criaturas/converter_animais_e_armas.py -- "$PWD" | grep -E "EXPORTADO|ARMA"
