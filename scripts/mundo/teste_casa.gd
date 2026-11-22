extends Node3D
## Cena de calibração: uma casa de 3x4 módulos (6x8 m) para conferir orientação das peças por captura.

func _ready() -> void:
	add_child(ConstrutorCasa.montar(3, 4, {
		"parede": "Wall_Plaster_WoodGrid", "porta": "Wall_Plaster_Door_Flat", "janela": "Wall_Plaster_Window_Wide_Flat",
		"piso": "Floor_WoodDark", "canto": "Corner_Exterior_Wood", "telhado": "Roof_RoundTiles_6x8"}))
