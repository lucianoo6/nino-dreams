extends Fase
## Alice, Capítulo 2 — A Lagoa de Lágrimas.
## A Alice gigante chorou tanto que virou uma lagoa (de TULE!). Ela continua chorando lá no horizonte,
## e lágrimas enormes caem do céu: uma sombra na água avisa onde, e o respingo empurra quem estiver perto.
## Caminho: ilha inicial → luvinhas brancas e o leque boiando → ilha do Rato → trecho a nado
## (garrafa BEBA-ME e xícara-barquinho para descansar) → ilha do lampião → botões gigantes →
## praia onde os bichos esperam; o Dodô é a saída ("uma Corrida em Comitê!").

const SHADER_AGUA := preload("res://shaders/lagoa_tule.gdshader")
const FONTE := preload("res://assets/fonts/Fredoka-Bold.woff2")
const M_GRAMA := preload("res://materials/pbr/feltro_verde.tres")
const M_AREIA := preload("res://materials/pbr/feltro_creme.tres")
const M_TERRA := preload("res://materials/pbr/cotele_marrom.tres")
const M_LUVA := preload("res://materials/pbr/la_trico_creme.tres")
const M_PAPEL := preload("res://materials/pbr/papel.tres")
const M_MADEIRA := preload("res://materials/pbr/madeira_verniz.tres")
const M_VIDRO := preload("res://materials/pbr/vidro_claro.tres")
const M_OURO := preload("res://materials/pbr/linha_dourada.tres")
const M_FITA := preload("res://materials/pbr/veludo_vermelho.tres")
const SOM_SPLASH := preload("res://assets/audio/sfx/pouso_feltro.mp3")

## Modelos opcionais (Hyper3D); se ainda não existirem, a fase funciona sem eles.
const CAMINHO_RATO := "res://assets/models/personagens/rato.glb"
const CAMINHO_ALICE := "res://assets/models/personagens/alice_gigante.glb"

## Onde as lágrimas podem cair (faixa do trecho a nado).
const LAGRIMAS_Z := Vector2(26.0, 70.0)

var _boiando: Array[Dictionary] = []  # {no, base, fase, amplitude}
var _tempo: float = 0.0
var _relogio_lagrima: float = 2.0
## Coisas para "assentar" no chão de verdade (raycast) depois que a física começa.
var _assentar: Array[Node3D] = []


func _ready() -> void:
	_gravidade()
	_lagoa()
	_caminho()
	_praia()
	_alice_no_horizonte()
	_fundo()
	super._ready()
	_assentar_tudo.call_deferred()


func _physics_process(delta: float) -> void:
	_tempo += delta
	for b: Dictionary in _boiando:
		var n := b["no"] as Node3D
		var base: Vector3 = b["base"]
		var f: float = b["fase"]
		n.position = base + Vector3.UP * sin(_tempo * 1.3 + f) * float(b["amplitude"])
		n.rotation.z = sin(_tempo * 0.9 + f) * 0.04
	_relogio_lagrima -= delta
	if _relogio_lagrima <= 0.0:
		_relogio_lagrima = randf_range(1.2, 2.2)
		_lagrima()


# ---------------- base ----------------

func _gravidade() -> void:
	var a := Area3D.new()
	a.collision_layer = 0
	a.collision_mask = 6
	a.monitorable = false
	a.gravity_space_override = Area3D.SPACE_OVERRIDE_REPLACE
	a.gravity_direction = Vector3.DOWN
	a.gravity = 25.0
	a.position = Vector3(0, 20, 50)
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(220, 80, 260)
	c.shape = b
	a.add_child(c)
	add_child(a)


func _lagoa() -> void:
	var agua := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(220, 260)
	pm.subdivide_width = 110
	pm.subdivide_depth = 130
	agua.mesh = pm
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_AGUA
	agua.material_override = mat
	agua.position = Vector3(0, 0, 50)
	agua.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(agua)
	var zona := ZonaAgua.new()
	zona.tamanho = Vector3(220, 8, 260)
	zona.position = Vector3(0, -4, 50)
	add_child(zona)
	# fundo de feltro (para não "afundar" para sempre)
	_caixa_solida(Vector3(0, -7, 50), Vector3(220, 1, 260), M_AREIA)


