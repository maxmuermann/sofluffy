shader_type spatial;

render_mode cull_disabled;//, unshaded;

uniform float height = 0;
uniform float h = 0;
uniform float density = 1.0;
uniform sampler2D base_texture : source_color, filter_nearest;


uniform float thickness = 1;

uniform vec3 physics_pos_offset = vec3(0.0, -1.0, 0.0);

uniform vec3 color: source_color;

void vertex() {	
	vec3 physics_pos_offset_world = (vec4(physics_pos_offset, 0.0) * MODEL_MATRIX).xyz * h * 0.2;
	VERTEX += NORMAL * height * h + physics_pos_offset_world;
}

void fragment() {
	vec2 ts = vec2(textureSize(base_texture, 0)) * density; // texture size in pixels
	vec2 uv = UV * density; // current pixel UV
	vec3 val = texture(base_texture, uv).rgb; // sample length texture
	
	// calculate distance of current pixel from center of texture pixel
	vec2 center = vec2(0.5, 0.5);
	float relDist = pow(length(fract(UV * ts) - center), 2);
	
	//if(val.r >= h) {
	if((val.r - thickness >= relDist) && (h > 0.0)) {
		ALBEDO = color;
	} else {
		discard;
	}
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
