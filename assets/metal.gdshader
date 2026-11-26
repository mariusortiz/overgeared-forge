shader_type spatial;

// Recolours a 3D model: its grey metal takes the material's colours, the
// rarity adds a glow on its edges, and heat makes the metal red then white.

uniform sampler2D albedo : source_color, filter_linear, hint_default_white;
uniform vec3 base : source_color = vec3(1.0);
uniform vec3 metal_dark : source_color = vec3(0.33, 0.34, 0.39);
uniform vec3 metal_light : source_color = vec3(0.90, 0.94, 0.96);
uniform vec3 glow : source_color = vec3(0.0);
uniform float glow_power = 0.0;
uniform float heat = 0.0;

void fragment() {
	vec3 c = texture(albedo, UV).rgb * base;
	float high = max(c.r, max(c.g, c.b));
	float low = min(c.r, min(c.g, c.b));
	float saturation = high > 0.0 ? (high - low) / high : 0.0;
	float metal = step(saturation, 0.3) * step(0.04, high);
	float light = smoothstep(0.05, 0.45, high);
	c = mix(c, mix(metal_dark, metal_light, light) * 0.8, metal);
	vec3 hot = mix(vec3(0.85, 0.2, 0.05), vec3(1.0, 0.95, 0.65), heat * (0.6 + 0.4 * light));
	c = mix(c, hot, metal * clamp(heat * 1.2, 0.0, 0.9));
	ALBEDO = c;
	ROUGHNESS = 0.55;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	EMISSION = glow * glow_power * (0.2 + rim) + hot * metal * heat * 1.2;
}
