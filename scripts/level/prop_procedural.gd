@tool
class_name PropProcedural
extends Node3D
## Peças de cenário geradas por código (aparecem no editor): bule-casinha, xícara flutuante, relógio de bolso,
## nuvem de algodão, florzinha de feltro e botão decorativo. Torno (revolução) + tubos ao longo de curvas.
## `tamanho` = raio principal em metros. Os filhos gerados não são salvos na cena (são refeitos ao abrir).

enum Tipo { BULE, XICARA, RELOGIO, NUVEM, FLOR, BOTAO }

const PORCELANA := preload("res://materials/pbr/porcelana_florida.tres")
const CERAMICA_AZUL := preload("res://materials/pbr/ceramica_azul.tres")
const MADEIRA := preload("res://materials/pbr/madeira_verniz.tres")
const ALGODAO := preload("res://materials/pbr/feltro_creme.tres")
const FELTRO_FLOR := preload("res://materials/pbr/feltro_rosa.tres")
const FELTRO_VERDE := preload("res://materials/pbr/feltro_verde.tres")
const PLASTICO := preload("res://materials/pbr/botao_plastico_amarelo.tres")
const LINHA := preload("res://materials/pbr/linha_vermelha.tres")
const FONTE := preload("res://assets/fonts/Fredoka-Bold.woff2")

@export var tipo: Tipo = Tipo.BULE:
	set(v):
		tipo = v
		_refazer()
@export var tamanho: float = 1.0:
	set(v):
		tamanho = v
		_refazer()
@export var cor: Color = Color(1, 1, 1):
	set(v):
		cor = v
		_refazer()
@export var semente: int = 0:
	set(v):
		semente = v
		_refazer()
@export var com_colisao: bool = true:
	set(v):
		com_colisao = v
		_refazer()

var _raiz: Node3D


func _ready() -> void:
	_refazer()


func _refazer() -> void:
	if not is_inside_tree():
		return
	if _raiz:
		_raiz.queue_free()
	_raiz = Node3D.new()
	_raiz.name = "_Gerado"
	add_child(_raiz, false, Node.INTERNAL_MODE_FRONT)
	match tipo:
		Tipo.BULE:
			_bule()
		Tipo.XICARA:
			_xicara()
		Tipo.RELOGIO:
			_relogio()
		Tipo.NUVEM:
			_nuvem()
		Tipo.FLOR:
			_flor()
		Tipo.BOTAO:
			_botao()


# ---------------------------------------------------------------- peças

func _bule() -> void:
	var s: float = tamanho
	var corpo := _torno([Vector2(0, -0.86), Vector2(0.55, -0.84), Vector2(0.86, -0.6), Vector2(1.0, -0.15),
		Vector2(0.98, 0.2), Vector2(0.85, 0.5), Vector2(0.62, 0.7), Vector2(0.46, 0.77), Vector2(0.0, 0.77)], s)
	_malha(corpo, PORCELANA, true)
	var tampa := _torno([Vector2(0.0, 0.76), Vector2(0.5, 0.76), Vector2(0.52, 0.8), Vector2(0.42, 0.92),
		Vector2(0.2, 0.98), Vector2(0.1, 1.0), Vector2(0.17, 1.06), Vector2(0.13, 1.14), Vector2(0.0, 1.16)], s)
	_malha(tampa, CERAMICA_AZUL, true)
	# bico (+X) e alça (-X)
	_malha(_tubo([Vector3(0.82, -0.25, 0), Vector3(1.12, -0.02, 0), Vector3(1.3, 0.35, 0), Vector3(1.42, 0.55, 0)],
		[0.24, 0.17, 0.11, 0.1], s), PORCELANA, false)
	_malha(_tubo([Vector3(-0.8, 0.45, 0), Vector3(-1.2, 0.35, 0), Vector3(-1.3, 0.0, 0), Vector3(-1.15, -0.3, 0),
		Vector3(-0.9, -0.42, 0)], [0.08, 0.08, 0.08, 0.08, 0.08], s), CERAMICA_AZUL, false)
	# portinha em arco e janelinhas acesas (o bule é uma casinha!)
	var porta := _caixa(Vector3(0.24, 0.32, 0.06) * s, Vector3(0, -0.5, 0.92) * s, MADEIRA)
	porta.rotation.x = -0.25
	var arco := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.12 * s
	cil.bottom_radius = 0.12 * s
	cil.height = 0.06 * s
	arco.mesh = cil
	arco.material_override = MADEIRA
	arco.position = Vector3(0, -0.34, 0.885) * s
	arco.rotation = Vector3(PI / 2 - 0.25, 0, 0)
	_raiz.add_child(arco)
	for x: float in [-0.48, 0.48]:
		var janela := MeshInstance3D.new()
		var esf := SphereMesh.new()
		esf.radius = 0.09 * s
		esf.height = 0.06 * s
		janela.mesh = esf
		janela.material_override = _luz(Color(1.0, 0.78, 0.4), 2.5)
		janela.position = Vector3(x, 0.05, 0.86) * s
		janela.basis = Basis(Quaternion(Vector3.UP, janela.position.normalized()))
		_raiz.add_child(janela)
	# vapor de tule saindo do bico
	var vapor := _particulas_vapor(s)
	vapor.position = Vector3(1.45, 0.62, 0) * s
	_raiz.add_child(vapor)


