shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

// Scanlines
uniform float scanline_density = 360.0; // 240-480
uniform float scanline_strength = 0.14; // 0.05-0.25

// CRT mask (subpixel/grade)
uniform float mask_strength = 0.06;     // 0 desliga
uniform float mask_scale = 1.0;         // 1 normal, 2 maior

// Glow fake (barato)
uniform float glow_strength = 0.22;     // 0-0.35
uniform float glow_threshold = 0.55;    // 0.4-0.7
uniform float glow_radius_px = 1.25;    // 0.75-2.0

// Flicker e vinheta
uniform float flicker_strength = 0.02;  // 0-0.05
uniform float vignette_strength = 0.12; // 0-0.25

// Neon pop
uniform float contrast = 1.06;          // 1-1.15
uniform float saturation = 1.05;        // 1-1.2

float luma(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

vec3 saturate_color(vec3 c, float sat) {
	float g = luma(c);
	return mix(vec3(g), c, sat);
}

void fragment() {
	// ✅ Tudo em screen-space: colado na viewport SEMPRE
	vec2 uv = SCREEN_UV;

	vec4 base = texture(screen_tex, uv);
	vec3 col = base.rgb;

	// ---------- Glow fake (9 taps) ----------
	if (glow_strength > 0.0001) {
		vec2 px = 1.0 / vec2(textureSize(screen_tex, 0));
		vec2 r = px * glow_radius_px;

		vec3 g = vec3(0.0);
		g += texture(screen_tex, uv + vec2(-r.x, -r.y)).rgb;
		g += texture(screen_tex, uv + vec2( 0.0, -r.y)).rgb;
		g += texture(screen_tex, uv + vec2( r.x, -r.y)).rgb;

		g += texture(screen_tex, uv + vec2(-r.x,  0.0)).rgb;
		g += texture(screen_tex, uv).rgb;
		g += texture(screen_tex, uv + vec2( r.x,  0.0)).rgb;

		g += texture(screen_tex, uv + vec2(-r.x,  r.y)).rgb;
		g += texture(screen_tex, uv + vec2( 0.0,  r.y)).rgb;
		g += texture(screen_tex, uv + vec2( r.x,  r.y)).rgb;

		g /= 9.0;

		float hl = smoothstep(glow_threshold, 1.0, luma(g));
		col += g * (glow_strength * hl);
	}

	// ---------- Scanlines (screen-space) ----------
	float y = uv.y * scanline_density * 3.14159265;
	float s = (sin(y) * 0.5) + 0.5;
	float scan = mix(1.0, s, scanline_strength);
	col *= scan;

	// ---------- CRT mask (screen-space) ----------
	if (mask_strength > 0.0001) {
		vec2 px_screen = vec2(textureSize(screen_tex, 0));
		vec2 p = uv * px_screen / mask_scale;

		float m = fract(p.x / 3.0);
		vec3 mask_rgb = vec3(
			smoothstep(0.0, 0.15, 0.5 - abs(m - 0.166)),
			smoothstep(0.0, 0.15, 0.5 - abs(m - 0.5  )),
			smoothstep(0.0, 0.15, 0.5 - abs(m - 0.833))
		);

		mask_rgb = mix(vec3(1.0), 0.85 + 0.15 * mask_rgb, mask_strength);
		col *= mask_rgb;
	}

	// ---------- Flicker (screen-space) ----------
	float flick = 1.0 + (sin(TIME * 60.0) * flicker_strength);
	col *= flick;

	// ---------- Vinheta (screen-space) ----------
	vec2 d = uv * 2.0 - 1.0;
	float v = 1.0 - vignette_strength * smoothstep(0.2, 1.2, dot(d, d));
	col *= v;

	// ---------- “Neon pop” ----------
	col = pow(col, vec3(1.0 / contrast));
	col = saturate_color(col, saturation);

	COLOR = vec4(col, base.a);
}
