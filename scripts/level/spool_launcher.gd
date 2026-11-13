class_name SpoolLauncher
extends Area3D
## CARRETEL-LANÇADOR: pisou, a linha estica e "tóim!" — o sonhador voa em arco até o destino.
## Se a Mel (IA) estiver perto, ela vai junto logo atrás (ninguém fica para trás num lançamento).

@export var destino: NodePath
@export var altura_arco: float = 10.0
@export var duracao: float = 1.6
@export var levar_mel_raio: float = 12.0
@export var som: AudioStream

var _visual: Node3D
var _audio: AudioStreamPlayer3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	_visual = get_node_or_null("Visual") as Node3D
	_audio = AudioStreamPlayer3D.new()
	_audio.stream = som
	add_child(_audio)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	var sonhador := body as DreamerController
	var alvo := get_node_or_null(destino) as Node3D
	if sonhador == null or alvo == null or sonhador.is_launching():
		return
	_boing()
	sonhador.launch_to(alvo.global_position, altura_arco, duracao)

	if body.is_in_group("sonhador"):
		for n: Node in get_tree().get_nodes_in_group("mel"):
			var mel := n as MelController
			if mel and not mel.player_controlled and mel.global_position.distance_to(global_position) < levar_mel_raio:
				var atraso := get_tree().create_timer(0.3)
				atraso.timeout.connect(mel.launch_to.bind(alvo.global_position + alvo.global_basis.x * 1.2,
						altura_arco * 1.1, duracao))


func _boing() -> void:
	if _audio.stream:
		_audio.play()
	if _visual == null:
		return
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3(1.3, 0.6, 1.3), 0.08)
	tw.tween_property(_visual, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