func _caixa_solida(pos: Vector3, tamanho: Vector3, mat: Material) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = pos
	add_child(corpo)
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tamanho
	m.mesh = bm
	m.material_override = mat
	corpo.add_child(m)
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = tamanho
	c.shape = s
	corpo.add_child(c)
	return corpo


func _malha(pai: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.position = pos
	m.material_override = mat
	pai.add_child(m)
	return m


## Ilhota de feltro esculpida (kit): topo fofo costurado, florzinhas e cogumelinhos, terra de cotelê
## com raízes de lã — a borda do feltro fica na linha da água.
func _ilha(pos: Vector3, raio: float, semente: int) -> Node3D:
	# escala UNIFORME (senão os cogumelinhos do topo viram panquecas); a parte de terra fica submersa.
	# No modelo normalizado (altura 0,86): borda do feltro ~0,55; topo do domo ~0,74
	var esc := Vector3.ONE * raio * 2.0
	var y: float = pos.y - 0.74 * esc.y
	var ilha := KitCenario.colocar(self, "ilha_feltro", Vector3(pos.x, y, pos.z), esc, semente * 1.3, "estatico", 0.74)
	# juncos na beirinha
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	for i in 3:
		var ang: float = rng.randf() * TAU
		KitCenario.enfeite(self, "juncos", Vector3(pos.x + cos(ang) * raio * 1.0, -0.4, pos.z + sin(ang) * raio * 1.0),
			rng.randf_range(1.6, 2.6), rng.randf() * TAU)
	return ilha


## Coisa boiando onde dá para pisar (sobe e desce com a água).
func _boia(pos: Vector3, amplitude: float = 0.12) -> AnimatableBody3D:
	var corpo := AnimatableBody3D.new()
	corpo.position = pos
	corpo.sync_to_physics = true
	add_child(corpo)
	_boiando.append({"no": corpo, "base": pos, "fase": randf() * TAU, "amplitude": amplitude})
	return corpo


func _forma_caixa(corpo: CollisionObject3D, tamanho: Vector3, pos: Vector3 = Vector3.ZERO) -> void:
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = tamanho
	c.shape = s
	c.position = pos
	corpo.add_child(c)


# ---------------- o caminho ----------------

func _caminho() -> void:
	_ilha(Vector3(0, 0.55, 0), 5.0, 1)
	var pt: bool = MenuEstanteUI._pt()
	_placa("Atravesse a lagoa até a margem!" if pt else "Cross the pool to the shore!", Vector3(-2.5, 3.2, 3.5))
	# as luvinhas brancas que o Coelho deixou cair
	_luva(Vector3(2.0, 0.15, 9.0), 0.4)
	_luva(Vector3(-1.2, 0.15, 13.0), -0.5)
	# o leque (foi ele que fez a Alice encolher!)
	_leque(Vector3(1.8, 0.2, 18.0))
	# ilha do Rato
	_ilha(Vector3(-3.0, 0.7, 25.5), 4.0, 2)
	_rato(Vector3(-3.6, 0.82, 26.5))
	# trecho a nado, com lugares para descansar
	_garrafa(Vector3(3.5, 0.2, 35.0))
	_xicara_barco(Vector3(-2.5, -0.35, 42.5))
	_placa("Cuidado com as lágrimas! ☂" if pt else "Watch out for the tears! ☂", Vector3(-3.0, 3.6, 29.0))
	# ilha do lampião
	_ilha(Vector3(2.0, 0.7, 52.0), 4.5, 3)
	_lampiao(Vector3(3.2, 0.82, 53.0))
	# vitórias-régias de feltro para pular até a praia
	for i in 4:
		var v := KitCenario.colocar(self, "vitoria_regia", Vector3(-1.5 + (i % 2) * 3.0, -0.3, 58.5 + i * 3.6),
			Vector3(3.2, 1.0, 3.2), i * 1.7, "animavel", 0.25)
		_boiando.append({"no": v, "base": v.position, "fase": i * 1.1, "amplitude": 0.06})
	# mais vitórias-régias e juncos espalhados pela lagoa (enfeite)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 26:
		var p := Vector3(rng.randf_range(-26, 26), -0.35, rng.randf_range(-8, 74))
		if absf(p.x) < 6.0:
			continue
		if i % 2 == 0:
			KitCenario.enfeite(self, "vitoria_regia", p, rng.randf_range(1.5, 3.0), rng.randf() * TAU)
		else:
			KitCenario.enfeite(self, "juncos", p, rng.randf_range(2.0, 4.0), rng.randf() * TAU)


func _luva(pos: Vector3, giro: float) -> void:
	# luva de feltro esculpida, deitada (≈2 x 2,6 m)
	var b := KitCenario.colocar(self, "luva", pos + Vector3(0, -0.25, 0), Vector3(2.6, 1.3, 2.6), giro, "animavel")
	_boiando.append({"no": b, "base": b.position, "fase": randf() * TAU, "amplitude": 0.12})


func _leque(pos: Vector3) -> void:
	var b := KitCenario.colocar(self, "leque", pos + Vector3(0, -0.1, 0), Vector3(4.6, 3.0, 4.6), 0.2, "animavel")
	_boiando.append({"no": b, "base": b.position, "fase": randf() * TAU, "amplitude": 0.1})


func _garrafa(pos: Vector3) -> void:
	# a garrafa BEBA-ME caída, boiando (vidro com rolha e etiqueta)
	var b := KitCenario.colocar(self, "garrafa", pos + Vector3(0, -0.85, 0), Vector3.ONE * 2.6, 0.6, "animavel")
	_boiando.append({"no": b, "base": b.position, "fase": randf() * TAU, "amplitude": 0.1})


func _xicara_barco(pos: Vector3) -> void:
	var b := _boia(pos, 0.1)
	var x := PropProcedural.new()
	x.tipo = PropProcedural.Tipo.XICARA
	x.tamanho = 2.4
	x.cor = Color(1, 0.75, 0.85)
	x.com_colisao = false
	b.add_child(x)
	# chão dentro da xícara (para ficar em pé "dentro" dela)
	var c := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 1.3
	cs.height = 0.9
	c.shape = cs
	c.position.y = 0.55
	b.add_child(c)


func _lampiao(pos: Vector3) -> void:
	var poste := CylinderMesh.new()
	poste.top_radius = 0.08
	poste.bottom_radius = 0.1
	poste.height = 2.4
	var n := Node3D.new()
	n.position = pos
	add_child(n)
	_assentar.append(n)
	_malha(n, poste, Vector3(0, 1.2, 0), M_MADEIRA)
	var luz := OmniLight3D.new()
	luz.light_color = Color(1.0, 0.75, 0.45)
	luz.light_energy = 2.0
	luz.omni_range = 7.0
	luz.position.y = 2.5
	n.add_child(luz)
	var bulbo := SphereMesh.new()
	bulbo.radius = 0.25
	bulbo.height = 0.5
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.78, 0.45)
	mat.emission_energy_multiplier = 3.0
	_malha(n, bulbo, Vector3(0, 2.5, 0), mat)


