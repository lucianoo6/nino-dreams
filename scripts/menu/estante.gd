class_name Estante
extends Node3D
## Estante alta de madeira, LOTADA de livros. Os livros jogáveis (BookData) ficam na prateleira do meio,
## à altura dos olhos; o resto são livros decorativos com títulos de obras em domínio público.
## Um rastro de faíscas douradas passeia entre as prateleiras.

const MADEIRA := preload("res://materials/pbr/madeira.tres")
const FUNDO := preload("res://materials/pbr/cotele_vinho.tres")

const TITULOS_DECORATIVOS: Array[String] = [
	"Contos de Andersen", "Contos de Grimm", "Fábulas de Esopo", "As Mil e Uma Noites", "Viagens de Gulliver",
	"O Jardim Secreto", "A Bela e a Fera", "O Gato de Botas", "Chapeuzinho Vermelho", "A Fênix e o Tapete",
	"Vinte Mil Léguas", "Os Músicos de Bremen", "O Patinho Feio", "O Soldadinho de Chumbo", "Lendas do Folclore",
	"Saci-Pererê", "A Volta ao Mundo", "Robinson Crusoé", "A Ilha do Tesouro", "Heidi", "Pollyanna",
	"Mulherzinhas", "Através do Espelho", "O Cavaleiro sem Cabeça", "Contos de Perrault", "A Pequena Sereia",
]
const CORES: Array[Color] = [
	Color(0.55, 0.12, 0.16), Color(0.14, 0.2, 0.42), Color(0.13, 0.36, 0.24), Color(0.78, 0.55, 0.18),
	Color(0.12, 0.42, 0.45), Color(0.4, 0.18, 0.4), Color(0.45, 0.28, 0.16), Color(0.86, 0.8, 0.66),
	Color(0.7, 0.3, 0.2), Color(0.25, 0.3, 0.5),
]

@export var largura: float = 1.25
@export var altura_total: float = 2.0
@export var profundidade: float = 0.32
## Altura do topo de cada prateleira (de baixo para cima).
@export var prateleiras: PackedFloat32Array = PackedFloat32Array([0.12, 0.6, 1.08, 1.56])
## Em qual prateleira ficam os livros jogáveis.
@export var prateleira_jogaveis: int = 2
@export var semente: int = 7

var livros: Array[ShelfBook] = []
var _seguidor: PathFollow3D
var _brilho_selecao: GPUParticles3D
var _rng := RandomNumberGenerator.new()


func construir(jogaveis: Array[BookData]) -> void:
	_rng.seed = semente
	_moveis()
	var nenhum: Array[BookData] = []
	for i in prateleiras.size():
		_encher(i, jogaveis if i == prateleira_jogaveis else nenhum)
	_faiscas()


func _process(delta: float) -> void:
	if _seguidor:
		_seguidor.progress_ratio = fmod(_seguidor.progress_ratio + delta * 0.07, 1.0)


## Faíscas extras em volta do livro selecionado.
func destacar(livro: ShelfBook) -> void:
	if _brilho_selecao == null or livro == null:
		return
	_brilho_selecao.global_position = livro.global_position + Vector3(0, livro.altura * 0.5, 0)
	_brilho_selecao.restart()


# ---------------- móveis ----------------

func _moveis() -> void:
	var e: float = 0.035
	for lado: float in [-1.0, 1.0]:
		_caixa(Vector3(e, altura_total, profundidade), Vector3(lado * (largura + e) / 2.0, altura_total / 2.0, 0), MADEIRA)
	for y: float in prateleiras:
		_caixa(Vector3(largura, e, profundidade), Vector3(0, y - e / 2.0, 0), MADEIRA)
	_caixa(Vector3(largura + e * 2.6, e * 1.4, profundidade * 1.08), Vector3(0, altura_total, 0.005), MADEIRA)
	_caixa(Vector3(largura, altura_total, 0.02), Vector3(0, altura_total / 2.0, -profundidade / 2.0), FUNDO)
	# rodapé
	_caixa(Vector3(largura + e * 2, prateleiras[0] - e, profundidade * 0.95), Vector3(0, (prateleiras[0] - e) / 2.0, 0.01),
		MADEIRA)


