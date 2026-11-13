class_name CharacterAnimator
extends Node3D
## Escolhe a animação do personagem (modelo do Hyper3D com 52 ossos) a partir do estado do DreamerController.
## Sem pai DreamerController (ex.: Nino sentado no quarto), toca só `modo_fixo`.
## Nomes = IDs das animações do catálogo Rodin embutidas no .glb.

@export_group("Animações")
@export var anim_parado: StringName = &"human_000025" ## happy idle
@export var anim_parado_pesadelo: StringName = &"human_000050" ## sad idle
@export var anim_andar: StringName = &"human_000089" ## walking
@export var anim_andar_pesadelo: StringName = &"human_000086" ## tiptoe walk
@export var anim_correr: StringName = &"human_000024" ## goofy running
@export var anim_pulo: StringName = &"human_000030" ## joyful jump
@export var anim_rodopio: StringName = &"human_000039" ## northern soul spin
## Começa o pulo já no ar (pula a preparação agachada da animação).
@export var pulo_inicio: float = 0.45

@export_group("Ritmo")
@export var limiar_andar: float = 0.4
@export var limiar_correr: float = 4.0
## Velocidade (m/s) em que a animação de andar/correr fica no ritmo natural (já na escala do modelo).
@export var ritmo_andar: float = 1.4
@export var ritmo_correr: float = 2.6
@export var mistura: float = 0.18

## Se preenchido, toca sempre esta animação (cutscenes, quarto).
@export var modo_fixo: StringName = &""

var _player: AnimationPlayer
var _body: DreamerController


func _ready() -> void:
	_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	_body = get_parent() as DreamerController
	if _player == null:
		push_warning("CharacterAnimator: AnimationPlayer não encontrado no modelo.")
		return
	# Todas em loop (o .glb vem sem loop); o pulo é tratado à parte.
	for nome: StringName in _player.get_animation_list():
		var anim: Animation = _player.get_animation(nome)
		if anim:
			anim.loop_mode = Animation.LOOP_NONE if nome == anim_pulo else Animation.LOOP_LINEAR
	_tocar(modo_fixo if modo_fixo != &"" else anim_parado)


func _process(_delta: float) -> void:
	if _player == null:
		return
	if modo_fixo != &"" or _body == null:
		_tocar(modo_fixo if modo_fixo != &"" else anim_parado)
		return

	var pesadelo: bool = GameState.livro_atual != null \
		and GameState.livro_atual.tipo == BookData.DreamKind.PESADELO
	var up: Vector3 = _body.up_direction
	var v: Vector3 = _body.velocity
	var lateral: float = (v - up * v.dot(up)).length()

	var forcada: StringName = _body.get_animation_override()
	if forcada != &"":
		_tocar(forcada)
	elif _body.is_launching() or _body.is_spinning:
		_tocar(anim_rodopio, 1.4)
	elif not _body.is_on_floor():
		_tocar(anim_pulo, 1.2, pulo_inicio)
	elif lateral > limiar_correr and not pesadelo:
		_tocar(anim_correr, clampf(lateral / ritmo_correr, 0.8, 2.6))
	elif lateral > limiar_andar:
		var andar: StringName = anim_andar_pesadelo if pesadelo else anim_andar
		_tocar(andar, clampf(lateral / ritmo_andar, 0.7, 2.2))
	else:
		_tocar(anim_parado_pesadelo if pesadelo else anim_parado)


func _tocar(nome: StringName, velocidade: float = 1.0, inicio: float = 0.0) -> void:
	if not _player.has_animation(nome):
		return
	if _player.current_animation != nome:
		_player.play(nome, mistura)
		if inicio > 0.0:
			_player.seek(inicio, true)
	_player.speed_scale = velocidade