func _placa(texto: String, pos: Vector3) -> void:
	var l := Label3D.new()
	l.text = texto
	l.font = FONTE
	l.font_size = 64
	l.pixel_size = 0.006
	l.modulate = Color(1.0, 0.95, 0.82)
	l.outline_modulate = Color(0.3, 0.2, 0.45)
	l.outline_size = 16
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	add_child(l)


# ---------------- personagens ----------------

func _rato(pos: Vector3) -> void:
	var p := Personagem.new()
	if ResourceLoader.exists(CAMINHO_RATO):
		p.modelo = load(CAMINHO_RATO)
	else:
		BichoFeltro.criar(p, Color(0.6, 0.6, 0.65), Color(1, 0.7, 0.75), 0.55, true)
	p.escala = 0.5
	p.altura_pes = 0.48
	p.altura_balao = 1.4
	p.anim_parado = &"human_000093"
	p.anim_falando = &"human_000041"
	var pt: bool = MenuEstanteUI._pt()
	p.falas = PackedStringArray([
		"Ó Rato! Você sabe como sair desta lagoa?" if pt else "O Mouse! Do you know the way out of this pool?",
		"Nada de falar em gatos, por favor!" if pt else "No talking about cats, please!",
		"Nade até a margem — os outros bichos estão lá." if pt else "Swim to the shore — the other animals are there."])
	p.tom_voz = 520.0
	p.raio_conversa = 6.0
	p.position = pos
	add_child(p)
	_assentar.append(p)


