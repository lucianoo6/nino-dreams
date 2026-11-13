class_name BabbleVoice
extends AudioStreamPlayer
## Voz "balbuciada": em vez de dublar cada livro, os personagens falam sílabas fofas sem sentido,
## sintetizadas na hora (nenhum arquivo de áudio necessário). Cada letra vira um "blip" com tom próprio,
## então a mesma frase sempre soa igual — parece uma língua de verdade.
## Depois dá para trocar a síntese por sílabas gravadas (ex.: "ba", "mi", "nu") mantendo a mesma interface.

const MIX_RATE := 22050.0

@export var tom_base: float = 340.0 ## Hz — Nino ~340, Mel ~460
@export var variacao: float = 0.35 ## quanto o tom varia entre letras (0..1)
@export var duracao_silaba: float = 0.075
@export_range(0.0, 1.0) var volume_balbucio: float = 0.35

var _playback: AudioStreamGeneratorPlayback


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = 0.5
	stream = gen
	play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback


## Toca um blip para o caractere. Vogais soam mais abertas; consoantes, mais curtinhas.
func blip(caractere: String, multiplicador_tom: float = 1.0) -> void:
	if _playback == null or caractere.strip_edges().is_empty():
		return
	var codigo: int = caractere.to_lower().unicode_at(0)
	var semitom: float = float((codigo * 7) % 9) - 4.0
	var freq: float = tom_base * multiplicador_tom * pow(2.0, semitom * variacao / 4.0)
	var vogal: bool = "aeiouáéíóúâêôãõ".contains(caractere.to_lower())
	var dur: float = duracao_silaba * (1.25 if vogal else 0.8)
	var n: int = int(dur * MIX_RATE)
	if _playback.get_frames_available() < n:
		return
	var fase: float = 0.0
	for i in n:
		var k: float = float(i) / float(n)
		# Envelope: ataque rápido, queda suave.
		var env: float = minf(1.0, k * 12.0) * pow(1.0 - k, 1.6)
		# Pequena "dobra" de tom no fim da sílaba, como fala de bichinho.
		var f: float = freq * (1.0 + 0.12 * sin(k * PI))
		fase += TAU * f / MIX_RATE
		var s: float = sin(fase) + 0.35 * sin(fase * 2.0) + (0.15 * sin(fase * 3.0) if vogal else 0.0)
		s *= env * volume_balbucio * 0.6
		_playback.push_frame(Vector2(s, s))
