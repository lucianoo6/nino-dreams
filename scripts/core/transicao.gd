extends CanvasLayer
## Autoload "Transicao": cortina de nuvens fofas por cima de tudo.
## cobrir() -> adormecer; descobrir() -> chegar no sonho. Ambos devolvem o Tween (use `await t.finished`).

const SHADER := preload("res://shaders/nuvens.gdshader")

var _rect: ColorRect
var _mat: ShaderMaterial
var _tween: Tween


func _ready() -> void:
	layer = 100
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_rect = ColorRect.new()
	_rect.material = _mat
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
	definir(0.0)


func definir(valor: float) -> void:
	_mat.set_shader_parameter("cobertura", valor)
	_rect.visible = valor > 0.001


func cobrir(duracao: float = 1.4) -> Tween:
	return _animar(1.0, duracao)


func descobrir(duracao: float = 2.0) -> Tween:
	return _animar(0.0, duracao)


func _animar(alvo: float, duracao: float) -> Tween:
	if _tween:
		_tween.kill()
	_rect.visible = true
	var atual: float = _mat.get_shader_parameter("cobertura")
	_tween = create_tween()
	_tween.tween_method(definir, atual, alvo, duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return _tween
