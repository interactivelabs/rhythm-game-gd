shader_type canvas_item;
// Moonlight colour grade for everything drawn beneath this rect (the world).
// No night art needed: the day colours are desaturated, tinted from deep blue
// (dark areas) to pale blue (bright areas), dimmed, and darkened with distance
// from a light point (the player). Used by NightOverlay, which fades `amount`
// in and keeps `light_center` on the player.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
// 0 = day (untouched), 1 = full night.
uniform float amount : hint_range(0.0, 1.0) = 0.0;
// How much colour is removed (0 = full colour, 1 = greyscale).
uniform float desaturation : hint_range(0.0, 1.0) = 0.6;
// Tint for the darkest and brightest parts of the image.
uniform vec3 shadow_tint : source_color = vec3(0.12, 0.16, 0.35);
uniform vec3 highlight_tint : source_color = vec3(0.75, 0.85, 1.0);
// Overall light level at night.
uniform float brightness : hint_range(0.0, 2.0) = 0.85;
// Where the light is, in screen UV (0-1). Set every frame from the player.
uniform vec2 light_center = vec2(0.5, 0.5);
// Fully lit within light_inner, fading to full darkness at light_outer.
// Both are measured in screen heights.
uniform float light_inner : hint_range(0.0, 2.0) = 0.25;
uniform float light_outer : hint_range(0.0, 3.0) = 1.4;
// How dark it gets far from the light (0 = no darkening).
uniform float darkness : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec3 day = texture(screen_texture, SCREEN_UV).rgb;
	float lum = dot(day, vec3(0.299, 0.587, 0.114));
	vec3 night = mix(day, vec3(lum), desaturation);
	night *= mix(shadow_tint, highlight_tint, lum) * brightness;
	// Distance to the light in screen heights, so the light is round.
	vec2 aspect = vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	float dist = length((SCREEN_UV - light_center) * aspect);
	night *= 1.0 - darkness * smoothstep(light_inner, light_outer, dist);
	COLOR = vec4(mix(day, night, amount), 1.0);
}
