extends Node
## Cap. 8 da Alice (pesadelo): simula a Luna acalmando os soldados-carta, a Rainha descendo,
## a segunda leva de soldados e o fim. Imprime as etapas e salva prints.
## SHOTS=/pasta godot --path . res://tools/debug/TesteCroquet.tscn

var pasta: String = OS.get_environment("SHOTS")
var _completou: bool = false


func _ready() -> void:
	var alice := load("res://data/livros/alice.tres") as BookData
	GameState.livro_atual = alice
	GameState.capitulo_atual = alice.lista_capitulos()[7]
	GameState.mission_completed.connect(func() -> void: _completou = true)
	var fase := (load(GameState.capitulo_atual.cena) as PackedScene).instantiate()
	add_child(fase)
	await get_tree().create_timer(2.5).timeout
	await _foto("croquet_1")
	print("sombras: ", get_tree().get_nodes_in_group("sombra").size())
	# acalma os soldados (luz direta)
	await _acalmar_soldados()
	await get_tree().create_timer(1.5).timeout
	var rainha := get_tree().get_first_node_in_group("chefe") as ShadowCreature
	print("rainha escudo=", rainha.escudo, " vel=", rainha.chase_speed)
	var nino := get_tree().get_first_node_in_group("sonhador") as Node3D
	nino.global_position = rainha.global_position + rainha.global_basis.y * 0.5 - rainha.global_basis.z * 4.0
	await get_tree().create_timer(1.5).timeout
	await _foto("croquet_2_rainha")
	var voltas: int = 0
	while not rainha.escudo:
		rainha.receive_light(0.2)
		voltas += 1
		if voltas % 30 == 0:
			print("  fracao=%.2f escudo=%s" % [rainha.fracao(), rainha.escudo])
		await get_tree().physics_frame
	await get_tree().create_timer(0.5).timeout
	print("metade: escudo=", rainha.escudo, " sombras=", get_tree().get_nodes_in_group("sombra").size())
	await _foto("croquet_3_escudo")
	await _acalmar_soldados()
	await get_tree().create_timer(0.5).timeout
	print("de novo: escudo=", rainha.escudo)
	while is_instance_valid(rainha) and not rainha.is_queued_for_deletion():
		rainha.receive_light(0.3)
		await get_tree().physics_frame
	await get_tree().create_timer(2.5).timeout
	await _foto("croquet_4_amanhecer")
	print("missao completa=", _completou)
	get_tree().quit()


func _acalmar_soldados() -> void:
	for n: Node in get_tree().get_nodes_in_group("sombra"):
		var s := n as ShadowCreature
		if s and not s.is_boss:
			while is_instance_valid(s) and not s.is_queued_for_deletion():
				s.receive_light(0.5)
				await get_tree().physics_frame


func _foto(nome: String) -> void:
	if pasta.is_empty():
		return
	await RenderingServer.frame_post_draw
	if true:
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [pasta, nome])
