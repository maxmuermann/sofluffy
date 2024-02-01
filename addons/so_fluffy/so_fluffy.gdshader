shader_type spatial;

render_mode cull_disabled; //, unshaded

uniform float height = 0;
uniform float normal_strength = 1.0;
uniform vec3 static_direction_local = vec3(0.0,0.0,0.0);
uniform vec3 static_direction_world = vec3(0.0,0.0,0.0);
uniform float h = 0;
uniform float density = 1.0;
uniform float sparseness = 0.5;
uniform sampler2D heightmap_texture : source_color, filter_nearest;
uniform sampler2D turbulence_texture : filter_linear;
uniform float turbulence_strength = 0.5;
uniform float turbulence_bendiness = 0.5;

uniform vec3 color: source_color;
uniform sampler2D height_gradient: source_color, filter_nearest;
uniform bool scale_height_gradient = true;
uniform bool use_albedo_texture = false;
uniform sampler2D albedo_texture : source_color;

uniform bool use_emission = false;
uniform vec3 emission_color: source_color;
uniform float emission_energy_multiplier;
uniform bool use_emission_texture = false;
uniform sampler2D emission_texture : source_color;


uniform sampler2D thickness_curve;
uniform float thickness_scale = 1.0;

// physics
uniform vec3 physics_pos_offset = vec3(0.0, 0.0, 0.0);
uniform mat3 physics_rot_offset;

// Gold Noise ©2015 dcerisano@standard3d.com
// - based on the Golden Ratio
// - uniform normalized distribution
// - fastest static noise generator function (also runs at low precision)
// - use with indicated fractional seeding method. 
// @see https://www.shadertoy.com/view/ltB3zD
float gold_noise(vec2 p) {
	vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void vertex() {	
	vec3 physics_pos_offset_world = (vec4(physics_pos_offset, 0.0) * MODEL_MATRIX).xyz * h * 0.2;
	vec3 direction = static_direction_local + (vec4(static_direction_world, 0.0) * MODEL_MATRIX).xyz;
	VERTEX += (NORMAL * normal_strength + direction * (1.0 - normal_strength)) * height * h + physics_pos_offset_world;
	VERTEX = VERTEX * physics_rot_offset;
}

void fragment() {	
	vec2 uv = UV * density; // current pixel UV, scaled by density
	
	float ts = 1024.0;
	
	vec2 turbulence = texture(turbulence_texture, uv).xy - vec2(0.5, 0.5);
	
	vec2 displacement = turbulence * turbulence_strength * 0.1;
	vec2 xy = uv + displacement * pow((1.0 - h * 0.5), 1.0 * turbulence_strength) * 1.0
	;
	
	// density noise
	float len = pow(gold_noise(floor(xy * 1024.0)), sparseness);
	
	vec3 val = texture(heightmap_texture, UV).rgb; // sample heightmap length texture at original UV - we don't care how far the strand has been displaced
	len *= val.r;
	
	// calculate distance of current pixel from center of texture pixel
	vec2 center = vec2(0.5, 0.5);
	float relDist = length(fract(xy * ts) - center) / thickness_scale * 2.0;
	
	float thickness = texture(thickness_curve, vec2(h * 0.99, 0.0)).r;
	
	if((len - thickness >= relDist)) {
		if(!FRONT_FACING) NORMAL = -NORMAL;
		vec3 col = color;
		
		// sample height gradient
		float grad_h = h;
		if(scale_height_gradient) {
			grad_h /= len;
		}
		vec3 height_col = texture(height_gradient, vec2(grad_h * 0.999, 0.0)).rgb;
		col *= height_col;
		
		if(use_albedo_texture) {
			col *= texture(albedo_texture, UV).rgb;
		}
		ALBEDO = col;
		if(use_emission) {
			vec3 emission = emission_color;
			if(use_emission_texture) {
				emission += texture(emission_texture, UV).rgb;
			}
			EMISSION = emission * emission_energy_multiplier;
		}
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