func _caixa(tamanho: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tamanho
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi


# ---------------- livros ----------------

func _encher(indice: int, jogaveis: Array[BookData]) -> void:
	var y: float = prateleiras[indice]
	var espaco: float = (prateleiras[indice + 1] if indice + 1 < prateleiras.size() else altura_total) - y - 0.035
	var x: float = -largura / 2.0 + 0.012
	var fim: float = largura / 2.0 - 0.012
	# os jogáveis entram mais ou menos no meio da prateleira
	var largura_jogaveis: float = jogaveis.size() * 0.085
	var inicio_jogaveis: float = -largura_jogaveis / 2.0 + 0.1
	var colocados: bool = jogaveis.is_empty()
	var variacao: int = indice * 7
	while x < fim - 0.04:
		if not colocados and x >= inicio_jogaveis:
			for livro: BookData in jogaveis:
				var w: float = 0.072 + float(absi(hash(livro.id)) % 3) * 0.006
				var h: float = minf(espaco * 0.9, 0.36 + float(absi(hash(livro.id) >> 4) % 4) * 0.015)
				var sb := ShelfBook.new()
				sb.setup(livro, h, w, profundidade * 0.82, variacao)
				sb.position = Vector3(x + w / 2.0, y, 0.02)
				add_child(sb)
				livros.append(sb)
				x += w + 0.004
				variacao += 1
			colocados = true
			continue
		var w2: float = _rng.randf_range(0.045, 0.085)
		if x + w2 > fim:
			break
		var h2: float = minf(espaco * 0.92, _rng.randf_range(0.28, 0.42))
		var no := Node3D.new()
		no.position = Vector3(x + w2 / 2.0, y, _rng.randf_range(-0.01, 0.02))
		add_child(no)
		var titulo: String = TITULOS_DECORATIVOS[_rng.randi() % TITULOS_DECORATIVOS.size()] \
			if _rng.randf() < 0.75 else ""
		LivroVisual.montar(no, titulo, CORES[_rng.randi() % CORES.size()], w2, h2, profundidade * 0.8, variacao)
		variacao += 1
		x += w2 + 0.003


# ---------------- faíscas ----------------

func _faiscas() -> void:
	var caminho := Path3D.new()
	var curva := Curve3D.new()
	var z: float = profundidade / 2.0 + 0.08
	var pontos: Array[Vector3] = []
	for i in range(prateleiras.size() - 1, -1, -1):  # de cima para baixo, serpenteando
		var y: float = prateleiras[i] + 0.22
		var l: float = largura / 2.0 + 0.05
		var ida: bool = i % 2 == 0
		pontos.append(Vector3(-l if ida else l, y + 0.05, z))
		pontos.append(Vector3(0, y - 0.06, z + 0.04))
		pontos.append(Vector3(l if ida else -l, y + 0.05, z))
	for p: Vector3 in pontos:
		curva.add_point(p, Vector3(-0.15, 0, 0), Vector3(0.15, 0, 0))
	curva.add_point(pontos[0])
	caminho.curve = curva
	add_child(caminho)
	_seguidor = PathFollow3D.new()
	_seguidor.loop = true
	caminho.add_child(_seguidor)
	_seguidor.add_child(_particulas(260, 3.2, Vector3(0.015, 0.015, 0.015)))
	_brilho_selecao = _particulas(60, 1.0, Vector3(0.05, 0.18, 0.05))
	_brilho_selecao.one_shot = true
	_brilho_selecao.explosiveness = 0.6
	add_child(_brilho_selecao)


static func _particulas(qtd: int, vida: float, caixa: Vector3) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = qtd
	p.lifetime = vida
	p.local_coords = false
	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proc.emission_box_extents = caixa
	proc.direction = Vector3(0, 1, 0)
	proc.spread = 180.0
	proc.initial_velocity_min = 0.01
	proc.initial_velocity_max = 0.06
	proc.gravity = Vector3(0, -0.03, 0)
	proc.scale_min = 0.4
	proc.scale_max = 1.3
	var rampa := Gradient.new()
	rampa.set_color(0, Color(1.0, 0.95, 0.7, 1.0))
	rampa.set_color(1, Color(1.0, 0.7, 0.2, 0.0))
	var tex_rampa := GradientTexture1D.new()
	tex_rampa.gradient = rampa
	proc.color_ramp = tex_rampa
	p.process_material = proc
	var quad := QuadMesh.new()
	quad.size = Vector2(0.03, 0.03)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(1.0, 0.85, 0.45) * 1.8  # bem acima de 1: o glow faz o brilho
	var ponto := GradientTexture2D.new()
	ponto.fill = GradientTexture2D.FILL_RADIAL
	ponto.fill_from = Vector2(0.5, 0.5)
	ponto.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	ponto.gradient = g
	mat.albedo_texture = ponto
	p.draw_pass_1 = quad
	p.material_override = mat
	return p
