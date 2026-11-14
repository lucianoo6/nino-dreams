extends Fase
## Alice, Capítulo 3 — Uma Corrida Maluca e uma História Comprida.
## Planetinha-campo onde os bichos (Dodô, Pato, Papagaio, Aguiazinha, Caranguejo) correm em CÍRCULOS sem parar,
## cada um no seu ritmo — e esbarram em quem estiver no caminho. Achar os 3 CONFEITOS de prêmio:
##   1) na pista da corrida (do outro lado do planeta);
##   2) no alto da "história comprida" do Rato — uma rampa em espiral feita das palavras da história,
##      que vai afinando como um rabo de rato (como no livro!);
##   3) numa luazinha, alcançada pelo carretel-lançador.

const CARRETEL := preload("res://scenes/level/Carretel.tscn")
const SOM_CONFEITO := preload("res://assets/audio/sfx/botao_plim_b.mp3")
const FONTE := preload("res://assets/fonts/Fredoka-Bold.woff2")
const M_GRAMA := preload("res://materials/pbr/feltro_verde.tres")
const M_LUA := preload("res://materials/pbr/feltro_creme.tres")
const M_PAPEL := preload("res://materials/pbr/papel.tres")
const M_PENA := preload("res://materials/pbr/tule_branco.tres")
const M_OURO := preload("res://materials/pbr/linha_dourada.tres")
const RATO := "res://assets/models/personagens/rato.glb"

const RAIO: float = 10.0
## Direções (a partir do centro do planeta) de cada coisa importante.
const DIR_RABO := Vector3(0.75, 0.6, -0.1)
const DIR_CARRETEL := Vector3(-0.7, 0.75, 0.2)
const DIR_CONFEITO_PISTA := Vector3(0.0, -0.05, 1.0)

## Palavras da história do Rato (o rabo), do começo largo ao fim fininho. Tradução livre do poema de 1865.
const HISTORIA_PT := ["Fúria", "disse", "a um", "rato", "que", "encontrou", "na casa:", "“Vamos", "os dois",
	"ao tribunal:", "eu vou", "te", "processar!", "Não", "aceito", "não!", "Temos", "que", "ter", "um", "julga-",
	"mento", "hoje", "de", "manhã”…"]
const HISTORIA_EN := ["Fury", "said", "to a", "mouse,", "that", "he met", "in the", "house,", "“Let us", "both", "go",
	"to law:", "I will", "prose-", "cute", "you.", "Come,", "I'll", "take", "no", "denial;", "we", "must", "have",
	"a trial”…"]

var _corredores: Array[Dictionary] = []  # {pivo, velocidade, corpo}
var _planeta: Planetoid


func _ready() -> void:
	_planeta = Planetoid.new()
	_planeta.name = "Campo"
	_planeta.raio = RAIO
	_planeta.alcance_gravidade = 14.0
	_planeta.material_superficie = M_GRAMA
	add_child(_planeta)
	_pista()
	_corrida()
	_rabo_da_historia()
	_luazinha()
	_enfeites()
	super._ready()


func _physics_process(delta: float) -> void:
	var nino := get_tree().get_first_node_in_group("sonhador") as DreamerController
	for c: Dictionary in _corredores:
		var pivo := c["pivo"] as Node3D
		pivo.rotate_y(float(c["velocidade"]) * delta)
		var corpo := c["corpo"] as Node3D
		corpo.position.x = RAIO + absf(sin(Time.get_ticks_msec() * 0.012 * float(c["velocidade"]))) * 0.25
		if nino and nino.global_position.distance_to(corpo.global_position) < 1.1:
			nino.empurrar(corpo.global_position, 6.0)


# ---------------- utilidades ----------------

func _no_planeta(n: Node3D, dir: Vector3, elevacao: float = 0.0, giro: float = 0.0) -> Node3D:
	var up: Vector3 = dir.normalized()
	var frente: Vector3 = up.cross(Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD).normalized()
	n.global_basis = Basis.looking_at(frente, up).rotated(up, giro)
	n.global_position = _planeta.ponto_na_superficie(up, elevacao)
	return n


