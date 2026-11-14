shader_type canvas_item;
// Pós-processamento "maquete fotografada": vinheta suave, grão de filme leve, tom quente e
// um leve "halation" (o brilho que vaza ao redor das luzes em fotos de verdade).
uniform sampler2D tela : hint_screen_texture, filter_linear_mipmap;
uniform float vinheta : hint_range(0.0, 1.0) = 0.38;
uniform float grao : hint_range(0.0, 0.2) = 0.035;
uniform vec3 tom : source_color = vec3(1.03, 1.0, 0.95);
uniform float halation : hint_range(0.0, 1.0) = 0.18;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 cor = texture(tela, SCREEN_UV).rgb;
	// halation: mistura um pouco da versão borrada (mip alto) onde está claro
	vec3 borrado = textureLod(tela, SCREEN_UV, 4.0).rgb;
	float claro = smoothstep(0.65, 1.0, dot(borrado, vec3(0.333)));
	cor += borrado * vec3(1.0, 0.75, 0.55) * claro * halation;
	cor *= tom;
	vec2 c = SCREEN_UV - 0.5;
	cor *= 1.0 - vinheta * smoothstep(0.25, 0.85, length(c * vec2(1.0, 0.85)) * 1.25);
	float g = hash(SCREEN_UV * 1000.0 + fract(TIME * 7.13)) - 0.5;
	cor += g * grao;
	COLOR = vec4(cor, 1.0);
}
