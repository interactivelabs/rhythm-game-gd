shader_type canvas_item;
// Soft, flickering light around a fire: a warm radial glow added on top of
// what's underneath (blend_add), so it brightens the ground and walls nearby
// like real light instead of covering them. Drawn after the night grade (the
// campfire is at z 15, the grade at z 10), so it stays warm against the blue.
// Put it on a square ColorRect centred on the flame; the rect's size is the
// light's reach. The node's modulate (e.g. a night fade) dims it as a whole.
render_mode blend_add, unshaded;

// Colour of the light.
uniform vec3 glow_color : source_color = vec3(1.0, 0.55, 0.2);
// Brightness at the centre.
uniform float intensity : hint_range(0.0, 2.0) = 0.8;
// Higher = light falls off faster from the centre (a tighter glow).
uniform float falloff : hint_range(0.5, 6.0) = 2.2;
// How much the light flickers (0 = steady) and how fast.
uniform float flicker_strength : hint_range(0.0, 1.0) = 0.18;
uniform float flicker_speed : hint_range(0.0, 20.0) = 7.0;

varying float phase;

void vertex() {
	// Different fires flicker out of step: phase from the fire's height on
	// screen (fixed per building; x changes as the world scrolls).
	phase = MODEL_MATRIX[3].y * 0.37;
}

void fragment() {
	float dist = length(UV - 0.5) * 2.0; // 0 at the centre, 1 at the rect's edge
	float glow = pow(clamp(1.0 - dist, 0.0, 1.0), falloff);
	float t = TIME * flicker_speed + phase;
	// A few sine waves at odd ratios: irregular, fire-like flicker.
	float flicker = 1.0 + flicker_strength * (0.5 * sin(t) + 0.3 * sin(t * 2.3 + 1.7) + 0.2 * sin(t * 5.1 + 0.4));
	COLOR = vec4(glow_color, COLOR.a * glow * intensity * flicker);
}
