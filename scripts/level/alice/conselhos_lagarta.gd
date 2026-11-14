extends Fase
## Alice, Capítulo 5 — Conselhos de uma Lagarta.
## Floresta de cogumelos gigantes de feltro. A Lagarta azul, lá no alto do maior cogumelo, pergunta
## "Quem é você?" em bolhas de sabão. A mecânica é o TAMANHO:
##   🔴 cogumelinho vermelho → o Nino vira GIGANTE (pula muito alto);
##   🔵 cogumelinho azul     → o Nino fica PEQUENININHO (cabe no buraco do tronco);
##   ⚪ cogumelinho branco    → volta ao normal.
## Achar os 3 pedaços do cogumelo: no alto de um cogumelo altíssimo (gigante), dentro do tronco oco
## (pequenininho) e com a Lagarta, no topo da escadinha de cogumelos.

const SOM_PLIM := preload("res://assets/audio/sfx/botao_plim_a.mp3")
const SOM_PEDACO := preload("res://assets/audio/sfx/botao_plim_b.mp3")
const FONTE := preload("res://assets/fonts/Fredoka-Bold.woff2")
const M_GRAMA := preload("res://materials/pbr/feltro_verde.tres")
const M_CAULE := preload("res://materials/pbr/feltro_creme.tres")
const M_TRONCO := preload("res://materials/pbr/cotele_marrom.tres")
const M_MADEIRA := preload("res://materials/pbr/madeira.tres")
const M_BOLHA := preload("res://materials/pbr/vidro_claro.tres")

const RAIO_CHAO: float = 42.0

var _bolhas: Array[Node3D] = []
var _tempo: float = 0.0


func _ready() -> void:
	_gravidade_e_chao()
	_estacoes()
	_cogumelo_altissimo()
	_tronco_oco()
	_escadinha_e_lagarta()
	_floresta()
	super._ready()


func _process(delta: float) -> void:
	_tempo += delta
	for i in _bolhas.size():
		var b: Node3D = _bolhas[i]
		b.position.y += delta * 0.35
		b.position.x += sin(_tempo * 1.4 + i) * delta * 0.2
		if b.position.y > 19.0:
			b.position.y = 13.5


# ---------------- base ----------------

func _gravidade_e_chao() -> void:
	var a := Area3D.new()
	a.collision_layer = 0
	a.collision_mask = 6
	a.monitorable = false
	a.gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
	a.gravity_direction = Vector3.DOWN
	a.gravity = 25.0
	a.position = Vector3(0, 20, 0)
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(RAIO_CHAO * 2.0, 60, RAIO_CHAO * 2.0)
	c.shape = b
	a.add_child(c)
	add_child(a)
	var chao := StaticBody3D.new()
	add_child(chao)
	var cm := CylinderMesh.new()
	cm.top_radius = RAIO_CHAO
	cm.bottom_radius = RAIO_CHAO + 2.0
	cm.height = 4.0
	_malha(chao, cm, Vector3(0, -2.0, 0), M_GRAMA)
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = RAIO_CHAO
	cs.height = 4.0
	col.shape = cs
	col.position.y = -2.0
	chao.add_child(col)


