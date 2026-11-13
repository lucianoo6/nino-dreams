class_name ShelfBook
extends Area3D
## Um livro na estante. Pula ao passar o mouse/seleção, e voa até as mãos do Nino ao ser escolhido.

signal hovered(book: ShelfBook)
signal clicked(book: ShelfBook)

const FELTRO := preload("res://materials/feltro.tres")
## Capa de veludo (tingida com a cor do livro) e faixa de linha dourada na lombada.
const CAPA := preload("res://materials/pbr/veludo_vermelho.tres")
const FAIXA := preload("res://materials/pbr/linha_dourada.tres")

var data: BookData
var rest_position: Vector3

var _visual: Node3D
var _selected: bool = false
var _hop_tween: Tween
var _transform_estante: Transform3D


func setup(livro: BookData, altura: float, largura: float, profundidade: float) -> void:
	data = livro
	_visual = Node3D.new()
	add_child(_visual)

	var capa := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(largura, altura, profundidade)
	capa.mesh = box
	var mat_capa := CAPA.duplicate() as StandardMaterial3D
	mat_capa.albedo_color = livro.cor_da_capa
	capa.material_override = mat_capa
	capa.position.y = altura / 2.0
	_visual.add_child(capa)

	# Faixinha costurada na lombada (mais clara), virada para a câmera.
	var faixa := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(largura * 1.02, altura * 0.12, 0.01)
	faixa.mesh = fb
	faixa.material_override = FAIXA
	faixa.position = Vector3(0.0, altura * 0.72, profundidade / 2.0 + 0.003)
	_visual.add_child(faixa)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	col.shape = shape
	col.position.y = altura / 2.0
	add_child(col)

	_criar_marcador(altura, largura, profundidade)
	input_ray_pickable = true
	mouse_entered.connect(func() -> void: hovered.emit(self))
	input_event.connect(_on_input_event)


func _ready() -> void:
	rest_position = position


## Fitinha de marcador saindo do topo: mostra que o livro já foi começado (dourada se terminado).
func _criar_marcador(altura: float, largura: float, profundidade: float) -> void:
	var lidos: int = GameState.capitulos_concluidos(data).size()
	if lidos == 0:
		return
	var terminado: bool = GameState.livro_terminado(data)
	var fita := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(largura * 0.35, 0.12, 0.006)
	fita.mesh = bm
	fita.material_override = FELTRO
	fita.set_instance_shader_parameter("tint", Color(1.0, 0.82, 0.3) if terminado else Color(0.85, 0.2, 0.3))
	fita.position = Vector3(0.0, altura + 0.04, profundidade * 0.3)
	_visual.add_child(fita)


## Texto curto de progresso, ex.: "capítulo 3 de 12".
func progresso_texto() -> String:
	var total: int = data.total_capitulos()
	if total <= 1:
		return ""
	if GameState.livro_terminado(data):
		return "lido até o FIM ✨"
	return "capítulo %d de %d" % [GameState.proximo_capitulo(data), total]


func _on_input_event(_cam: Node, event: InputEvent, _pos: Vector3, _n: Vector3, _idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)


## Pulinho fofo com squash & stretch.
func hop() -> void:
	if _hop_tween:
		_hop_tween.kill()
	var base_y: float = 0.06 if _selected else 0.0
	_hop_tween = create_tween()
	_hop_tween.tween_property(_visual, "position:y", base_y + 0.12, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hop_tween.parallel().tween_property(_visual, "scale", Vector3(0.9, 1.12, 0.9), 0.12)
	_hop_tween.tween_property(_visual, "position:y", base_y, 0.35) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_hop_tween.parallel().tween_property(_visual, "scale", Vector3.ONE, 0.35) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func set_selected(valor: bool) -> void:
	if _selected == valor:
		return
	_selected = valor
	if valor:
		hop()
	else:
		var tw := create_tween()
		tw.tween_property(_visual, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_SINE)


## Voa até um ponto (as mãos do Nino), girando de leve. Use com await.
func voar_para(destino: Vector3, duracao: float = 0.9) -> void:
	if _hop_tween:
		_hop_tween.kill()
	_transform_estante = global_transform
	var meio: Vector3 = (global_position + destino) / 2.0 + Vector3.UP * 0.6
	var tw := create_tween()
	tw.tween_property(self, "global_position", meio, duracao * 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "rotation:y", PI, duracao)
	tw.tween_property(self, "global_position", destino, duracao * 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "scale", Vector3.ONE * 0.7, duracao * 0.5)
	await tw.finished


## Volta para o lugar na estante (quando o jogador desiste do livro).
func voltar(duracao: float = 0.7) -> void:
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "global_transform", _transform_estante, duracao)
	await tw.finished
	_selected = false
	set_selected(true)
