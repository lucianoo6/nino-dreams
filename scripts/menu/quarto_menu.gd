extends Node3D
## Tela inicial / escolha de fase: a estante de livros fofa em primeiro plano e o Nino na cama, desfocado ao fundo.
## Passar o mouse (ou o direcional) faz os livros pularem. Ao escolher:
##   1. o foco da câmera "passa" da estante para o Nino (rack focus);
##   2. o livro voa até as mãos dele;
##   3. ele lê a última linha da história em balbucio — e diz o grande "e FIM";
##   4. nuvens cobrem a tela e o sonho começa com a câmera descendo das nuvens até o Nino.

const PASTA_LIVROS := "res://data/livros/"
const FELTRO := preload("res://materials/feltro.tres")

@export_group("Estante")
@export var largura: float = 1.6
@export var profundidade: float = 0.3
@export var altura_prateleiras: PackedFloat32Array = PackedFloat32Array([0.5, 0.06])
@export var cor_madeira: Color = Color(0.62, 0.42, 0.3)

@export_group("Foco")
@export var foco_estante_distancia: float = 2.3
@export var foco_nino_distancia: float = 3.2
@export var duracao_rack_focus: float = 1.2

var _attrs: CameraAttributesPractical
var _livros: Array[ShelfBook] = []
var _indice: int = -1
var _ocupado: bool = false

@onready var _camera: Camera3D = $Camera3D
@onready var _nino: Node3D = $Nino
@onready var _maos: Marker3D = $Nino/MaosDoNino
@onready var _voz: BabbleVoice = $VozDoNino
@onready var _dialogo: BabbleDialog = $Dialogo
@onready var _titulo: Label3D = $TituloLivro
@onready var _estante: Node3D = $Estante


func _ready() -> void:
	get_viewport().physics_object_picking = true
	GameState.cutscene = false
	_attrs = _camera.attributes as CameraAttributesPractical
	if _attrs == null:
		_attrs = CameraAttributesPractical.new()
		_camera.attributes = _attrs
	_camera.look_at(Vector3(0.0, 0.62, -1.2))
	_construir_moveis()
	_construir_livros(_carregar_livros())
	_foco_na_estante(0.0)
	Transicao.descobrir(1.2)
	if not _livros.is_empty():
		_selecionar(0, false)


func _unhandled_input(event: InputEvent) -> void:
	if _ocupado or _livros.is_empty():
		return
	if event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_selecionar(wrapi(_indice + 1, 0, _livros.size()))
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_selecionar(wrapi(_indice - 1, 0, _livros.size()))
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		_escolher(_livros[_indice])


# ---------------- Livros ----------------

func _carregar_livros() -> Array[BookData]:
	var lista: Array[BookData] = []
	for arquivo: String in ResourceLoader.list_directory(PASTA_LIVROS):
		if not arquivo.ends_with(".tres"):
			continue
		var livro := load(PASTA_LIVROS + arquivo) as BookData
		if livro and livro.em_dominio_publico_mundial():
			lista.append(livro)
	lista.sort_custom(func(a: BookData, b: BookData) -> bool: return a.ano_publicacao < b.ano_publicacao)
	return lista


func _construir_livros(lista: Array[BookData]) -> void:
	var margem: float = 0.08
	var prateleira: int = 0
	var x: float = -largura / 2.0 + margem
	for i in lista.size():
		# Tamanhos variados (mas sempre iguais para o mesmo livro) para parecer uma estante de verdade.
		var semente: int = hash(lista[i].id)
		var largura_livro: float = 0.07 + float(absi(semente) % 5) * 0.012
		var altura_livro: float = 0.3 + float(absi(semente >> 3) % 5) * 0.02
		if x + largura_livro > largura / 2.0 - margem:
			prateleira += 1
			x = -largura / 2.0 + margem
			if prateleira >= altura_prateleiras.size():
				push_warning("Estante cheia: aumente a largura ou adicione prateleiras.")
				break
		var livro := ShelfBook.new()
		livro.setup(lista[i], altura_livro, largura_livro, profundidade * 0.8)
		livro.position = Vector3(x + largura_livro / 2.0, altura_prateleiras[prateleira] + 0.02, 0.0)
		livro.rotation.z = deg_to_rad(float(semente % 5) * 0.8) # inclinadinhos, feitos à mão
		_estante.add_child(livro)
		livro.hovered.connect(_on_livro_hover)
		livro.clicked.connect(_escolher)
		_livros.append(livro)
		x += largura_livro + 0.012