func _malha(pai: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.position = pos
	m.material_override = mat
	pai.add_child(m)
	return m


func _confeito(onde: Node3D, local: Vector3, cor: Color) -> MissionItem:
	var item := MissionItem.new()
	item.som = SOM_CONFEITO
	item.collision_layer = 8
	item.collision_mask = 6
	item.position = local
	var c := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.7
	c.shape = esfera
	item.add_child(c)
	var visual := Node3D.new()
	visual.name = "Visual"
	visual.position.y = 0.6
	item.add_child(visual)
	# bala embrulhada: bolinha brilhante + duas "orelhinhas" de papel torcido
	var doce := StandardMaterial3D.new()
	doce.albedo_color = cor
	doce.roughness = 0.15
	doce.clearcoat_enabled = true
	doce.emission_enabled = true
	doce.emission = cor * 0.35
	var bola := SphereMesh.new()
	bola.radius = 0.32
	bola.height = 0.64
	_malha(visual, bola, Vector3.ZERO, doce)
	for lado: float in [-1.0, 1.0]:
		var ponta := CylinderMesh.new()
		ponta.top_radius = 0.2
		ponta.bottom_radius = 0.0
		ponta.height = 0.3
		var p := _malha(visual, ponta, Vector3(lado * 0.42, 0, 0), doce)
		p.rotation.z = -lado * PI / 2.0
	var luz := OmniLight3D.new()
	luz.light_color = cor
	luz.light_energy = 0.8
	luz.omni_range = 2.5
	visual.add_child(luz)
	onde.add_child(item)
	return item


# ---------------- a pista e a corrida ----------------

func _pista() -> void:
	# a linha da pista (costura em volta do "equador")
	var c := CosturaPlaneta.new()
	add_child(c)
	c.planeta = c.get_path_to(_planeta)
	c.eixo = Vector3.UP
	c.pontos = 90
	c.cor = Color(1.0, 0.95, 0.85)
	# confeito 1, na pista, do outro lado
	var ancora := Node3D.new()
	add_child(ancora)
	_no_planeta(ancora, DIR_CONFEITO_PISTA, 0.0)
	_confeito(ancora, Vector3.ZERO, Color(1.0, 0.35, 0.5))


func _corrida() -> void:
	var pt: bool = MenuEstanteUI._pt()
	var bichos: Array = [
		["dodo", 1.4, 0.55],
		["pato", 1.0, 0.8],
		["papagaio", 0.9, 0.7],
		["pato", 0.7, 0.95],
		["papagaio", 0.75, -0.6],   # esse corre ao contrário!
	]
	for i in bichos.size():
		var b: Array = bichos[i]
		# pivô no centro do planeta girando em volta do Y do mundo; o bicho fica no "equador" (a pista)
		var pivo := Node3D.new()
		pivo.rotation.y = i * TAU / bichos.size()
		add_child(pivo)
		var corpo := Node3D.new()
		var vel: float = b[2]
		# "para cima" do bicho = para fora do planeta (+X); frente = sentido em que corre
		corpo.basis = Basis.looking_at(Vector3.FORWARD if vel > 0.0 else Vector3.BACK, Vector3.RIGHT)
		corpo.position = Vector3(RAIO, 0, 0)
		pivo.add_child(corpo)
		BichoFeltro.modelo(corpo, b[0], b[1])
		_corredores.append({"pivo": pivo, "velocidade": vel, "corpo": corpo})
	# o Dodô explica as regras na largada (perto do Nino)
	var dodo := Personagem.new()
	add_child(dodo)
	_no_planeta(dodo, Vector3(0.25, 1.0, 0.35), 0.0)
	dodo.altura_balao = 2.0
	dodo.falas = PackedStringArray([
		"Uma Corrida Maluca! Corra em volta, como quiser!" if pt else "A Caucus-race! Run round, any way you like!",
		"Todo mundo ganhou, e todos ganham prêmios!" if pt else "Everybody has won, and all must have prizes!",
		"Ache os 3 confeitos de prêmio!" if pt else "Find the 3 prize comfits!"])
	dodo.tom_voz = 220.0
	dodo.raio_conversa = 6.0
	BichoFeltro.modelo(dodo, "dodo", 1.5)


# ---------------- a história comprida (rabo de rato) ----------------

func _rabo_da_historia() -> void:
	var base := Node3D.new()
	base.name = "RaboDaHistoria"
	add_child(base)
	_no_planeta(base, DIR_RABO, 0.0)
	# pena de escrever espetada no chão: o "poste" da espiral
	var pena := CylinderMesh.new()
	pena.top_radius = 0.05
	pena.bottom_radius = 0.18
	pena.height = 13.0
	_malha(base, pena, Vector3(0, 6.5, 0), M_OURO)
	var plumas := SphereMesh.new()
	plumas.radius = 1.0
	plumas.height = 5.0
	var pl := _malha(base, plumas, Vector3(0, 12.5, 0), M_PENA)
	pl.scale = Vector3(0.5, 1.0, 0.25)
	var palavras: Array = HISTORIA_PT if MenuEstanteUI._pt() else HISTORIA_EN
	var n: int = palavras.size()
	var topo := Vector3.ZERO
	for i in n:
		var t: float = float(i) / float(n - 1)
		var ang: float = i * 0.55
		var raio: float = lerpf(2.6, 1.3, t)
		var altura: float = 0.55 + i * 0.45
		var largura: float = lerpf(1.9, 0.9, t)
		var degrau := StaticBody3D.new()
		degrau.position = Vector3(cos(ang) * raio, altura, sin(ang) * raio)
		degrau.rotation.y = -ang
		base.add_child(degrau)
		var bm := BoxMesh.new()
		bm.size = Vector3(0.9, 0.16, largura)
		_malha(degrau, bm, Vector3.ZERO, M_PAPEL)
		var c := CollisionShape3D.new()
		var s := BoxShape3D.new()
		s.size = Vector3(1.0, 0.2, largura)
		c.shape = s
		degrau.add_child(c)
		var l := Label3D.new()
		l.text = palavras[i]
		l.font = FONTE
		l.font_size = int(lerpf(72.0, 34.0, t))
		l.pixel_size = 0.005
		l.modulate = Color(0.25, 0.18, 0.35)
		l.outline_size = 0
		l.position = Vector3(0, 0.09, 0)
		l.rotation = Vector3(-PI / 2.0, PI / 2.0, 0)
		l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
		degrau.add_child(l)
		topo = degrau.position
	_confeito(base, topo + Vector3(0, 0.2, 0), Color(0.4, 0.7, 1.0))
	# o Rato contando a história, ao pé da espiral
	var rato := Personagem.new()
	if ResourceLoader.exists(RATO):
		rato.modelo = load(RATO)
	rato.escala = 0.5
	rato.altura_pes = 0.48
	rato.altura_balao = 1.4
	rato.anim_parado = &"human_000093"
	rato.anim_falando = &"human_000041"
	var pt: bool = MenuEstanteUI._pt()
	rato.falas = PackedStringArray([
		"A minha história é longa e triste!" if pt else "Mine is a long and a sad tale!",
		"Suba pela minha história — o prêmio está lá no alto!" if pt else "Climb my tale — the prize is at the top!"])
	rato.tom_voz = 520.0
	rato.raio_conversa = 5.0
	rato.position = Vector3(3.2, 0.0, 1.5)
	base.add_child(rato)


# ---------------- luazinha com o terceiro confeito ----------------

func _luazinha() -> void:
	var lua := Planetoid.new()
	lua.name = "Luazinha"
	lua.raio = 3.0
	lua.alcance_gravidade = 4.0
	lua.prioridade = 1
	lua.material_superficie = M_LUA
	lua.position = Vector3(-21.0, 15.0, 6.0)
	add_child(lua)
	var pouso := Marker3D.new()
	pouso.name = "PousoLua"
	add_child(pouso)
	pouso.global_position = lua.global_position + Vector3(0.4, 3.4, 0.4).normalized() * 3.6
	# ida
	var ida := CARRETEL.instantiate() as SpoolLauncher
	add_child(ida)
	_no_planeta(ida, DIR_CARRETEL, 0.0)
	ida.destino = ida.get_path_to(pouso)
	ida.altura_arco = 8.0
	# volta
	var volta_pouso := Marker3D.new()
	add_child(volta_pouso)
	volta_pouso.global_position = _planeta.ponto_na_superficie(Vector3(-0.3, 1.0, 0.1), 0.6)
	var volta := CARRETEL.instantiate() as SpoolLauncher
	add_child(volta)
	var dir_volta: Vector3 = Vector3(0.6, 0.2, -0.75).normalized()
	volta.global_basis = Basis.looking_at(dir_volta.cross(Vector3.RIGHT).normalized(), dir_volta)
	volta.global_position = lua.global_position + dir_volta * 3.0
	volta.destino = volta.get_path_to(volta_pouso)
	volta.altura_arco = 8.0
	# o confeito no "polo" de baixo da luazinha (tem que dar a volta nela)
	var ancora := Node3D.new()
	add_child(ancora)
	var dir_c: Vector3 = Vector3(-0.5, -0.8, -0.3).normalized()
	var frente: Vector3 = dir_c.cross(Vector3.RIGHT).normalized()
	ancora.global_basis = Basis.looking_at(frente, dir_c)
	ancora.global_position = lua.global_position + dir_c * 3.0
	_confeito(ancora, Vector3.ZERO, Color(1.0, 0.8, 0.25))


# ---------------- enfeites ----------------

func _enfeites() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	for i in 22:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		if absf(dir.normalized().y) < 0.15:
			continue  # deixa a pista livre
		if dir.normalized().dot(DIR_RABO.normalized()) > 0.9 or dir.normalized().dot(DIR_CARRETEL.normalized()) > 0.92:
			continue
		var p := PropProcedural.new()
		p.tipo = PropProcedural.Tipo.FLOR if i % 3 != 0 else PropProcedural.Tipo.MORRINHO
		p.tamanho = rng.randf_range(0.5, 0.9) if p.tipo == PropProcedural.Tipo.FLOR else rng.randf_range(0.8, 1.4)
		p.cor = [Color(1, 0.55, 0.65), Color(1, 0.85, 0.35), Color(0.7, 0.6, 1.0), Color(0.5, 0.75, 0.45)][i % 4]
		p.semente = i
		p.com_colisao = p.tipo == PropProcedural.Tipo.MORRINHO
		add_child(p)
		_no_planeta(p, dir, -0.05, rng.randf() * TAU)
	# nuvens de algodão em volta
	for i in 12:
		var ang: float = i * TAU / 12.0 + rng.randf() * 0.3
		var nuvem := PropProcedural.new()
		nuvem.tipo = PropProcedural.Tipo.NUVEM
		nuvem.tamanho = rng.randf_range(2.0, 3.5)
		nuvem.semente = 100 + i
		nuvem.com_colisao = false
		nuvem.position = Vector3(cos(ang) * 30.0, rng.randf_range(-10.0, 12.0), sin(ang) * 30.0)
		add_child(nuvem)
	# bandeirinhas de largada
	var faixa := Label3D.new()
	faixa.text = "LARGADA ✿ CHEGADA ✿ LARGADA" if MenuEstanteUI._pt() else "START ✿ FINISH ✿ START"
	faixa.font = FONTE
	faixa.font_size = 72
	faixa.pixel_size = 0.006
	faixa.modulate = Color(1.0, 0.95, 0.82)
	faixa.outline_modulate = Color(0.55, 0.2, 0.35)
	faixa.outline_size = 16
	faixa.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	faixa.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
	add_child(faixa)
	faixa.global_position = Vector3(0, RAIO + 4.0, 0)
