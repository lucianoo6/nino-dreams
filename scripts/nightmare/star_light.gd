class_name StarLight
extends OmniLight3D
## ESTRELINHA — a luz da Mel: estrela de luz QUENTE, redonda (aura), complementar à Luna (fria, em cone).
## • Pesadelo: zona segura (sombras não entram); Luna recarrega mais rápido perto dela;
##   Luna + Estrelinha juntas na mesma sombra = "luz de amanhecer" (dano multiplicado).
## • Sonho: revela coisas escondidas (StarRevealable), como fios-ponte e botões secretos.
## Apertar a ação faz um "abraço de luz": aura maior por um tempo, depois descansa.

const CROSS_LIGHT_BONUS := 2.5

@export var base_radius: float = 3.5
@export var hug_radius: float = 7.0
@export var hug_duration: float = 2.5
@export var hug_cooldown: float = 4.0
@export var luna_recharge_boost: float = 2.5
@export var action_name: StringName = &"p2_lamp"
## Quando a IA controla a Mel, ela dá o "abraço de luz" sozinha se houver sombra muito perto.
@export var auto_hug_when_ai: bool = true

var radius: float

var _hug_timer: float = 0.0
var _cooldown: float = 0.0
var _owner_mel: MelController


func _ready() -> void:
	add_to_group("estrelinha")
	radius = base_radius
	_owner_mel = get_parent() as MelController


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	_hug_timer -= delta

	var ai_controlled: bool = _owner_mel != null and not _owner_mel.player_controlled
	var wants_hug: bool
	if ai_controlled:
		wants_hug = auto_hug_when_ai and _shadow_nearby(base_radius * 1.3)
	else:
		wants_hug = Input.is_action_just_pressed(action_name)
	if wants_hug and _cooldown <= 0.0:
		_hug_timer = hug_duration
		_cooldown = hug_duration + hug_cooldown

	var target_radius: float = hug_radius if _hug_timer > 0.0 else base_radius
	radius = lerpf(radius, target_radius, 1.0 - exp(-6.0 * delta))
	omni_range = radius * 1.6

	var c: Vector3 = global_position

	for n: Node in get_tree().get_nodes_in_group("sombra"):
		var s := n as ShadowCreature
		if s and s.global_position.distance_to(c) < radius:
			s.is_in_star_aura = true
			s.repel_active = true
			s.repel_from = c

	for n: Node in get_tree().get_nodes_in_group("luna"):
		var luna := n as MoonLamp
		if luna:
			var perto: bool = luna.global_position.distance_to(c) < radius * 1.5
			luna.recharge_multiplier = luna_recharge_boost if perto else 1.0

	for n: Node in get_tree().get_nodes_in_group("revelavel_estrela"):
		var r := n as StarRevealable
		if r:
			r.set_lit(r.global_position.distance_to(c) < radius)


func _shadow_nearby(r: float) -> bool:
	for n: Node in get_tree().get_nodes_in_group("sombra"):
		var s := n as Node3D
		if s and s.global_position.distance_to(global_position) < r:
			return true
	return false