func _malha(pai: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.position = pos
	m.material_override = mat
	pai.add_child(m)
	return m


func _feltro(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.95
	m.rim_enabled = true
	m.rim = 0.4
	return m


## Cogumelo de feltro: caule + chapéu (meia esfera) com bolinhas; o topo do chapéu é plataforma.
func _cogumelo(pos: Vector3, altura: float, raio_chapeu: float, cor: Color, colisao: bool = true) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = pos
	add_child(corpo)
	var caule := CylinderMesh.new()
	caule.top_radius = raio_chapeu * 0.22
	caule.bottom_radius = raio_chapeu * 0.3
	caule.height = altura
	_malha(corpo, caule, Vector3(0, altura / 2.0, 0), M_CAULE)
	var chapeu := SphereMesh.new()
	chapeu.radius = raio_chapeu
	chapeu.height = raio_chapeu
	chapeu.is_hemisphere = true
	var ch := _malha(corpo, chapeu, Vector3(0, altura - 0.05, 0), _feltro(cor))
	ch.scale = Vector3(1.0, 0.55, 1.0)
	var branco := _feltro(Color(1, 0.97, 0.9))
	for k in 7:
		var ang: float = k * TAU / 7.0 + 0.3
		var bolinha := SphereMesh.new()
		bolinha.radius = raio_chapeu * 0.13
		bolinha.height = raio_chapeu * 0.1
		var b := _malha(corpo, bolinha, Vector3(cos(ang) * raio_chapeu * 0.6,
			altura + raio_chapeu * 0.36, sin(ang) * raio_chapeu * 0.6), branco)
	if colisao:
		var c1 := CollisionShape3D.new()
		var s1 := CylinderShape3D.new()
		s1.radius = raio_chapeu * 0.28
		s1.height = altura
		c1.shape = s1
		c1.position.y = altura / 2.0
		corpo.add_child(c1)
		var c2 := CollisionShape3D.new()
		var s2 := CylinderShape3D.new()
		s2.radius = raio_chapeu * 0.92
		s2.height = raio_chapeu * 0.5
		c2.shape = s2
		c2.position.y = altura + raio_chapeu * 0.25 - 0.05
		corpo.add_child(c2)
	return corpo


## Altura do topo do chapéu (plataforma) de um cogumelo.
static func _topo(altura: float, raio_chapeu: float) -> float:
	return altura + raio_chapeu * 0.5 - 0.05


func _placa(texto: String, pos: Vector3, tamanho_fonte: int = 64) -> Label3D:
	var l := Label3D.new()
	l.text = texto
	l.font = FONTE
	l.font_size = tamanho_fonte
	l.pixel_size = 0.006
	l.modulate = Color(1.0, 0.95, 0.82)
	l.outline_modulate = Color(0.3, 0.2, 0.45)
	l.outline_size = 16
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	add_child(l)
	return l


# ---------------- estações de tamanho ----------------

func _estacoes() -> void:
	var pt: bool = MenuEstanteUI._pt()
	_placa("🔴 cresce   🔵 encolhe   ⚪ normal" if pt else "🔴 grow   🔵 shrink   ⚪ normal", Vector3(0, 3.2, -6.0), 56)
	_estacao(Vector3(4.0, 0, -9.0), 2.3, Color(0.95, 0.25, 0.25))
	_estacao(Vector3(-5.0, 0, 4.0), 0.38, Color(0.3, 0.5, 1.0))
	_estacao(Vector3(-2.0, 0, -9.0), 1.0, Color(1, 1, 1))
	_estacao(Vector3(-9.5, 0, 8.0), 1.0, Color(1, 1, 1))
	_estacao(Vector3(12.0, 0, -4.0), 2.3, Color(0.95, 0.25, 0.25))


## Cogumelinho mágico: encostou, mudou de tamanho (pode usar quantas vezes quiser).
func _estacao(pos: Vector3, alvo: float, cor: Color) -> void:
	var c := _cogumelo(pos, 0.7, 0.6, cor, false)
	var luz := OmniLight3D.new()
	luz.light_color = cor
	luz.light_energy = 1.2
	luz.omni_range = 3.0
	luz.position.y = 1.2
	c.add_child(luz)
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitorable = false
	area.position = pos + Vector3(0, 0.6, 0)
	var col := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 1.0
	col.shape = s
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(func(corpo: Node3D) -> void:
		var d := corpo as DreamerController
		if d == null or is_equal_approx(d.tamanho, alvo):
			return
		d.mudar_tamanho(alvo)
		var p := AudioStreamPlayer.new()
		p.stream = SOM_PLIM
		p.bus = &"Efeitos"
		p.pitch_scale = 0.55 if alvo > 1.0 else (1.9 if alvo < 1.0 else 1.0)
		add_child(p)
		p.play()
		p.finished.connect(p.queue_free)
		Efeitos.estrelinhas(self, d.global_position + Vector3.UP))


# ---------------- pedaços do cogumelo ----------------

func _pedaco(pos: Vector3, cor: Color) -> void:
	var item := MissionItem.new()
	item.som = SOM_PEDACO
	item.collision_layer = 8
	item.collision_mask = 6
	item.position = pos
	var c := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.8
	c.shape = esfera
	item.add_child(c)
	var visual := Node3D.new()
	visual.name = "Visual"
	visual.position.y = 0.6
	item.add_child(visual)
	# fatia de chapéu de cogumelo (meia lua) com bolinhas
	var fatia := CylinderMesh.new()
	fatia.top_radius = 0.5
	fatia.bottom_radius = 0.55
	fatia.height = 0.22
	fatia.radial_segments = 16
	_malha(visual, fatia, Vector3.ZERO, _feltro(cor))
	var miolo := CylinderMesh.new()
	miolo.top_radius = 0.18
	miolo.bottom_radius = 0.22
	miolo.height = 0.4
	_malha(visual, miolo, Vector3(0, -0.25, 0), M_CAULE)
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.9, 0.6)
	luz.light_energy = 1.0
	luz.omni_range = 3.0
	visual.add_child(luz)
	add_child(item)


func _cogumelo_altissimo() -> void:
	# topo a 5 m: só o Nino gigante alcança (normal pula ~2,4 m; gigante ~5,5 m)
	_cogumelo(Vector3(14.0, 0, -10.0), 4.0, 2.0, Color(0.95, 0.5, 0.2))
	_pedaco(Vector3(14.0, _topo(4.0, 2.0) + 0.05, -10.0), Color(0.95, 0.5, 0.2))
	_placa("Alto demais…" if MenuEstanteUI._pt() else "Too tall…", Vector3(14.0, 8.4, -10.0), 48)


func _tronco_oco() -> void:
	# tronco caído com um buraquinho de 0,7 m: só o Nino pequenininho passa
	var tronco := CSGCombiner3D.new()
	tronco.use_collision = true
	tronco.position = Vector3(-13.0, 0, 9.0)
	tronco.rotation.y = 0.35
	add_child(tronco)
	var fora := CSGCylinder3D.new()
	fora.radius = 2.2
	fora.height = 9.0
	fora.sides = 28
	fora.rotation.z = PI / 2.0
	fora.position.y = 2.0
	fora.material = M_TRONCO
	tronco.add_child(fora)
	var dentro := CSGCylinder3D.new()
	dentro.radius = 1.7
	dentro.height = 8.2
	dentro.sides = 28
	dentro.rotation.z = PI / 2.0
	dentro.position.y = 2.0
	dentro.operation = CSGShape3D.OPERATION_SUBTRACTION
	dentro.material = M_MADEIRA
	tronco.add_child(dentro)
	var buraco := CSGBox3D.new()
	buraco.size = Vector3(1.4, 0.7, 0.7)
	buraco.position = Vector3(4.4, 0.65, 0)
	buraco.operation = CSGShape3D.OPERATION_SUBTRACTION
	buraco.material = M_MADEIRA
	tronco.add_child(buraco)
	# chão de dentro na altura do buraco (o fundo do cilindro é curvo)
	var piso := CSGBox3D.new()
	piso.size = Vector3(8.0, 0.3, 2.4)
	piso.position = Vector3(0, 0.15, 0)
	piso.material = M_MADEIRA
	tronco.add_child(piso)
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.8, 0.5)
	luz.light_energy = 1.5
	luz.omni_range = 4.0
	luz.position = Vector3(-2.5, 1.5, 0)
	tronco.add_child(luz)
	var marca := Marker3D.new()
	marca.position = Vector3(-3.0, 0.3, 0)
	tronco.add_child(marca)
	_pedaco(marca.global_position, Color(0.3, 0.5, 1.0))
	_placa("Pequenininho cabe!" if MenuEstanteUI._pt() else "Tiny fits!", tronco.to_global(Vector3(5.2, 2.0, 0)), 48)


