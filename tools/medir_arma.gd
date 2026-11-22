extends SceneTree
# Mede armas importadas no espaço da RAIZ da instância (o nó filho da malha vem girado pelo importador).
# Imprime o giro do filho, o eixo do comprimento na raiz e a largura por fatia, para achar o cabo.
func _init() -> void:
	for caminho in OS.get_cmdline_user_args():
		var inst: Node3D = (load(caminho) as PackedScene).instantiate()
		root.add_child(inst)
		var mi: MeshInstance3D = inst.find_children("*", "MeshInstance3D", true, false)[0]
		var t: Transform3D = mi.transform   # local = relativo à raiz (a malha é filha direta)
		var pts: Array = []
		for s in mi.mesh.get_surface_count():
			for v in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				pts.append(t * v)
		var mn := Vector3(1e9, 1e9, 1e9)
		var mx := Vector3(-1e9, -1e9, -1e9)
		for p in pts:
			mn = mn.min(p)
			mx = mx.max(p)
		var ext := mx - mn
		var ax := 0
		if ext.y > ext[ax]: ax = 1
		if ext.z > ext[ax]: ax = 2
		var outros := [0, 1, 2]
		outros.erase(ax)
		var fatias := 40
		var larg: Array = []
		larg.resize(fatias)
		larg.fill(0.0)
		for p in pts:
			var k := clampi(int((p[ax] - mn[ax]) / ext[ax] * fatias), 0, fatias - 1)
			larg[k] = maxf(larg[k], maxf(absf(p[outros[0]]), absf(p[outros[1]])))
		var s := ""
		for k in fatias:
			s += "%.2f " % larg[k]
		print("ARMA ", caminho.get_file(), " giro_do_filho=", mi.rotation_degrees, " eixo_na_raiz=", ["X", "Y", "Z"][ax], " de ", snappedf(mn[ax], 0.01), " a ", snappedf(mx[ax], 0.01))
		print("   largura(fatias de ", snappedf(ext[ax] / fatias, 0.01), ") ", s)
	quit(0)
