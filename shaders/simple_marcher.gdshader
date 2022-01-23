shader_type spatial;
render_mode unshaded, world_vertex_coords, cull_disabled;
varying vec3 cameraPosition;
varying vec3 pos;

uniform int max_steps = 300;
uniform float max_dist = 1000.0;
const float SURF_DIST = 1e-3;

float sphere_sdf(vec3 p, float r, vec3 offset) {
	float dist = distance(p, offset) - r;
	return dist;
}

float mandelbulb_sdf(vec3 p, float power, int iterations) {
	vec3 z = p;
	float dr = 1.0;
	float r = 0.0;
	
	for (int i = 0; i < iterations; i++) {
		r = length(z);
		if (r > 2.0) {
			break;
		}
		
		float theta = acos(z.z / r) * power;
		float phi = atan(z.y, z.x) * power;
		dr = pow(r, power - 1.0) * power * dr + 1.0;
		
		float zr = pow(r, power);
		z = zr * vec3 (sin (theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
		z += p;
	}
	return 0.5 * log(r) * r / dr;
}

float smoothMin(float x, float y, float sc) {
	float h = max(sc-abs(x - y), 0) / sc;
	return min(x, y) - h*h*h*sc*1.0/6.0;
}

vec2 march(vec3 ray_origin, vec3 ray_direction) {
	float dOrigin = 0.0;
	float dSurface;
	float total_steps = 0.0;
	for (int i = 0; i < max_steps; i++) {
		total_steps ++;
		vec3 p = ray_origin + dOrigin * ray_direction;
		//dSurface = sphere_sdf(p, 3.0, vec3(0,0,0));
		float scale = 1.0;
		dSurface = mandelbulb_sdf(p/vec3(scale, scale, scale), 2.5, 13);
		//dSurface = smoothMin(sphere_sdf(p, 2.0, vec3(0,0,0)), sphere_sdf(p, 2.0, vec3(3,0,0)), 3.0);
		dOrigin += dSurface;
		
		if (dSurface < SURF_DIST || dOrigin > max_dist) {
			break;
		}
	}
	return vec2(dSurface, total_steps);
}

void vertex() {
	pos = VERTEX;
	cameraPosition = ( CAMERA_MATRIX * vec4(0,0,0,1)).xyz;
}

void fragment() {
	
	vec3 ray_origin = cameraPosition;
	vec3 ray_direction =  normalize(pos - ray_origin);
	vec2 final_ray = march(ray_origin, ray_direction);
	float total_distance = final_ray.x;
	float total_steps = final_ray.y;
	float outline = min(1.0, total_steps/100.0);
	float value = step(total_distance, 0.5);
	ALBEDO = vec3(outline, outline, outline);
	ALPHA = value;
}