func _on_livro_hover(livro: ShelfBook) -> void:
	if _ocupado:
		return
	_selecionar(_livros.find(livro))


func _selecionar(i: int, com_pulo: bool = true) -> void:
	if i < 0 or i == _indice:
		if i >= 0 and com_pulo:
			_livros[i].hop()
		return
	if _indice >= 0:
		_livros[_indice].set_selected(false)
	_indice = i
	var livro: ShelfBook = _livros[i]
	livro.set_selected(true)
	_voz.blip(livro.data.titulo.substr(0, 1), 1.3)
	_titulo.text = "%s\n%s" % [livro.data.titulo, livro.data.autor]
	_titulo.global_position = livro.global_position + Vector3(0.0, 0.55, 0.1)
	_titulo.visible = true


# ---------------- Escolha: ler, "e FIM", nuvens ----------------

func _escolher(livro: ShelfBook) -> void:
	if _ocupado:
		return
	_ocupado = true
	GameState.cutscene = true
	_titulo.visible = false
	livro.hop()
	await get_tree().create_timer(0.25).timeout

	_foco_no_nino(duracao_rack_focus)
	await livro.voar_para(_maos.global_position, 1.0)

	var linha: String = livro.data.ultima_linha if not livro.data.ultima_linha.is_empty() else "…"
	await _dialogo.falar(linha, _voz)
	await _dialogo.dizer_fim(_voz)

	# Nino boceja, a câmera se aproxima devagar e as nuvens tomam conta.
	var tw := create_tween()
	tw.tween_property(_camera, "fov", _camera.fov * 0.7, 1.6).set_trans(Tween.TRANS_SINE)
	await Transicao.cobrir(1.6).finished
	GameState.entrar_no_livro(livro.data)


# ---------------- Rack focus (desfoque) ----------------

func _foco_na_estante(duracao: float) -> void:
	_attrs.dof_blur_amount = 0.12
	_attrs.dof_blur_near_enabled = false
	_attrs.dof_blur_far_enabled = true
	_attrs.dof_blur_far_transition = 1.4
	if duracao <= 0.0:
		_attrs.dof_blur_far_distance = foco_estante_distancia
		return
	create_tween().tween_property(_attrs, "dof_blur_far_distance", foco_estante_distancia, duracao)


func _foco_no_nino(duracao: float) -> void:
	_attrs.dof_blur_near_enabled = true
	_attrs.dof_blur_near_distance = 0.01
	_attrs.dof_blur_near_transition = 1.2
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(_attrs, "dof_blur_far_distance", 30.0, duracao)
	tw.tween_property(_attrs, "dof_blur_near_distance", foco_nino_distancia, duracao)
	tw.chain().tween_callback(func() -> void: _attrs.dof_blur_far_enabled = false)


# ---------------- Móveis de feltro ----------------

func _construir_moveis() -> void:
	var espessura: float = 0.035
	var topo: float = altura_prateleiras[0] + 0.44
	# Laterais
	for lado: float in [-1.0, 1.0]:
		_caixa(_estante, Vector3(espessura, topo, profundidade),
			Vector3(lado * (largura / 2.0 + espessura / 2.0), topo / 2.0, 0.0), cor_madeira)
	# Prateleiras + tampo
	for y: float in altura_prateleiras:
		_caixa(_estante, Vector3(largura, espessura, profundidade), Vector3(0.0, y, 0.0), cor_madeira)
	_caixa(_estante, Vector3(largura + espessura * 2.0, espessura, profundidade * 1.05),
		Vector3(0.0, topo, 0.0), cor_madeira.darkened(0.1))
	# Fundo (retalho xadrez — por enquanto liso)
	_caixa(_estante, Vector3(largura, topo, 0.02), Vector3(0.0, topo / 2.0, -profundidade / 2.0),
		Color(0.85, 0.7, 0.75))


func _caixa(pai: Node3D, tamanho: Vector3, pos: Vector3, cor: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tamanho
	mi.mesh = bm
	mi.material_override = FELTRO
	mi.set_instance_shader_parameter("tint", cor)
	mi.position = pos
	pai.add_child(mi)
	return mi
