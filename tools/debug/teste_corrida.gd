extends Node
## Cap. 3 da Alice: confere os bichos correndo, a espiral da história e pega os 3 confeitos.
## SHOTS=/pasta godot --path . res://tools/debug/TesteCorrida.tscn

var pasta: String = OS.get_environment("SHOTS")
var _completou: bool = false


func _ready() -> void:
	var alice := load("res://data/livros/alice.tres") as BookData
	GameState.livro_atual = alice
	GameState.capitulo_atual = alice.lista_capitulos()[2]
	GameState.itens_coletados = 0
	GameState.mission_completed.connect(func() -> void: _completou = true)
	add_child((load(GameState.capitulo_atual.cena) as PackedScene).instantiate())
	var nino := get_tree().get_first_node_in_group("sonhador") as DreamerController
	await get_tree().create_timer(2.5).timeout
	print("nino no planeta: chao=%s up=%s" % [nino.is_on_floor(), nino.up_direction])
	await _foto("corrida_1")
	var itens: Array[Node] = []
	for n: Node in get_tree().current_scene.find_children("*", "MissionItem", true, false):
		itens.append(n)
	for n: Node in find_children("*", "MissionItem", true, false):
		if not itens.has(n):
			itens.append(n)
	print("confeitos: ", itens.size())
	var rabo := find_child("RaboDaHistoria", true, false) as Node3D
	nino.global_position = rabo.global_position + rabo.global_basis.y * 1.5 + rabo.global_basis.x * 4.0
	await get_tree().create_timer(1.5).timeout
	await _foto("corrida_2_rabo")
	for item: Node in itens:
		if is_instance_valid(item):
			nino.global_position = (item as Node3D).global_position + (item as Node3D).global_basis.y * 0.3
			await get_tree().create_timer(0.6).timeout
			print("  pegou? itens=%d" % GameState.itens_coletados)
	await get_tree().create_timer(0.5).timeout
	print("missao completa=", _completou)
	await _foto("corrida_3_fim")
	get_tree().quit()


func _foto(nome: String) -> void:
	if pasta.is_empty():
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [pasta, nome])
