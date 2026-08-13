#type vertex
#version 330 core
layout (location=0) in vec3 aPos;
layout (location=1) in vec4 aColor;

out vec4 fColor;

void main()
{
    fColor = aColor;
    gl_Position = vec4(aPos, 1.0);
}

#type fragment
#version 330 core

in vec4 fColor;

out vec4 color;

uniform vec2 uResolution;
uniform vec3 uCamPos;
uniform vec3 uCamDir; //FL later
uniform vec3 uCamUp;
uniform vec3 uCamRight;
uniform float uTimeSeconds;
//ray struct ; ray origin ; ray direction ; step size
struct sRay {vec3 origin; vec3 direction; float stepSize;};
//hit struct ; hit point ; hit length ; total steps ; total density ; hit material
struct sHit {vec3 position;float totalLength; float totalSteps; float density; int mat;};
//                                                                  0:Photon Sphere(black)  1:background with glow

//material struct ; color ;
const float PSphereRadius = 2.5f;
const float biggerRadius = 1.4*PSphereRadius;
const float EHRadius = PSphereRadius/4;

const int MAX_ITER = 256;
const float MAX_LENGTH = 64;
const float MIN_STEP_SIZE = 0.078125;
float MAX_STEP_SIZE = length(uCamPos)*length(uCamPos)/405;

//SDF===============================================================SDF
//by Inigo Quilez
float sdSphere( in vec3 p, in float r )
{
    return length(p) - r;
}

float rand(in vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453)/2+0.5; //from 0.5 to 1.0
}

vec2 mix2(vec2 v1, vec2 v2, vec2 a)
{
    return vec2(mix(v1.x,v2.x,a.x),mix(v1.y,v2.y,a.y));
}

vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
    0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
    -0.577350269189626,  // -1.0 + 2.0 * C.x
    0.024390243902439); // 1.0 / 41.0
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);
    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289(i); // Avoid truncation effects in permutation
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
    + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

//idek i just found this lol
//                campos seed,  time in sec
float randSpecs(in vec3 pos, in float time)
{
    vec3 modified = vec3(pos.x+sin(cos(time/15)), pos.y+cos(sin(time*0.6366197724/15)), pos.z+cos(time/15)+sin(time/15));
    //basically vec2 = radial dist , vertical dist
    //                   only pos      neg and pos
    vec2 chopped = vec2(distance(modified.xz,vec2(0,0)),modified.y);
    vec2 i = floor(chopped);
    vec2 f = fract(chopped);
    //vec2 u = f*f*(3.0-2.0*f);
    vec2 u = f;
    vec2 result = mix2(noise2(i),
                       noise2(i+vec2(1.0,1.0)),
                       u);
    return (result.x+result.y);
}

//distance field=========================================distance field
//pure distance field, no hit info
float distanceField( in vec3 p )
{
    return sdSphere(p,EHRadius);
}

//density field for the accretion disk
float densityField( in vec3 p)
{
    float radial = -0.8*abs(length(p.xz)-biggerRadius);
    float vertical = -12*abs(p.y);
    return exp(radial+vertical);
}

float densityFieldAVG(in vec3 p)
{
    vec3 offset = vec3(0.05,0,0);
    float dense = densityField(p-offset.xyy)
                 +densityField(p-offset.yxy)
                 +densityField(p-offset.yyx)
                 +densityField(p-offset.xxx);
    return dense/4;
}
//march===========================================================march
void initRay( in vec2 uv, out sRay ray)
{
    ray.origin = uCamPos;
    ray.stepSize = MIN_STEP_SIZE;
    ray.direction = uCamDir-uCamUp-uResolution.x/uResolution.y*uCamRight;
    ray.direction += 2*uv.y*uCamUp+2*uv.x*uResolution.x/uResolution.y*uCamRight;
    ray.direction = ray.stepSize * normalize(ray.direction);
}

float getGravityConstant( in float stepSize)
{
    float sqrRadius = PSphereRadius*PSphereRadius;
    return sqrRadius * (sqrt(stepSize*stepSize+sqrRadius)-PSphereRadius);
}

void updateRay(in vec3 pos, inout sRay ray)
{
    ray.stepSize = MAX_STEP_SIZE*smoothstep(biggerRadius,length(ray.origin),length(pos))+MIN_STEP_SIZE;
    ray.stepSize *= rand(pos.zx);
    float G = getGravityConstant(ray.stepSize);
    vec3 force = -G*pos;
    force /= dot(pos,pos)*length(pos);
    ray.direction = ray.stepSize * normalize(ray.direction);
    ray.direction += force;
    ray.direction = ray.stepSize * normalize(ray.direction);
}

void march(in sRay ray, out sHit hit, in int maxIter, in float maxLength)
{
    const float epsilon = 1E-2;
    float squaredOrigin = dot(ray.origin,ray.origin);
    hit.position = ray.origin;
    //also need hit direction for background
    hit.totalSteps = 0;
    hit.density = 0;
    hit.mat = 1; //if i reaches maxIter, it means the ray is orbiting outside photon sphere. return hit material as glowing.
    for(int i = 0;i<maxIter;i++){
        hit.position += ray.direction;
        hit.density += densityFieldAVG(hit.position)*ray.stepSize;
        hit.totalLength += ray.stepSize;
        hit.totalSteps++;
        // if                           escaped           or                   hit EH                 or      enough samples
        //render                background and glow                             black                       background and glow
        if(!(dot(hit.position,hit.position)<squaredOrigin+1)||!(distanceField(hit.position)>epsilon)||!(hit.totalLength<maxLength)) {
            hit.mat = 1; //say its background time
            break;
        }

        updateRay(hit.position,ray);
    }
    if(!(distanceField(hit.position)>0.1)){
        hit.mat = 0;       //if it actually EH/inside Photon Sphere
    }
}

vec3 getColor(in sHit hit, in vec3 startDir)
{
    float avgDensity = hit.density*hit.totalLength;
    switch(hit.mat) {
        case 0:
            return max(vec3(avgDensity-0.5,(avgDensity-0.5)/2,(avgDensity-0.5)/8),vec3(0,0,0));
            break;
        case 1:
            vec3 noiser;
            float val = snoise(startDir);
            return vec3(avgDensity,avgDensity/2,avgDensity/8) + val;
            break;
        default:
            return vec3(1,0,1);
            break;
    }
}

vec3 Raymarcher(vec2 uv)
{
    //init ray
    sRay ray;
    initRay(uv,ray);
    vec3 startDir = normalize(ray.direction)/2;
    //call marchRay()
    sHit hit;
    march(ray,hit,MAX_ITER,MAX_LENGTH);
    //return color
    return getColor(hit, startDir);
}

vec3 applyVignette(in vec3 color, in vec2 uv)
{
    float intensity = exp(-length(uCamPos)/2);
    vec3 max = vec3(1,1,1);
    uv -= 0.5;
    uv *= 2;
    uv.x *= (float(uResolution.x) /uResolution.y);
    float multiplier = exp(-length(uv)*length(uv));
    return color+max*multiplier*intensity;
}

void main()
{
    vec2 uv = gl_FragCoord.xy / uResolution;

    color = vec4(Raymarcher(uv),1.0);
}