shader_type spatial;
// Lagoa de lágrimas feita de TULE: ondinhas suaves, trama de redinha (hexagonal), brilhinhos
// e borda mais clara (fresnel). Pensada para um plano grande subdividido.
render_mode blend_mix, depth_draw_always, cull_back, specular_schlick_ggx;

uniform vec4 cor_funda : source_color = vec4(0.12, 0.42, 0.62, 0.88);
uniform vec4 cor_rasa : source_color = vec4(0.35, 0.68, 0.82, 0.78);
uniform vec4 cor_trama : source_color = vec4(0.92, 0.96, 1.0, 1.0);
uniform float escala_trama = 3.0;
uniform float altura_onda = 0.12;
uniform float velocidade = 0.6;

varying vec3 pos_mundo;

float onda(vec2 p, float t) {
	return sin(p.x * 0.35 + t) * 0.5 + sin(p.y * 0.28 - t * 1.3) * 0.35 + sin((p.x + p.y) * 0.6 + t * 0.7) * 0.15;
}

void vertex() {
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * velocidade;
	VERTEX.y += onda(pos_mundo.xz, t) * altura_onda;
	// normal aproximada pela derivada da onda
	float e = 0.3;
	float hx = onda(pos_mundo.xz + vec2(e, 0.0), t) - onda(pos_mundo.xz - vec2(e, 0.0), t);
	float hz = onda(pos_mundo.xz + vec2(0.0, e), t) - onda(pos_mundo.xz - vec2(0.0, e), t);
	NORMAL = normalize(vec3(-hx * altura_onda / (2.0 * e), 1.0, -hz * altura_onda / (2.0 * e)));
}

// distância à borda de uma célula hexagonal (trama do tule)
float hexa(vec2 p) {
	p *= escala_trama;
	vec2 r = vec2(1.0, 1.7320508);
	vec2 h = r * 0.5;
	vec2 a = mod(p, r) - h;
	vec2 b = mod(p - h, r) - h;
	vec2 g = dot(a, a) < dot(b, b) ? a : b;
	g = abs(g);
	return 0.5 - max(dot(g, normalize(r)), g.x);
}

float ruido(vec2 p) {
	return fract(sin(dot(floor(p), vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	float t = TIME * velocidade;
	vec2 p = pos_mundo.xz + vec2(onda(pos_mundo.xz * 0.5, t) * 0.15);
	float linha = 1.0 - smoothstep(0.02, 0.06, hexa(p));
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0) * 0.6;
	// a trama do tule some com a distância (perto: tecido; longe: água)
	float dist = length(VERTEX);
	linha *= 1.0 - smoothstep(6.0, 22.0, dist);
	vec4 base = mix(cor_funda, cor_rasa, fres);
	vec3 cor = mix(base.rgb, cor_trama.rgb, linha * 0.25);
	// brilhinhos que piscam
	vec2 q = pos_mundo.xz * 3.0;
	vec2 celula = floor(q);
	float ponto = 1.0 - smoothstep(0.05, 0.12, length(fract(q) - 0.5));
	float b = step(0.97, ruido(celula)) * ponto * (0.5 + 0.5 * sin(TIME * 3.0 + ruido(celula + 3.0) * 30.0));
	ALBEDO = cor;
	EMISSION = vec3(1.0, 0.97, 0.9) * b * 1.5;
	ALPHA = clamp(base.a + linha * 0.15 + fres * 0.2, 0.0, 1.0);
	ROUGHNESS = 0.12;
	SPECULAR = 0.7;
}
