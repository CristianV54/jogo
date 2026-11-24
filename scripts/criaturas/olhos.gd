class_name Olhos
extends RefCounted
## Olhos para os bichos dos pacotes (que vêm sem olho). Dois olhos por animal, presos ao osso da cabeça por um BoneAttachment3D,
## então acompanham a animação. A posição vem do osso da cabeça e do osso da ponta do focinho do próprio modelo:
## Posição de cada olho = ponto do eixo da cabeça (t, entre a base da cabeça e a ponta do focinho) + uma distância (dist * L, L =
## comprimento cabeça-ponta) numa direção que sobe `ang` graus acima da horizontal, para o lado. Os valores de cada espécie foram
## calibrados olhando o close da cabeça na bancada (tools/bancada.gd); se um modelo mudar, refazer essa calibração com foto.
## Cada olho = íris colorida + pupila preta + um brilho branco pequeno (é isso que dá "vida" ao olhar).

const ESQUELETO_FAZENDA := ["Head", "Head_end"]
const ESQUELETO_LOBO := ["Bone.003", "Bone.003_end"]

# especie -> [ossos, t (0 = base da cabeça, 1 = ponta do focinho), ângulo acima da horizontal (graus), dist (fração de L), raio (fração de L), cor da íris, desvio do plano de simetria (unidades do esqueleto)]
const TABELA := {
	"vaca": [ESQUELETO_FAZENDA, 0.33, 35, 0.3, 0.06, Color(0.2, 0.12, 0.06)],
	"ovelha": [ESQUELETO_FAZENDA, 0.35, 35, 0.3, 0.075, Color(0.62, 0.46, 0.12)],
	"porco": [ESQUELETO_FAZENDA, 0.25, 40, 0.3, 0.06, Color(0.12, 0.08, 0.05)],
	"cavalo": [ESQUELETO_FAZENDA, 0.32, 35, 0.3, 0.06, Color(0.22, 0.12, 0.05)],
	"cervo": [ESQUELETO_FAZENDA, 0.32, 35, 0.3, 0.075, Color(0.2, 0.1, 0.04)],
	"cao": [ESQUELETO_FAZENDA, 0.5, 40, 0.7, 0.08, Color(0.3, 0.16, 0.06)],
	"coelho": [ESQUELETO_FAZENDA, 0.5, 50, 0.7, 0.08, Color(0.32, 0.06, 0.05)],
	"urso": [ESQUELETO_FAZENDA, 0.5, 40, 0.7, 0.08, Color(0.55, 0.3, 0.1)],
	"cao_guerra": [ESQUELETO_FAZENDA, 0.5, 45, 0.7, 0.08, Color(0.85, 0.16, 0.08)],
	"javali": [ESQUELETO_FAZENDA, 0.25, 40, 0.3, 0.06, Color(0.45, 0.13, 0.05)],
	"lobo": [ESQUELETO_LOBO, 0.4, 28, 0.42, 0.085, Color(0.88, 0.62, 0.1), -0.02],   # os ossos do lobo ficam ~0,03 fora do meio da cabeça; -0,02 foi o melhor entre os dois olhos (ainda levemente assimétrico)
}


static func aplicar(visual: Node3D, especie: String) -> void:
	if not TABELA.has(especie):
		return
	var esq := visual.find_child("Skeleton3D", true, false) as Skeleton3D
	if esq == null:
		return
	var cfg: Array = TABELA[especie]
	var ossos: Array = cfg[0]
	var ih := esq.find_bone(ossos[0])
	var ie := esq.find_bone(ossos[1])
	if ih < 0 or ie < 0:
		return
	var rep_h := esq.get_bone_global_rest(ih)
	var rep_e := esq.get_bone_global_rest(ie)
	var focinho := rep_e.origin - rep_h.origin
	var comp := focinho.length()
	var cima := (esq.global_transform.basis.orthonormalized().inverse() * Vector3.UP).normalized()   # "cima" do mundo, no espaço do esqueleto
	var frente_h := (focinho - cima * focinho.dot(cima)).normalized()                                   # para onde a cabeça aponta, na horizontal
	var lado := cima.cross(frente_h).normalized()
	var anexo := BoneAttachment3D.new()
	anexo.name = "Olhos"
	anexo.bone_name = ossos[0]
	esq.add_child(anexo)
	var eixos := Node3D.new()   # eixos do esqueleto, de volta (o anexo gira com o osso)
	eixos.transform = Transform3D(rep_h.basis.inverse(), Vector3.ZERO)
	anexo.add_child(eixos)
	var raio: float = comp * float(cfg[4])
	var eixo: Vector3 = rep_h.origin + focinho * float(cfg[1]) + lado * (float(cfg[6]) if cfg.size() > 6 else 0.0)   # ponto no eixo da cabeça
	var ang := deg_to_rad(float(cfg[2]))
	for s in [-1.0, 1.0]:
		var dir_s: Vector3 = (lado * s * cos(ang) + cima * sin(ang)).normalized()
		var p: Vector3 = (eixo - rep_h.origin) + dir_s * comp * float(cfg[3])
		var olho := Node3D.new()
		olho.name = "Olho"
		olho.position = p
		eixos.add_child(olho)
		_bola(olho, Vector3.ZERO, raio, cfg[5], 0.35)
		_bola(olho, lado * s * raio * 0.55 + frente_h * raio * 0.15, raio * 0.6, Color(0.02, 0.02, 0.03), 0.2)
		_bola(olho, lado * s * raio * 0.75 + cima * raio * 0.4 + frente_h * raio * 0.35, raio * 0.22, Color(1, 1, 1), 0.1)


static func _bola(pai: Node3D, pos: Vector3, raio: float, cor: Color, aspereza: float) -> void:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = raio
	s.height = raio * 2.0
	s.radial_segments = 12
	s.rings = 6
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = aspereza
	m.metallic_specular = 0.8
	s.material = m
	mi.mesh = s
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(mi)
