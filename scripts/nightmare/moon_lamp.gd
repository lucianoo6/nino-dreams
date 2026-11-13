class_name MoonLamp
extends SpotLight3D
## LUNA — a luz em formato de lua do quarto do Nino, levada para dentro do pesadelo.
## Luz fria, em cone, direcional: é a "arma" que dissipa as sombras.
## Segurar a ação acende o cone; o Brilho (bateria) gasta acesa e recarrega apagada.

signal glow_changed(glow01: float)

@export var max_glow: float = 100.0
@export var drain_per_second: float = 22.0
@export var recharge_per_second: float = 14.0
@export var light_power: float = 1.0
@export var on_energy: float = 6.0
@export var action_name: StringName = &"lamp"

## Multiplicador de recarga (a Estrelinha da Mel por perto acelera).
var recharge_multiplier: float = 1.0
var glow: float
var is_on: bool = false


func _ready() -> void:
	add_to_group("luna")
	glow = max_glow
	light_energy = 0.0


func _physics_process(delta: float) -> void:
	is_on = Input.is_action_pressed(action_name) and glow > 0.0

	if is_on:
		glow = maxf(0.0, glow - drain_per_second * delta)
	else:
		glow = minf(max_glow, glow + recharge_per_second * recharge_multiplier * delta)
	glow_changed.emit(glow / max_glow)

	light_energy = lerpf(light_energy, on_energy if is_on else 0.0, 1.0 - exp(-14.0 * delta))

	if not is_on:
		return

	var cos_half: float = cos(deg_to_rad(spot_angle))
	var origin: Vector3 = global_position
	var forward: Vector3 = -global_basis.z.normalized()
	var space := get_world_3d().direct_space_state

	for n: Node in get_tree().get_nodes_in_group("sombra"):
		var creature := n as ShadowCreature
		if creature == null:
			continue
		var to: Vector3 = creature.global_position - origin
		var dist: float = to.length()
		if dist > spot_range or dist < 0.01:
			continue
		if forward.dot(to / dist) < cos_half:
			continue

		# Linha de visão: só o mundo (layer 1) bloqueia a luz.
		var query := PhysicsRayQueryParameters3D.create(origin, creature.global_position, 1)
		if not space.intersect_ray(query).is_empty():
			continue

		var falloff: float = 1.0 - dist / spot_range
		# Luz cruzada: Luna + Estrelinha na mesma sombra = "luz de amanhecer", bem mais forte.
		var combo: float = StarLight.CROSS_LIGHT_BONUS if creature.is_in_star_aura else 1.0
		creature.receive_light(light_power * (0.5 + falloff) * combo * delta)
