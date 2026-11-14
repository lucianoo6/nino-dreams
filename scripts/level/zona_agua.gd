class_name ZonaAgua
extends Area3D
## Água (ex.: a lagoa de lágrimas de tule). Quem entra nada: boia com o peito na superfície (topo da caixa).
## A forma deve ser uma BoxShape3D; o nível da água é o topo dela.

@export var tamanho: Vector3 = Vector3(100, 6, 100)

var nivel: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 6
	monitorable = false
	var c := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = tamanho
	c.shape = b
	add_child(c)
	nivel = global_position.y + tamanho.y / 2.0
	body_entered.connect(func(corpo: Node3D) -> void:
		var d := corpo as DreamerController
		if d:
			d.entrar_agua(nivel))
	body_exited.connect(func(corpo: Node3D) -> void:
		var d := corpo as DreamerController
		if d:
			d.sair_agua())
