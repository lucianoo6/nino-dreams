// Transição de nuvens fofas (tela cheia). cobertura: 0 = céu limpo, 1 = tudo coberto de nuvem.
// Usada para "adormecer" (estante -> sonho) e para a câmera "descer das nuvens" no início do sonho.
shader_type canvas_item;

uniform float cobertura : hint_range(0.0, 1.0) = 0.0;
uniform vec4 cor_nuvem : source_color = vec4(1.0, 0.97, 1.0, 1.0);
uniform vec4 cor_sombra : source_color = vec4(0.78, 0.72, 0.93, 1.0);
uniform float escala = 2.6;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 aspect = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	vec2 p = UV * aspect * escala;
	float n1 = fbm(p + vec2(TIME * 0.05, TIME * 0.015));
	float n2 = fbm(p * 0.5 - vec2(TIME * 0.03, 0.0));
	float forma = mix(n1, n2, 0.5);
	// Limiar desce conforme a cobertura sobe: as nuvens "crescem" pelos fofos.
	float t = mix(1.05, -0.15, cobertura);
	float alpha = smoothstep(t - 0.06, t + 0.06, forma);
	vec3 cor = mix(cor_sombra.rgb, cor_nuvem.rgb, smoothstep(0.35, 0.75, n1));
	COLOR = vec4(cor, alpha);
}
