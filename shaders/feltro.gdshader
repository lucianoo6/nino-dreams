// Feltro / lã — material base do mundo de Sonhos.
// Ideia: superfície 100% fosca, fibrinhas por ruído triplanar (sem precisar de UV),
// "penugem" na borda via RIM (como tecido contra a luz) e um pouco de BACKLIGHT (lã é meio translúcida).
// Uma única ShaderMaterial serve para tudo: a cor de cada objeto vem do instance uniform `tint`.
shader_type spatial;
render_mode diffuse_lambert_wrap, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(1.0);
instance uniform vec4 tint : source_color = vec4(0.9, 0.55, 0.6, 1.0);

group_uniforms fibras;
uniform sampler2D fiber_noise : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float fiber_scale = 0.6;
uniform float fiber_strength : hint_range(0.0, 1.0) = 0.35;
uniform float fiber_bump : hint_range(0.0, 2.0) = 0.6;

group_uniforms penugem;
uniform float fuzz_rim : hint_range(0.0, 1.0) = 0.7;
uniform float fuzz_tint : hint_range(0.0, 1.0) = 0.6;
uniform float backlight_amount : hint_range(0.0, 1.0) = 0.15;

group_uniforms pesadelo;
// 0 = sonho colorido, 1 = pesadelo (dessaturado, frio, escuro). Animável para a luz da lua "devolver a cor".
uniform float pesadelo : hint_range(0.0, 1.0) = 0.0;
uniform vec3 pesadelo_tint : source_color = vec3(0.35, 0.3, 0.55);

varying vec3 w_pos;
varying vec3 w_nrm;

void vertex() {
	w_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	w_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float tri(vec3 p, vec3 n) {
	vec3 w = pow(abs(n), vec3(4.0));
	w /= (w.x + w.y + w.z);
	return texture(fiber_noise, p.zy).r * w.x
		 + texture(fiber_noise, p.xz).r * w.y
		 + texture(fiber_noise, p.xy).r * w.z;
}

void fragment() {
	vec3 p = w_pos * fiber_scale;
	vec3 n = normalize(w_nrm);
	float coarse = tri(p, n);
	float fine = tri(p * 5.3, n);
	float fibers = mix(coarse, fine, 0.55);

	vec3 col = base_color.rgb * tint.rgb;
	col *= mix(1.0 - fiber_strength, 1.0, fibers);

	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 night = mix(vec3(lum), pesadelo_tint * lum * 1.6, 0.6) * 0.7;
	col = mix(col, night, pesadelo);

	ALBEDO = col;
	ROUGHNESS = 1.0;
	SPECULAR = 0.15;
	RIM = fuzz_rim;
	RIM_TINT = fuzz_tint;
	BACKLIGHT = col * backlight_amount;

	// Relevo de fibra barato: perturba a normal pelo gradiente da tela do ruído fino.
	float h = fine * fiber_bump;
	vec3 dpdx = dFdx(VERTEX);
	vec3 dpdy = dFdy(VERTEX);
	float dhdx = dFdx(h);
	float dhdy = dFdy(h);
	vec3 r1 = cross(dpdy, NORMAL);
	vec3 r2 = cross(NORMAL, dpdx);
	float det = dot(dpdx, r1);
	if (abs(det) > 1e-6) {
		vec3 grad = sign(det) * (dhdx * r1 + dhdy * r2);
		NORMAL = normalize(abs(det) * NORMAL - grad * 0.02);
	}
}
