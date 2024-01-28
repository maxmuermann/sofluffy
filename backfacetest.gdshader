shader_type spatial;

render_mode cull_disabled;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO = vec3(1,1,1);
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
