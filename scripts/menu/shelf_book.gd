class_name ShelfBook
extends Area3D
## Um livro JOGÁVEL na estante. Ao ser selecionado sai um pouco para fora da prateleira e dá um pulinho;
## ao ser escolhido voa até as mãos do Nino.

signal hovered(book: ShelfBook)
signal clicked(book: ShelfBook)

const FITA := preload("res://materials/pbr/veludo_vermelho.tres")
const OURO := preload("res://materials/pbr/linha_dourada.tres")

var data: BookData
var rest_position: Vector3
var altura: float = 0.35

var _visual: Node3D
var _selected: bool = false
var _hop_tween: Tween
var _transform_estante: Transform3D


func setup(livro: BookData, alt: float, largura: float, profundidade: float, variacao: int) -> void:
	data = livro
	altura = alt
	_visual = Node3D.new()
	add_child(_visual)
	LivroVisual.montar(_visual, livro.titulo, livro.cor_da_capa, largura, alt, profundidade, variacao)
	_criar_marcador(alt, largura, profundidade)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(largura, alt, profundidade)
	col.shape = shape
	col.position.y = alt / 2.0
	add_child(col)
	input_ray_pickable = true
	mouse_entered.connect(func() -> void: hovered.emit(self))
	input_event.connect(_on_input_event)


func _ready() -> void:
	rest_position = position


## Fitinha de marcador saindo do topo: livro já começado (vermelha) ou lido até o fim (dourada).
func _criar_marcador(alt: float, largura: float, profundidade: float) -> void:
	if GameState.capitulos_concluidos(data).is_empty():
		return
	var fita := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(largura * 0.3, 0.1, 0.004)
	fita.mesh = bm
	fita.material_override = OURO if GameState.livro_terminado(data) else FITA
	fita.position = Vector3(0.0, alt + 0.03, profundidade * 0.3)
	_visual.add_child(fita)


## Texto curto de progresso, ex.: "capítulo 3 de 12".
func progresso_texto() -> String:
	var total: int = data.total_capitulos()
	if total <= 1:
		return "" if GameState.livro_jogavel(data) else "em breve — ainda sendo costurado 🧵"
	if not GameState.livro_jogavel(data):
		return "em breve — ainda sendo costurado 🧵"
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
	_hop_tween = create_tween()
	_hop_tween.tween_property(_visual, "position:y", 0.07, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hop_tween.parallel().tween_property(_visual, "scale", Vector3(0.92, 1.08, 0.92), 0.12)
	_hop_tween.tween_property(_visual, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_hop_tween.parallel().tween_property(_visual, "scale", Vector3.ONE, 0.35) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Selecionado: sai metade para fora da prateleira (em direção à câmera) e inclina um pouquinho.
func set_selected(valor: bool) -> void:
	if _selected == valor:
		return
	_selected = valor
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", rest_position + (Vector3(0, 0, 0.09) if valor else Vector3.ZERO), 0.3)
	tw.tween_property(self, "rotation:z", deg_to_rad(-4.0) if valor else 0.0, 0.3)
	if valor:
		hop()


## Voa até um ponto (as mãos do Nino), girando de leve. Use com await.
func voar_para(destino: Vector3, duracao: float = 0.9) -> void:
	if _hop_tween:
		_hop_tween.kill()
	_transform_estante = global_transform
	var meio: Vector3 = (global_position + destino) / 2.0 + Vector3.UP * 0.6
	var tw := create_tween()
	tw.tween_property(self, "global_position", meio, duracao * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "rotation:y", rotation.y + PI, duracao)
	tw.tween_property(self, "global_position", destino, duracao * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "scale", Vector3.ONE * 0.7, duracao * 0.5)
	await tw.finished


## Volta para o lugar na estante (quando o jogador desiste do livro).
func voltar(duracao: float = 0.7) -> void:
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "global_transform", _transform_estante, duracao)
	await tw.finished