func _xicara() -> void:
	var s: float = tamanho
	var copo := _torno([Vector2(0, 0.0), Vector2(0.5, 0.0), Vector2(0.62, 0.08), Vector2(0.92, 0.7), Vector2(1.0, 0.82),
		Vector2(0.94, 0.84), Vector2(0.86, 0.74), Vector2(0.6, 0.18), Vector2(0.0, 0.14)], s)
	_malha(copo, PORCELANA, true)
	var pires := _torno([Vector2(0, -0.08), Vector2(1.3, -0.08), Vector2(1.5, 0.04), Vector2(1.44, 0.07),
		Vector2(0.62, 0.0), Vector2(0, 0.0)], s)
	_malha(pires, CERAMICA_AZUL, true)
	var cha := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 0.88 * s
	disco.bottom_radius = 0.88 * s
	disco.height = 0.02 * s
	cha.mesh = disco
	var mat_cha := StandardMaterial3D.new()
	mat_cha.albedo_color = Color(0.45, 0.25, 0.12)
	mat_cha.roughness = 0.05
	cha.material_override = mat_cha
	cha.position.y = 0.66 * s
	_raiz.add_child(cha)
	_malha(_tubo([Vector3(0.9, 0.62, 0), Vector3(1.25, 0.6, 0), Vector3(1.22, 0.3, 0), Vector3(0.8, 0.25, 0)],
		[0.06, 0.06, 0.06, 0.06], s), PORCELANA, false)
	# arvorezinha de feltro dentro (como nas ilhas do conceito)
	var r := RandomNumberGenerator.new()
	r.seed = semente
	for k in 2:
		var arv := _caixa(Vector3(0.06, 0.4, 0.06) * s, Vector3(r.randf_range(-0.4, 0.4), 0.85, r.randf_range(-0.4, 0.4)) * s,
			MADEIRA)
		var copa := MeshInstance3D.new()
		var esf := SphereMesh.new()
		esf.radius = 0.22 * s
		esf.height = 0.4 * s
		copa.mesh = esf
		copa.material_override = FELTRO_VERDE
		copa.position = arv.position + Vector3(0, 0.3, 0) * s
		_raiz.add_child(copa)


