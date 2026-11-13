extends Node
## Teste automático: carrega o Cap. 7, simula andar/correr/pular e imprime o estado da animação.
## Rodar: godot --headless --path . res://tools/debug/TesteAnim.tscn

var nino: DreamerController
var anim: CharacterAnimator
var t: float = 0.0
var prox_log: float = 0.0
var esq: Skeleton3D
var osso: int = -1
var cam: Camera3D
var fotos: Array = [0.9, 1.8, 4.6, 4.9, 6.3, 6.6]
var pasta: String = OS.get_environment("SHOTS")


func _ready() -> void:
	var lvl: Node = load("res://scenes/livros/alice/Cap07_ChaMaluco.tscn").instantiate()
	add_child(lvl)
	await get_tree().physics_frame
	nino = get_tree().get_first_node_in_group("sonhador") as DreamerController
	anim = nino.get_node("Visual") as CharacterAnimator
	var p: AnimationPlayer = anim._player
	print("libs: ", p.get_animation_library_list(), " total anims: ", p.get_animation_list().size())
	print("tem ual/Walk_Loop? ", p.has_animation(&"ual/Walk_Loop"), "  exemplo trilha: ",
		p.get_animation(&"ual/Walk_Loop").track_get_path(0) if p.has_animation(&"ual/Walk_Loop") else "-")
	print("ual: ", Array(p.get_animation_list()).filter(func(n: StringName) -> bool: return String(n).begins_with("ual/")))
	print("exemplo trilha hyper3d: ", p.get_animation(&"human_000025").track_get_path(0))
	for n: Node in nino.find_children("*", "Skeleton3D", true, false):
		esq = n as Skeleton3D
	print("skeleton: ", anim.get_path_to(esq) if esq else "NENHUM")
	osso = esq.find_bone("LeftUpLeg") if esq else -1
	if pasta != "":
		cam = Camera3D.new()
		add_child(cam)
		cam.current = true


func _physics_process(delta: float) -> void:
	if nino == null:
		return
	t += delta
	Input.action_release("move_forward")
	Input.action_release("jump")
	if t > 1.0 and t < 4.0:
		Input.action_press("move_forward")
	if t > 2.5 and t < 2.7:
		Input.action_press("jump")
	if t > 5.0 and t < 5.2:
		Input.action_press("jump")
	Input.action_release("lamp")
	if t > 6.0:
		Input.action_press("lamp")
	if t >= prox_log:
		prox_log += 0.2
		var up: Vector3 = nino.up_direction
		var v: Vector3 = nino.velocity
		var lat: float = (v - up * v.dot(up)).length()
		var rot: String = str(esq.get_bone_pose_rotation(osso)).substr(0, 40) if osso >= 0 else "-"
		print("t=%.1f anim=%s chao=%s lat=%.2f vert=%.2f perna=%s" % [t, anim._player.current_animation,
			nino.is_on_floor(), lat, v.dot(up), rot])
	if cam:
		var up2: Vector3 = nino.up_direction
		var lado: Vector3 = nino.global_basis.x.normalized()
		# metade das fotos de frente (para onde ele anda), metade de lado
		var frente: Vector3 = -nino.global_basis.z.normalized()
		var de_frente: bool = fotos.size() % 2 == 0
		cam.global_position = nino.global_position + up2 * 0.9 + (frente * 2.6 if de_frente else lado * 2.6)
		cam.look_at(nino.global_position + up2 * 0.7, up2)
		if not fotos.is_empty() and t >= fotos[0]:
			var tt: float = fotos.pop_front()
			await RenderingServer.frame_post_draw
			var nome_anim: String = String(anim._player.current_animation).replace("/", "-")
			get_viewport().get_texture().get_image().save_png("%s/t%.2f_%s.png" % [pasta, tt, nome_anim])
	if t > 7.0:
		get_tree().quit()
