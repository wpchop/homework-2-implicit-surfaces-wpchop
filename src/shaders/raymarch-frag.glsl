#version 300 es

precision highp float;

out vec4 out_Col;
in vec4 fs_Pos;

uniform vec2 u_Screen;


const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;

/**
 * Signed distance function for a sphere centered at the origin with radius 1.0;
 */
float sphereSDF(vec3 samplePoint) {
    return length(samplePoint) - 1.0;
}

/**
 * Signed distance function describing the scene.
 * 
 * Absolute value of the return value indicates the distance to the surface.
 * Sign indicates whether the point is inside or outside the surface,
 * negative indicating inside.
 */
float sceneSDF(vec3 samplePoint) {
    return sphereSDF(samplePoint);
}

/**
 * Return the shortest distance from the eyepoint to the scene surface along
 * the marching direction. If no part of the surface is found between start and end,
 * return end.
 * 
 * eye: the eye point, acting as the origin of the ray
 * marchingDirection: the normalized direction to march in
 * start: the starting distance away from the eye
 * end: the max distance away from the ey to march before giving up
 */
float shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = sceneSDF(eye + depth * marchingDirection);
        if (dist < EPSILON) {
			return depth;
        }
        depth += dist;
        if (depth >= end) {
            return end;
        }
    }
    return end;
}

/**
 * Return the normalized direction to march in from the eye point for a single pixel.
 * 
 * fieldOfView: vertical field of view in degrees
 * size: resolution of the output image
 * fragCoord: the x,y coordinate of the pixel in the output image
 */
vec3 rayDirection(float fov, vec2 uv) {
	float width = u_Screen.x;
	float height = u_Screen.y;
	float aspect = width/height;

	float px = uv.x * tan(radians(fov)) * aspect;
	float py = uv.y * tan(radians(fov));
	
	vec3 ray_Origin = vec3(0.0); 
	float z = height / tan(radians(fov) / 2.0);
    vec3 ray_Dir = vec3(px, py, z) - ray_Origin;

	return normalize(ray_Dir);

	//
    // vec2 xy = fragCoord - size / 2.0;
    // float z = size.y / tan(radians(fov) / 2.0);
    // return normalize(vec3(xy, -z));
}

void main() {
	float width = u_Screen.x;
	float height = u_Screen.y;
	float aspect = width/height;

	// TODO: make a Raymarcher!
	float sx = fs_Pos.x;
	float sy = fs_Pos.y;

	vec3 eye = vec3(0.0, 0.0, 3.0);
	vec3 ref = vec3(0.0, 0.0, -1.0);
	float len = length(ref - eye);
	vec3 U = vec3(0.0,1.0,0.0);
	vec3 R = vec3(1.0,0.0,0.0);

	float fov = 45.0;
	vec3 V = U * len * tan(radians(fov/2.0));
	vec3 H = R * len * aspect * tan(radians(fov/2.0));

	vec3 dir = normalize(ref + sx * H + sy * V);

	// out_Col = vec4(fs_Pos.x, fs_Pos.y, 0.0, 1.0);
	// vec3 dir = rayDirection(45.0, vec2(u, v));
    // vec3 eye = vec3(0.0, 0.0, 0.0);
    float dist = shortestDistanceToSurface(eye, dir, MIN_DIST, MAX_DIST);
    
    if (dist > MAX_DIST - EPSILON) {
        // Didn't hit anything
        out_Col = vec4(dir, 1.0);
		return;
    }
    
    out_Col = vec4(1.0, 0.0, 0.0, 1.0);
	// out_Col = vec4(normalize(dir), 1.0);
}
