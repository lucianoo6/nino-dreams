extends Node3D
## Mostra um modelo (MODELO=res://...glb) de frente e de lado, imprime o tamanho (AABB) e salva prints.
## MODELO=res://assets/models/personagens/nino_pano.glb SHOTS=/pasta godot --path . res://tools/debug/VerModelo.tscn


func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.85, 0.85, 0.88)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.8, 0.85)
	add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-40, 30, 0)
	add_child(sol)
	var m := (load(OS.get_environment("MODELO")) as PackedScene).instantiate() as Node3D
	add_child(m)
	var caixa := _aabb(m)
	print("AABB pos=", caixa.position, " tamanho=", caixa.size)
	var centro: Vector3 = caixa.get_center()
	var dist: float = caixa.size.length() * 1.3
	var cam := Camera3D.new()
	add_child(cam)
	cam.current = true
	var pasta: String = OS.get_environment("SHOTS")
	for lado: Array in [["frente", Vector3(0, 0.1, 1)], ["lado", Vector3(1, 0.1, 0)], ["costas", Vector3(0, 0.1, -1)]]:
		cam.position = centro + (lado[1] as Vector3).normalized() * dist
		cam.look_at(centro)
		await get_tree().create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/modelo_%s.png" % [pasta, lado[0]])
	get_tree().quit()


func _aabb(n: Node) -> AABB:
	var total := AABB()
	var primeiro: bool = true
	for f: Node in n.find_children("*", "VisualInstance3D", true, false):
		var v := f as VisualInstance3D
		var a: AABB = v.global_transform * v.get_aabb()
		total = a if primeiro else total.merge(a)
		primeiro = false
	return total
