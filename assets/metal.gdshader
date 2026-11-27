shader_type spatial;

// Recolours a 3D model: its metal takes the material's colours, the rarity
// adds a glow on its edges, and heat makes the metal red then white.
// What is metal comes from the model's own metal map when it has one (use_map),
// otherwise from its colour: grey is metal.

uniform sampler2D albedo : source_color, filter_linear_mipmap, hint_default_white;
uniform sampler2D metal_map : filter_linear_mipmap, hint_default_white;
uniform sampler2D normal_map : hint_normal, filter_linear_mipmap;
uniform bool use_map = false;
uniform bool use_normal = false;
uniform vec3 base : source_color = vec3(1.0);
uniform vec3 metal_dark : source_color = vec3(0.33, 0.34, 0.39);
uniform vec3 metal_light : source_color = vec3(0.90, 0.94, 0.96);
uniform vec3 glow : source_color = vec3(0.0);
uniform float glow_power = 0.0;
uniform float heat = 0.0;

void fragment() {
	vec3 c = texture(albedo, UV).rgb * base * COLOR.rgb;
	float high = max(c.r, max(c.g, c.b));
	float low = min(c.r, min(c.g, c.b));
	float saturation = high > 0.0 ? (high - low) / high : 0.0;
	float metal = step(saturation, 0.3) * step(0.04, high);
	float light = smoothstep(0.05, 0.45, high);
	if (use_map) {
		metal = step(0.5, texture(metal_map, UV).b);
		light = smoothstep(0.02, 0.5, dot(c, vec3(0.3, 0.5, 0.2)));
	}
	c = mix(c, mix(metal_dark, metal_light, light) * 0.8, metal);
	vec3 hot = mix(vec3(0.85, 0.2, 0.05), vec3(1.0, 0.95, 0.65), heat * (0.6 + 0.4 * light));
	c = mix(c, hot, metal * clamp(heat * 1.2, 0.0, 0.9));
	ALBEDO = c;
	ROUGHNESS = mix(0.8, 0.4, metal);
	METALLIC = metal * 0.3;
	if (use_normal) {
		NORMAL_MAP = texture(normal_map, UV).rgb;
	}
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	EMISSION = glow * glow_power * (0.2 + rim) + hot * metal * heat * 1.2;
}