func _relogio() -> void:
	var s: float = tamanho
	var ouro := StandardMaterial3D.new()
	ouro.albedo_color = Color(0.95, 0.72, 0.32)
	ouro.metallic = 1.0
	ouro.roughness = 0.22
	var caixa := _torno([Vector2(0, -0.12), Vector2(0.98, -0.12), Vector2(1.04, -0.02), Vector2(1.04, 0.06),
		Vector2(0.98, 0.1), Vector2(0.92, 0.08), Vector2(0.9, 0.04), Vector2(0, 0.04)], s)
	_malha(caixa, ouro, true)
	var mostrador := _torno([Vector2(0, 0.045), Vector2(0.9, 0.045), Vector2(0.9, 0.05), Vector2(0, 0.05)], s)
	_malha(mostrador, preload("res://materials/pbr/ceramica_branca.tres"), false)
	var numeros: Array[String] = ["XII", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI"]
	for i in 12:
		var l := Label3D.new()
		l.text = numeros[i]
		l.font = FONTE
		l.font_size = 64
		l.pixel_size = 0.006 * s / 4.0
		l.modulate = Color(0.15, 0.12, 0.1)
		l.outline_size = 0
		l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
		var a: float = i * TAU / 12.0
		l.position = Vector3(sin(a) * 0.74, 0.056, -cos(a) * 0.74) * s
		l.rotation = Vector3(-PI / 2, -a, 0)
		_raiz.add_child(l)
	for p: Array in [[0.55, 0.035, 1.2], [0.75, 0.025, 4.0]]:  # ponteiros
		var ponteiro := _caixa(Vector3(p[1], 0.01, p[0]) * s, Vector3(0, 0.06, 0) * s, _cor_simples(Color(0.12, 0.1, 0.1)))
		ponteiro.rotation.y = p[2]
		ponteiro.translate_object_local(Vector3(0, 0, -p[0] * 0.5 * s))
	var coroa := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.1 * s
	cil.bottom_radius = 0.12 * s
	cil.height = 0.25 * s
	coroa.mesh = cil
	coroa.material_override = ouro
	coroa.position = Vector3(0, -0.02, -1.15) * s
	coroa.rotation.x = PI / 2
	_raiz.add_child(coroa)
	var argola := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.16 * s
	tor.outer_radius = 0.22 * s
	argola.mesh = tor
	argola.material_override = ouro
	argola.position = Vector3(0, -0.02, -1.42) * s
	argola.rotation.z = PI / 2
	_raiz.add_child(argola)


func _nuvem() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = semente
	var mat := ALGODAO.duplicate() as StandardMaterial3D
	mat.albedo_color = cor
	mat.rim = 1.0
	mat.rim_tint = 0.2
	for k in 7:
		var bola := MeshInstance3D.new()
		var esf := SphereMesh.new()
		var raio: float = tamanho * r.randf_range(0.35, 0.6)
		esf.radius = raio
		esf.height = raio * 1.6
		bola.mesh = esf
		bola.material_override = mat
		bola.position = Vector3(r.randf_range(-1, 1) * tamanho, r.randf_range(-0.1, 0.25) * tamanho,
			r.randf_range(-0.5, 0.5) * tamanho)
		bola.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_raiz.add_child(bola)


func _flor() -> void:
	var s: float = tamanho
	var petala := FELTRO_FLOR.duplicate() as StandardMaterial3D
	petala.albedo_color = cor
	for k in 5:
		var p := MeshInstance3D.new()
		var esf := SphereMesh.new()
		esf.radius = 0.5 * s
		esf.height = 0.25 * s
		p.mesh = esf
		p.material_override = petala
		var a: float = k * TAU / 5.0
		p.position = Vector3(cos(a) * 0.5, 0.1, sin(a) * 0.5) * s
		_raiz.add_child(p)
	var miolo := MeshInstance3D.new()
	var esf2 := SphereMesh.new()
	esf2.radius = 0.32 * s
	esf2.height = 0.3 * s
	miolo.mesh = esf2
	var amarelo := FELTRO_FLOR.duplicate() as StandardMaterial3D
	amarelo.albedo_color = Color(1.0, 0.8, 0.25)
	miolo.material_override = amarelo
	miolo.position.y = 0.18 * s
	_raiz.add_child(miolo)


func _botao() -> void:
	var s: float = tamanho
	var mat := PLASTICO.duplicate() as StandardMaterial3D
	mat.albedo_color = cor
	_malha(_torno([Vector2(0, 0.0), Vector2(0.95, 0.0), Vector2(1.0, 0.06), Vector2(0.98, 0.2), Vector2(0.86, 0.24),
		Vector2(0.74, 0.16), Vector2(0.0, 0.1)], s), mat, com_colisao)
	var furo := _cor_simples(Color(0.1, 0.07, 0.05))
	for v: Vector2 in [Vector2(0.22, 0.22), Vector2(-0.22, 0.22), Vector2(0.22, -0.22), Vector2(-0.22, -0.22)]:
		var f := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.top_radius = 0.09 * s
		cil.bottom_radius = 0.09 * s
		cil.height = 0.02 * s
		f.mesh = cil
		f.material_override = furo
		f.position = Vector3(v.x, 0.105, v.y) * s
		_raiz.add_child(f)
	for ang: float in [PI / 4, -PI / 4]:
		var ponto := _caixa(Vector3(0.08, 0.05, 0.75) * s, Vector3(0, 0.13, 0) * s, LINHA)
		ponto.rotation.y = ang


# ---------------------------------------------------------------- utilidades

## Superfície de revolução em torno de Y a partir de um perfil (x = raio, y = altura), em unidades de `escala`.
static func _torno(perfil: Array[Vector2], escala: float, segmentos: int = 48) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in perfil.size() - 1:
		var a: Vector2 = perfil[i] * escala
		var b: Vector2 = perfil[i + 1] * escala
		for j in segmentos:
			var t0: float = TAU * j / segmentos
			var t1: float = TAU * (j + 1) / segmentos
			var p00 := Vector3(cos(t0) * a.x, a.y, sin(t0) * a.x)
			var p01 := Vector3(cos(t1) * a.x, a.y, sin(t1) * a.x)
			var p10 := Vector3(cos(t0) * b.x, b.y, sin(t0) * b.x)
			var p11 := Vector3(cos(t1) * b.x, b.y, sin(t1) * b.x)
			for p: Vector3 in [p00, p10, p11, p00, p11, p01]:
				st.set_uv(Vector2(0, 0))
				st.add_vertex(p)
	st.generate_normals()
	return st.commit()


## Tubo que passa pelos pontos (spline Catmull-Rom), com raio interpolado.
static func _tubo(pontos: Array[Vector3], raios: Array[float], escala: float,
		lados: int = 16, passos: int = 12) -> ArrayMesh:
	var curva := Curve3D.new()
	for p: Vector3 in pontos:
		curva.add_point(p * escala)
	var amostras: Array[Vector3] = []
	var raios_a: Array[float] = []
	var total: int = (pontos.size() - 1) * passos
	for k in total + 1:
		var t: float = float(k) / passos
		var seg: int = mini(int(t), pontos.size() - 2)
		var f: float = t - seg
		amostras.append(_catmull(pontos, seg, f) * escala)
		raios_a.append(lerpf(raios[seg], raios[seg + 1], f) * escala)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var aneis: Array = []
	var ref := Vector3.UP
	for k in amostras.size():
		var tang: Vector3 = (amostras[mini(k + 1, amostras.size() - 1)] - amostras[maxi(k - 1, 0)]).normalized()
		if absf(tang.dot(ref)) > 0.95:
			ref = Vector3.FORWARD
		var lado: Vector3 = tang.cross(ref).normalized()
		var cima: Vector3 = lado.cross(tang).normalized()
		var anel: Array[Vector3] = []
		for j in lados + 1:
			var a: float = TAU * j / lados
			anel.append(amostras[k] + (lado * cos(a) + cima * sin(a)) * raios_a[k])
		aneis.append(anel)
	for k in aneis.size() - 1:
		for j in lados:
			var q: Array[Vector3] = [aneis[k][j], aneis[k + 1][j], aneis[k + 1][j + 1], aneis[k][j], aneis[k + 1][j + 1],
				aneis[k][j + 1]]
			for p: Vector3 in q:
				st.add_vertex(p)
	st.generate_normals()
	return st.commit()


static func _catmull(p: Array[Vector3], seg: int, t: float) -> Vector3:
	var p0: Vector3 = p[maxi(seg - 1, 0)]
	var p1: Vector3 = p[seg]
	var p2: Vector3 = p[seg + 1]
	var p3: Vector3 = p[mini(seg + 2, p.size() - 1)]
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t)


