extends Node
## Cap. 5 da Alice: estações de tamanho (gigante / pequenininho / normal), altura do pulo gigante
## e os 3 pedaços do cogumelo.
## SHOTS=/pasta godot --path . res://tools/debug/TesteLagarta.tscn

var pasta: String = OS.get_environment("SHOTS")
var _completou: bool = false


func _ready() -> void:
	var alice := load("res://data/livros/alice.tres") as BookData
	GameState.livro_atual = alice
	GameState.capitulo_atual = alice.lista_capitulos()[4]
	GameState.itens_coletados = 0
	GameState.mission_completed.connect(func() -> void: _completou = true)
	add_child((load(GameState.capitulo_atual.cena) as PackedScene).instantiate())
	var nino := get_tree().get_first_node_in_group("sonhador") as DreamerController
	await get_tree().create_timer(2.5).timeout
	await _foto("lagarta_1")
	# estação vermelha (gigante)
	nino.global_position = Vector3(4.0, 0.3, -8.0)
	await get_tree().create_timer(1.5).timeout
	var cap := (nino.get_node("Colisao") as CollisionShape3D).shape as CapsuleShape3D
	print("gigante: tamanho=%.2f capsula=%.2f pulo=%.1f" % [nino.tamanho, cap.height, nino.jump_velocity])
	await _foto("lagarta_2_gigante")
	# pulo do gigante: mede a altura máxima
	nino.global_position = Vector3(8.0, 0.3, -2.0)
	await get_tree().create_timer(0.8).timeout
	var y0: float = nino.global_position.y
	Input.action_press("jump")
	var maximo: float = y0
	for i in 90:
		await get_tree().physics_frame
		maximo = maxf(maximo, nino.global_position.y)
	Input.action_release("jump")
	print("pulo gigante: %.2f m" % (maximo - y0))
	# estação azul (pequenininho)
	nino.global_position = Vector3(-5.0, 0.3, 5.0)
	await get_tree().create_timer(1.5).timeout
	print("pequeno: tamanho=%.2f capsula=%.2f" % [nino.tamanho, cap.height])
	await _foto("lagarta_3_pequeno")
	# pega os 3 pedaços
	for n: Node in find_children("*", "MissionItem", true, false):
		nino.global_position = (n as Node3D).global_position + Vector3.UP * 0.2
		await get_tree().create_timer(0.6).timeout
	print("itens=%d missao completa=%s" % [GameState.itens_coletados, _completou])
	await _foto("lagarta_4_fim")
	get_tree().quit()


func _foto(nome: String) -> void:
	if pasta.is_empty():
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [pasta, nome])
