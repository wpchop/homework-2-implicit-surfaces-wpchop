#version 300 es
precision highp float;


/** Most of this shader is borrowed from IQ's blog**/

out vec4 out_Col;
in vec4 fs_Pos;

uniform vec2 u_Screen;
uniform vec3 u_Eye;
uniform vec3 u_Up;
uniform mat4 u_View;
uniform float u_Time;
uniform sampler2D u_Texture;

const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;
const vec3 LIGHT = vec3(0.0,2.0,1.0);

/**
 * Rotation matrix around the Y axis.
 */
mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

/**
 * Rotation matrix around the Z axis.
 */
mat3 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, -s, 0),
        vec3(s, c, 0),
        vec3(0, 0, 1)
    );
}

// Intersection
float opI( float d1, float d2 )
{
    return max(d1,d2);
}

// Subtraction
float opS( float d1, float d2 )
{
    return max(-d1,d2);
}

/**
 * Signed distance function for a sphere centered at the origin with radius 1.0;
 */
float sphereSDF(vec3 samplePoint) {
    return length(samplePoint) - 1.0;
}

float udBox( vec3 p, vec3 b )
{
  return length(max(abs(p)-b,0.0));
}

float sdPlane( vec3 p, vec4 n )
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}

/**
 * Union function, from IQ's blog:
 * http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
 */
float opU( float d1, float d2 )
{
    return min(d1,d2);
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdCylinder( vec3 p, vec3 c )
{
  return length(p.xz-c.xy)-c.z;
}

float spinnyThing(vec3 samplePoint) {
	samplePoint = rotateY(u_Time / 20.0) * samplePoint;
	vec3 cylinderPoint = rotateZ(u_Time / 10.0) * samplePoint;

	// Intersection
    float sphereBox = opI(sphereSDF(samplePoint), udBox(samplePoint, vec3(0.8)));
	float cylinder = sdCylinder(cylinderPoint + vec3(1.0,1.0,1.0), vec3(0.3));
	float cylinder2 = sdCylinder(cylinderPoint + vec3(0.0, 0.0, 1.0), vec3(0.3));
	float cylinder3 = sdCylinder(cylinderPoint + vec3(1.0, 1.0, -0.5), vec3(0.3));

	// Union
	float twoCylinder = opU(sdCylinder(cylinderPoint + vec3(0.0, 0.0, -0.5), vec3(0.3)), cylinder3);

	// Subtraction
	float subtract2 = opS(cylinder2, opS(cylinder, sphereBox));
	float subtract3 = opS(twoCylinder, subtract2);
	return subtract3;
}

// /**
// * Repetition, from IQ's blog
// */
float opRep( vec3 p, vec3 c )
{
    vec3 q = mod(p,c)-0.5*c;
    return spinnyThing( q );
}


/**
 * Signed distance function describing the scene.
 * 
 * Absolute value of the return value indicates the distance to the surface.
 * Sign indicates whether the point is inside or outside the surface,
 * negative indicating inside.
 */
float sceneSDF(vec3 samplePoint) {
	return opRep(samplePoint, vec3(3.0, 3.0, 5.0));
}

/**

 * From https://www.shadertoy.com/view/llt3R4
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
 * Jamie Wong: http://jamie-wong.com/2016/07/15/ray-marching-signed-distance-functions/#surface-normals-and-lighting
 * Using the gradient of the SDF, estimate the normal on the surface at point p.
 */
vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

void main() {
	float width = u_Screen.x;
	float height = u_Screen.y;
	float aspect = width/height;

	// TODO: make a Raymarcher!

	float sx = fs_Pos.x;
	float sy = fs_Pos.y;

	// making ray
	// vec3 eye = vec3(0.0, 0.0, 3.0);
	// vec3 ref = vec3(0.0, 0.0, -1.0);
	// float len = length(ref - eye); 
	// vec3 U = vec3(0.0,1.0,0.0);
	// vec3 R = cross(ref, U);

///////////////// Using camera
	vec3 eye = -vec3(u_View[0].w, u_View[1].w, u_View[2].w);
	vec3 R = normalize(vec3(u_View[0].x, u_View[0].y, u_View[0].z));
	vec3 U = normalize(vec3(u_View[1].x, u_View[1].y, u_View[1].z));
	vec3 ref = vec3(u_View[2].x, u_View[2].y, u_View[2].z);
	float len = length(ref - eye); 

///////////////////
	
	float fov = 45.0;
	vec3 V = U * len * tan(radians(fov/2.0));
	vec3 H = R * len * aspect * tan(radians(fov/2.0));

	// Ray direction
	vec3 dir = normalize(ref + sx * H + sy * V - eye);

    float dist = shortestDistanceToSurface(eye, dir, MIN_DIST, MAX_DIST);

    if (dist > MAX_DIST - EPSILON) {
        // Didn't hit anything
		vec3 color1 = vec3(130.0/255.0, 53.0/255.0 ,128.0/255.0);
		vec3 color2 = vec3(90.0/255.0, 213.0/255.0, 240.0/255.0);

		vec3 color = color1 * cos(u_Time / 20.0) + color2 * sin(u_Time / 20.0);
		color = normalize( abs( dir * cos(u_Time / 20.0)) + abs (color1 * sin(u_Time / 15.0)) );

        out_Col = vec4(color, 1.0);
		return;
    }
	vec3 p = eye + dir * dist;
    vec3 normal = estimateNormal(p);

	// Referenced Aman Sachan's matcap shading vertex shader
	// https://github.com/Aman-Sachan-asach/Metaballic-Lava-Lamp/
	vec3 reflected = reflect(dir, normal);
	float x = reflected.x / (2.0 * sqrt(pow(reflected.x, 2.0) + 
								       pow(reflected.y, 2.0) + 
        							   pow(reflected.z + 1.0, 2.0))) + 0.5;
	
	float y = reflected.y / (2.0 * sqrt(pow(reflected.x, 2.0) + 
								       pow(reflected.y, 2.0) + 
        							   pow(reflected.z + 1.0, 2.0))) + 0.5;

	vec2 texCoord = vec2(x,y);

	vec4 color1 = texture(u_Texture, texCoord);
	out_Col = color1;
}
