class_name CameraZone
extends Area3D
## Zona de câmera guiada: enquanto o Nino está dentro, a câmera muda distância/inclinação e
## (opcionalmente) gira devagar para olhar na direção de um alvo — mostra o caminho sem tirar o controle.

@export var comprimento: float = 9.0
@export var inclinacao_graus: float = -32.0
## Opcional: a câmera vira para que o Nino olhe na direção deste nó.
@export var olhar_para: NodePath
@export var forca_giro: float = 1.5


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func alvo() -> Node3D:
	return get_node_or_null(olhar_para) as Node3D if not olhar_para.is_empty() else null


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("sonhador"):
		var cam := (body as DreamerController).get_dream_camera()
		if cam:
			cam.aplicar_zona(self)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("sonhador"):
		var cam := (body as DreamerController).get_dream_camera()
		if cam:
			cam.limpar_zona(self)