func _praia() -> void:
	# a margem: três ilhas grandes de feltro emendadas (no lugar de uma caixa de areia)
	_ilha(Vector3(0, 0.6, 86.0), 11.0, 7)
	_ilha(Vector3(-17, 0.9, 92.0), 9.0, 8)
	_ilha(Vector3(17, 0.9, 92.0), 9.0, 9)
	var pt: bool = MenuEstanteUI._pt()
	# os bichos molhados esperando, em roda
	var bichos: Array = [
		["pato", 1.0, Vector3(-3.5, 0.6, 79.0)],
		["papagaio", 0.9, Vector3(3.0, 0.6, 79.5)],
		["pato", 0.75, Vector3(-1.8, 0.6, 82.8)],
	]
	for b: Array in bichos:
		var p := Personagem.new()
		p.position = b[2]
		p.rotation.y = PI
		p.altura_balao = float(b[1]) + 0.5
		p.falas = PackedStringArray(["Estou ensopado!" if pt else "I'm soaking wet!"])
		p.tom_voz = 380.0 + randf() * 200.0
		p.raio_conversa = 5.0
		p.intervalo = 9.0
		add_child(p)
		_assentar.append(p)
		BichoFeltro.modelo(p, b[0], b[1])
	# o Dodô: é a saída
	var dodo := Personagem.new()
	dodo.position = Vector3(0.5, 0.6, 81.0)
	dodo.rotation.y = PI
	dodo.altura_balao = 2.0
	dodo.falas = PackedStringArray([
		"A melhor maneira de se secar é uma Corrida em Comitê!" if pt
			else "The best thing to get us dry would be a Caucus-race!",
		"Venha! Todo mundo ganha!" if pt else "Come on! Everybody has won!"])
	dodo.tom_voz = 220.0
	dodo.raio_conversa = 8.0
	add_child(dodo)
	_assentar.append(dodo)
	BichoFeltro.modelo(dodo, "dodo", 1.5)
	var saida := MissionItem.new()
	saida.is_exit = true
	saida.bob_height = 0.0
	saida.spin_speed = 0.0
	saida.collision_layer = 0
	saida.collision_mask = 6
	saida.position = Vector3(0.5, 1.4, 79.5)
	_forma_caixa(saida, Vector3(4.0, 2.5, 3.0))
	add_child(saida)
	var brilho := OmniLight3D.new()
	brilho.light_color = Color(1.0, 0.85, 0.5)
	brilho.light_energy = 1.5
	brilho.omni_range = 5.0
	brilho.position = Vector3(0.5, 2.0, 80.0)
	add_child(brilho)


func _alice_no_horizonte() -> void:
	if not ResourceLoader.exists(CAMINHO_ALICE):
		return
	var alice := (load(CAMINHO_ALICE) as PackedScene).instantiate() as Node3D
	alice.scale = Vector3.ONE * 30.0
	alice.position = Vector3(14, 9.0, 128)
	alice.rotation.y = PI  # olhando para a lagoa
	add_child(alice)


