class_name NavegacaoLocal
extends RefCounted
## Malha de navegação de um povoado ou cidade: os NPCs a usam para achar o caminho de verdade (contornando cercas, casas e
## poços) quando voltam para casa. Assa a malha a partir dos colisores estáticos que já existem sob `raiz`.


## `meia` = metade do lado (x, z) da região de interesse em volta de `centro` (coordenadas do mundo).
## `com_chao`: acrescenta um chão plano (povoados do mundo, cujo terreno não é filho de `raiz`).
static func assar(raiz: Node3D, centro: Vector3, meia: Vector2, com_chao: bool) -> void:
	NavigationServer3D.map_set_cell_size(raiz.get_world_3d().navigation_map, 0.5)   # tem que casar com o da malha
	var nm := NavigationMesh.new()
	nm.cell_size = 0.5
	nm.cell_height = 0.25
	nm.agent_radius = 0.5
	nm.agent_height = 1.75
	nm.agent_max_climb = 0.5
	nm.agent_max_slope = 40.0
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	var c := raiz.to_local(centro)
	nm.filter_baking_aabb = AABB(c - Vector3(meia.x, 8.0, meia.y), Vector3(meia.x * 2.0, 16.0, meia.y * 2.0))
	var fonte := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nm, fonte, raiz)
	if com_chao:
		var a := Vector3(c.x - meia.x, c.y, c.z - meia.y)
		var b := Vector3(c.x + meia.x, c.y, c.z - meia.y)
		var d := Vector3(c.x - meia.x, c.y, c.z + meia.y)
		var e := Vector3(c.x + meia.x, c.y, c.z + meia.y)
		fonte.add_faces(PackedVector3Array([a, b, d, b, e, d]), Transform3D.IDENTITY)
	NavigationServer3D.bake_from_source_geometry_data(nm, fonte)
	var regiao := NavigationRegion3D.new()
	regiao.name = "Navegacao"
	regiao.navigation_mesh = nm
	raiz.add_child(regiao)