func _malha(m: Mesh, mat: Material, colisao: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	_raiz.add_child(mi)
	if colisao and com_colisao:
		var corpo := StaticBody3D.new()
		corpo.collision_layer = 1
		corpo.collision_mask = 0
		var forma := CollisionShape3D.new()
		forma.shape = m.create_trimesh_shape()
		corpo.add_child(forma)
		_raiz.add_child(corpo)
	return mi


func _caixa(tam: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	_raiz.add_child(mi)
	return mi


static func _cor_simples(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	return m


static func _luz(c: Color, energia: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energia
	return m


static func _particulas_vapor(s: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 24
	p.lifetime = 4.0
	var proc := ParticleProcessMaterial.new()
	proc.direction = Vector3(0.4, 1, 0)
	proc.spread = 15.0
	proc.initial_velocity_min = 0.25 * s
	proc.initial_velocity_max = 0.4 * s
	proc.gravity = Vector3(0, 0.02 * s, 0)
	proc.scale_min = 0.6
	proc.scale_max = 1.2
	var curva := Curve.new()
	curva.add_point(Vector2(0, 0.3))
	curva.add_point(Vector2(0.5, 1.0))
	curva.add_point(Vector2(1, 1.4))
	var tex := CurveTexture.new()
	tex.curve = curva
	proc.scale_curve = tex
	var rampa := Gradient.new()
	rampa.set_color(0, Color(1, 1, 1, 0.0))
	rampa.add_point(0.2, Color(1, 1, 1, 0.8))
	rampa.set_color(rampa.get_point_count() - 1, Color(1, 1, 1, 0.0))
	var tr := GradientTexture1D.new()
	tr.gradient = rampa
	proc.color_ramp = tr
	p.process_material = proc
	var esf := SphereMesh.new()
	esf.radius = 0.18 * s
	esf.height = 0.3 * s
	var mat := (preload("res://materials/pbr/tule_branco.tres") as StandardMaterial3D).duplicate() as StandardMaterial3D
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	esf.material = mat
	p.draw_pass_1 = esf
	return p
