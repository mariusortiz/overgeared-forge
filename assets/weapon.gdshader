shader_type canvas_item;

// Recolours a weapon sprite: its grey metal takes the material's colours,
// its outline takes the rarity's colour, and heat makes the metal glow.

uniform vec3 metal_dark = vec3(0.33, 0.34, 0.39);
uniform vec3 metal_light = vec3(0.90, 0.94, 0.96);
uniform vec4 outline = vec4(0.0);
uniform float heat = 0.0;
uniform float silhouette = 0.0;

// The outline colour used by every sprite of the weapon pack.
const vec3 PACK_OUTLINE = vec3(0.227, 0.412, 0.518);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (c.a > 0.5) {
		if (distance(c.rgb, PACK_OUTLINE) < 0.08) {
			c = outline;
		} else {
			float high = max(c.r, max(c.g, c.b));
			float low = min(c.r, min(c.g, c.b));
			float saturation = high > 0.0 ? (high - low) / high : 0.0;
			if (saturation < 0.22 && high > 0.3) {
				float light = smoothstep(0.35, 0.96, high);
				c.rgb = mix(metal_dark, metal_light, light);
				vec3 hot = mix(vec3(0.85, 0.2, 0.05), vec3(1.0, 0.95, 0.65), heat * (0.6 + 0.4 * light));
				c.rgb = mix(c.rgb, hot, clamp(heat * 1.2, 0.0, 0.9));
			}
			c.rgb = mix(c.rgb, vec3(0.13, 0.12, 0.17), silhouette);
		}
	}
	COLOR = c;
}
