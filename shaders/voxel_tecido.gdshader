shader_type spatial;
// VOXEL DE TECIDO: cada face de cubo vira um quadradinho de feltro ESTOFADO (como um patchwork):
// cor do voxel (atributo de cor), fibra de feltro, borda afundada (costura entre os quadradinhos),
// pontinhos de linha na costura e um "brilho de veludo" nas bordas (sheen/rim).
// A malha vem do tools/blender/voxelizar.py com UV 0..1 em cada face.
render_mode cull_back, diffuse_burley;

uniform sampler2D fibra : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D fibra_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float escala_fibra = 0.35;
uniform float estofado : hint_range(0.0, 1.0) = 0.55;   // quanto a borda afunda
uniform float largura_costura : hint_range(0.02, 0.3) = 0.13;
uniform vec4 cor_linha : source_color = vec4(1.0, 0.96, 0.88, 1.0);
uniform float pontos_linha : hint_range(0.0, 1.0) = 0.55;
uniform float veludo : hint_range(0.0, 1.0) = 0.45;

varying vec3 pos_mundo;

void vertex() {
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = UV;
	// distância até a borda do quadradinho
	vec2 d2 = min(uv, 1.0 - uv);
	float borda = min(d2.x, d2.y);
	// "almofada": sobe no meio e afunda na borda
	float almofada = smoothstep(0.0, largura_costura, borda);
	// fibra de feltro: amostrada em coordenadas do mundo (não repete igual em todos os cubos)
	vec2 fuv = (pos_mundo.xz + pos_mundo.y * vec2(0.37, 0.61)) * escala_fibra + uv * 0.25;
	vec3 fib = texture(fibra, fuv).rgb;
	vec3 base = COLOR.rgb * mix(vec3(1.0), fib * 1.15, 0.55);
	base *= mix(1.0 - estofado * 0.45, 1.0, almofada);
	// pontinhos de costura correndo junto da borda
	float faixa = smoothstep(0.035, 0.0, abs(borda - largura_costura * 0.55));
	float tracejado = step(0.5, fract((uv.x + uv.y) * 5.0));
	base = mix(base, cor_linha.rgb * COLOR.rgb * 1.3 + 0.08, faixa * tracejado * pontos_linha);
	ALBEDO = base;
	// normal da almofada (inclina perto das bordas) + fibra
	vec2 inclina = vec2(0.0);
	if (d2.x < largura_costura) inclina.x = (uv.x < 0.5 ? -1.0 : 1.0) * (1.0 - almofada);
	if (d2.y < largura_costura) inclina.y = (uv.y < 0.5 ? -1.0 : 1.0) * (1.0 - almofada);
	vec3 nf = texture(fibra_normal, fuv).rgb * 2.0 - 1.0;
	NORMAL_MAP = normalize(vec3(-inclina * estofado * 0.9 + nf.xy * 0.35, 1.0)) * 0.5 + 0.5;
	ROUGHNESS = 0.92;
	SPECULAR = 0.25;
	// veludo: claridade suave nas bordas da silhueta (fibras pegando luz)
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = base * fres * veludo * 0.35;
}
