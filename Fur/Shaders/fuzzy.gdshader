shader_type spatial;

render_mode cull_disabled; //, unshaded

uniform float height = 0;
uniform float normal_strength = 1.0;
uniform vec3 static_direction_local = vec3(0.0,0.0,0.0);
uniform vec3 static_direction_world = vec3(0.0,0.0,0.0);
uniform float h = 0;
uniform float density = 1.0;
uniform sampler2D base_texture : source_color, filter_nearest;
uniform sampler2D displacement_noise : filter_nearest;
uniform float displacement_noise_strength = 0.5;


uniform float thickness = 1;

uniform vec3 physics_pos_offset = vec3(0.0, -1.0, 0.0);

uniform vec3 color: source_color;

void vertex() {	
	vec3 physics_pos_offset_world = (vec4(physics_pos_offset, 0.0) * MODEL_MATRIX).xyz * h * 0.2;
	vec3 direction = static_direction_local + (vec4(static_direction_world, 0.0) * MODEL_MATRIX).xyz;
	VERTEX += (NORMAL * normal_strength + direction * (1.0 - normal_strength)) * height * h + physics_pos_offset_world;
}

void fragment() {
	vec2 ts = vec2(textureSize(base_texture, 0)) * density; // texture size in pixels
	
	vec2 xy = UV + (texture(displacement_noise, UV).xy - vec2(0.5, 0.5)) * displacement_noise_strength;
	
	vec2 uv = xy * density; // current pixel UV
	vec3 val = texture(base_texture, uv).rgb; // sample length texture
	
	// calculate distance of current pixel from center of texture pixel
	vec2 center = vec2(0.5, 0.5);
	float relDist = pow(length(fract(xy * ts) - center), 2);
	
	//if(val.r >= h) {
	if((val.r - thickness >= relDist)) {
		if(!FRONT_FACING) NORMAL = -NORMAL;
		ALBEDO = color;
	} else {
		discard;
	}
}

void light() {
	// LAMBERT
	//DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR;
	
	// HALF-LAMBERT
	float d = dot(NORMAL, LIGHT) / 2.0 + 0.5;
	DIFFUSE_LIGHT += d * d * ATTENUATION * LIGHT_COLOR;
}