func _escadinha_e_lagarta() -> void:
	# escadinha de cogumelos: o 1º dá para pular normal; os outros, só gigante
	_cogumelo(Vector3(4.0, 0, 10.0), 1.4, 1.6, Color(0.85, 0.35, 0.55))   # topo 2,2
	_cogumelo(Vector3(7.5, 0, 14.0), 4.2, 1.8, Color(0.55, 0.4, 0.85))   # topo 5,1
	_cogumelo(Vector3(4.5, 0, 18.5), 6.6, 2.0, Color(0.95, 0.75, 0.3))   # topo 7,6
	_cogumelo(Vector3(0.0, 0, 21.0), 9.2, 4.5, Color(0.25, 0.55, 0.9))   # topo 11,45
	var topo: float = _topo(9.2, 4.5)
	_pedaco(Vector3(1.6, topo + 0.05, 21.0), Color(0.25, 0.55, 0.9))
	# a Lagarta azul: corpinho de bolas de feltro em "S"
	var lagarta := Personagem.new()
	lagarta.position = Vector3(-1.2, topo - 0.05, 21.6)
	lagarta.altura_balao = 2.6
	var pt: bool = MenuEstanteUI._pt()
	lagarta.falas = PackedStringArray([
		"Quem… é… você?" if pt else "Who… are… you?",
		"Um lado faz crescer, o outro faz diminuir." if pt else "One side will make you grow taller, the other side shorter.",
		"Mantenha a calma." if pt else "Keep your temper."])
	lagarta.tom_voz = 160.0
	lagarta.raio_conversa = 9.0
	lagarta.intervalo = 6.0
	add_child(lagarta)
	var azul := _feltro(Color(0.3, 0.5, 0.95))
	for k in 6:
		var seg := SphereMesh.new()
		var r: float = 0.42 - k * 0.03
		seg.radius = r
		seg.height = r * 2.0
		_malha(lagarta, seg, Vector3(k * 0.5, r + absf(sin(k * 1.1)) * 0.15 + (0.6 if k == 0 else 0.0), 0), azul)
	var olho := _feltro(Color(0.05, 0.05, 0.08))
	for z: float in [-0.15, 0.15]:
		var o := SphereMesh.new()
		o.radius = 0.06
		o.height = 0.12
		_malha(lagarta, o, Vector3(-0.35, 1.15, z), olho)
	# bolhas de sabão com as letras de "QUEM É VOCÊ?"
	var letras: String = "QUEM É VOCÊ?" if pt else "WHO ARE YOU?"
	for i in letras.length():
		if letras[i] == " ":
			continue
		var bolha := Node3D.new()
		bolha.position = Vector3(-1.5 + (i % 6) * 0.45, topo + 2.0 + i * 0.45, 21.0 + (i % 3) * 0.3)
		add_child(bolha)
		var esf := SphereMesh.new()
		esf.radius = 0.32
		esf.height = 0.64
		_malha(bolha, esf, Vector3.ZERO, M_BOLHA)
		var l := Label3D.new()
		l.text = letras[i]
		l.font = FONTE
		l.font_size = 72
		l.pixel_size = 0.005
		l.modulate = Color(0.3, 0.45, 0.9)
		l.outline_size = 8
		l.outline_modulate = Color(1, 1, 1)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		bolha.add_child(l)
		_bolhas.append(bolha)


