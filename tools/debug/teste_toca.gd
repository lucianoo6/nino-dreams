extends Node
## Cap. 1 da Alice: fotos do topo, da queda no poço, do fundo e do salão; mede a velocidade de queda
## e testa chave → portinha → missão completa.
## SHOTS=/pasta godot --path . res://tools/debug/TesteToca.tscn

var pasta: String = OS.get_environment("SHOTS")
var _completou: bool = false


func _ready() -> void:
	var alice := load("res://data/livros/alice.tres") as BookData
	GameState.livro_atual = alice
	GameState.capitulo_atual = alice.lista_capitulos()[0]
	GameState.mission_completed.connect(func() -> void: _completou = true)
	var fase := (load(GameState.capitulo_atual.cena) as PackedScene).instantiate()
	add_child(fase)
	var nino := get_tree().get_first_node_in_group("sonhador") as DreamerController
	await get_tree().create_timer(2.0).timeout
	await _foto("toca_1_topo")
	# pula no buraco
	nino.global_position = Vector3(0, 93.0, -2.0)
	await get_tree().create_timer(1.5).timeout
	print("queda: y=%.1f vel=%.2f" % [nino.global_position.y, nino.velocity.y])
	await get_tree().create_timer(1.0).timeout
	await _foto("toca_2_poco")
	print("queda: y=%.1f vel=%.2f chao=%s" % [nino.global_position.y, nino.velocity.y, nino.is_on_floor()])
	nino.global_position = Vector3(0, 8.0, 0)
	await get_tree().create_timer(3.0).timeout
	print("fundo: y=%.2f chao=%s" % [nino.global_position.y, nino.is_on_floor()])
	await _foto("toca_3_fundo")
	nino.global_position = Vector3(0, 0.3, 24.0)
	await get_tree().create_timer(1.5).timeout
	await _foto("toca_4_salao")
	# chave na mesinha (z = 31) e depois a portinha
	nino.global_position = Vector3(0, 1.9, 31.0)
	await get_tree().create_timer(1.5).timeout
	nino.global_position = Vector3(0, 0.3, 40.0)
	await get_tree().create_timer(1.5).timeout
	await _foto("toca_5_portinha")
	nino.global_position = Vector3(0, 0.4, 43.4)
	await get_tree().create_timer(0.8).timeout
	print("missao completa=", _completou)
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()


func _foto(nome: String) -> void:
	await RenderingServer.frame_post_draw
	if not pasta.is_empty():
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [pasta, nome])
