class_name NinoLendo
extends Node3D
## O Nino de feltro "de verdade" (como na foto de referência), recostado no travesseiro lendo.
## É o Nino do quarto; dentro do sonho ele vira o boneco de pano mais caricato.
## Fica deitado na cama (relativo ao nó `cama`), respira devagar e balança a cabeça quando lê em voz alta.

@export var modelo: PackedScene = preload("res://assets/models/personagens/nino_lendo_vox.glb")
@export var cama: NodePath = ^"../Cama"
## Posição no espaço da cama (o modelo olha para +Z = pé da cama; a cabeça fica no travesseiro).
@export var posicao_na_cama: Vector3 = Vector3(0.0, 0.83, -0.3)
@export var escala: float = 0.85

## Lendo em voz alta (o quarto liga/desliga enquanto o balão escreve a frase).
var lendo_alto: bool = false

var _corpo: Node3D
var _t: float = 0.0


func _ready() -> void:
	var c := get_node_or_null(cama) as Node3D
	if c:
		global_transform = c.global_transform * Transform3D(Basis.from_scale(Vector3.ONE * escala), posicao_na_cama)
	_corpo = modelo.instantiate() as Node3D
	VoxelTecido.aplicar(_corpo)
	add_child(_corpo)


func _process(delta: float) -> void:
	_t += delta
	# respiração: o peito sobe e desce bem de leve
	var resp: float = sin(_t * 1.6) * 0.012
	_corpo.scale = Vector3(1.0 + resp * 0.5, 1.0 + resp, 1.0 + resp * 0.5)
	# lendo em voz alta: balança um pouquinho, como quem acompanha as palavras
	var alvo: float = sin(_t * 7.0) * 0.025 if lendo_alto else 0.0
	_corpo.rotation.x = lerpf(_corpo.rotation.x, alvo, 1.0 - exp(-8.0 * delta))