## Morros de feltro recortado em camadas em volta da lagoa (a Alice fica na frente deles).
func _fundo() -> void:
	var f := CenarioRecortes.new()
	f.position = Vector3(0, 0, 50)
	f.raios = PackedFloat32Array([88.0, 112.0, 140.0])
	f.alturas = PackedFloat32Array([10.0, 18.0, 30.0])
	f.cores = PackedColorArray([Color(0.45, 0.68, 0.45), Color(0.58, 0.7, 0.72), Color(0.75, 0.74, 0.9)])
	f.base_y = -6.0
	add_child(f)


func _assentar_tudo() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var espaco := get_world_3d().direct_space_state
	for n: Node3D in _assentar:
		if not is_instance_valid(n):
			continue
		var de: Vector3 = n.global_position + Vector3.UP * 8.0
		var q := PhysicsRayQueryParameters3D.create(de, de + Vector3.DOWN * 20.0, 1)
		var hit := espaco.intersect_ray(q)
		if not hit.is_empty():
			n.global_position.y = (hit["position"] as Vector3).y + (1.0 if n is MissionItem else 0.0)


# ---------------- lágrimas ----------------

func _lagrima() -> void:
	var nino := get_tree().get_first_node_in_group("sonhador") as Node3D
	if nino == null:
		return
	if nino.global_position.z < LAGRIMAS_Z.x - 4.0 or nino.global_position.z > LAGRIMAS_Z.y:
		return
	var alvo := Vector3(nino.global_position.x + randf_range(-5.0, 5.0), 0.0,
		clampf(nino.global_position.z + randf_range(-3.0, 7.0), LAGRIMAS_Z.x, LAGRIMAS_Z.y))
	# sombra de aviso
	var sombra := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 2.4
	disco.bottom_radius = 2.4
	disco.height = 0.02
	sombra.mesh = disco
	var ms := StandardMaterial3D.new()
	ms.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ms.albedo_color = Color(0.1, 0.15, 0.35, 0.0)
	ms.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sombra.material_override = ms
	sombra.position = alvo + Vector3.UP * 0.18
	sombra.scale = Vector3(0.3, 1, 0.3)
	add_child(sombra)
	var gota := MeshInstance3D.new()
	var esf := SphereMesh.new()
	esf.radius = 1.1
	esf.height = 2.8
	gota.mesh = esf
	gota.material_override = M_VIDRO
	gota.position = alvo + Vector3.UP * 34.0
	add_child(gota)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sombra, "scale", Vector3.ONE, 1.3)
	tw.tween_property(ms, "albedo_color:a", 0.45, 1.3)
	tw.tween_property(gota, "position:y", 0.0, 1.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func() -> void:
		_respingo(alvo)
		sombra.queue_free()
		gota.queue_free())


func _respingo(pos: Vector3) -> void:
	Efeitos.fiapos(self, pos + Vector3.UP * 0.2, Vector3.UP, Color(0.75, 0.88, 1.0))
	var anel := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.9
	t.outer_radius = 1.1
	anel.mesh = t
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.9, 0.95, 1.0, 0.8)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	anel.material_override = m
	anel.position = pos + Vector3.UP * 0.15
	add_child(anel)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(anel, "scale", Vector3(4, 1, 4), 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.9)
	tw.chain().tween_callback(anel.queue_free)
	var som := AudioStreamPlayer3D.new()
	som.stream = SOM_SPLASH
	som.bus = &"Efeitos"
	som.pitch_scale = 0.6
	som.position = pos
	add_child(som)
	som.play()
	som.finished.connect(som.queue_free)
	for grupo: StringName in [&"sonhador", &"mel"]:
		for n: Node in get_tree().get_nodes_in_group(grupo):
			var d := n as DreamerController
			if d and d.global_position.distance_to(pos) < 3.0:
				d.empurrar(pos, 7.0)