func _floresta() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	var cores: Array[Color] = [Color(0.95, 0.35, 0.4), Color(0.6, 0.45, 0.9), Color(0.95, 0.7, 0.3),
		Color(0.4, 0.7, 0.5), Color(0.95, 0.55, 0.75)]
	for i in 40:
		var ang: float = rng.randf() * TAU
		var r: float = rng.randf_range(18.0, RAIO_CHAO - 2.0)
		var pos := Vector3(cos(ang) * r, 0, sin(ang) * r)
		if pos.distance_to(Vector3(-13, 0, 9)) < 7.0 or pos.distance_to(Vector3(14, 0, -10)) < 5.0:
			continue
		var alt: float = rng.randf_range(3.0, 11.0)
		_cogumelo(pos, alt, alt * rng.randf_range(0.35, 0.55), cores[i % cores.size()], alt < 6.0)
	# capim alto (folhas de feltro) espalhado
	var verde := _feltro(Color(0.35, 0.6, 0.3))
	for i in 120:
		var ang: float = rng.randf() * TAU
		var r: float = rng.randf_range(3.0, RAIO_CHAO - 1.0)
		var folha := PrismMesh.new()
		folha.size = Vector3(0.35, rng.randf_range(0.8, 2.2), 0.05)
		var f := _malha(self, folha, Vector3(cos(ang) * r, folha.size.y / 2.0, sin(ang) * r), verde)
		f.rotation.y = rng.randf() * TAU
		f.rotation.z = rng.randf_range(-0.2, 0.2)
