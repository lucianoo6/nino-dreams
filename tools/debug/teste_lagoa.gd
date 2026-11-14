extends Node
## Cap. 2 da Alice: testa nadar (boiar na superfície, nado lento, pular para fora), lágrimas e a saída no Dodô.
## SHOTS=/pasta godot --path . res://tools/debug/TesteLagoa.tscn

var pasta: String = OS.get_environment("SHOTS")
var _completou: bool = false


func _ready() -> void:
	var alice := load("res://data/livros/alice.tres") as BookData
	GameState.livro_atual = alice
	GameState.capitulo_atual = alice.lista_capitulos()[1]
	GameState.mission_completed.connect(func() -> void: _completou = true)
	add_child((load(GameState.capitulo_atual.cena) as PackedScene).instantiate())
	var nino := get_tree().get_first_node_in_group("sonhador") as DreamerController
	await get_tree().create_timer(2.5).timeout
	print("ilha: y=%.2f chao=%s nadando=%s" % [nino.global_position.y, nino.is_on_floor(), nino.nadando])
	await _foto("lagoa_1_inicio")
	# cai na água entre as ilhas
	nino.global_position = Vector3(0, 1.5, 31.0)
	await get_tree().create_timer(2.0).timeout
	print("agua: y=%.2f nadando=%s boiando=%s vel_y=%.2f" % [nino.global_position.y, nino.nadando, nino.boiando(),
		nino.velocity.y])
	await _foto("lagoa_2_nadando")
	# pulo para fora da água
	var ev := InputEventAction.new()
	ev.action = "jump"
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().create_timer(0.25).timeout
	print("pulo: y=%.2f vel_y=%.2f nadando=%s" % [nino.global_position.y, nino.velocity.y, nino.nadando])
	var solta := InputEventAction.new()
	solta.action = "jump"
	solta.pressed = false
	Input.parse_input_event(solta)
	await get_tree().create_timer(3.0).timeout
	print("depois: y=%.2f nadando=%s" % [nino.global_position.y, nino.nadando])
	await _foto("lagoa_3_lagrimas")
	nino.global_position = Vector3(0.5, 1.5, 77.0)
	await get_tree().create_timer(1.5).timeout
	print("missao completa=", _completou)
	await _foto("lagoa_4_praia")
	get_tree().quit()


func _foto(nome: String) -> void:
	if pasta.is_empty():
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [pasta, nome])
