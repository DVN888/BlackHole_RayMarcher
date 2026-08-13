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
//hit struct ; hit point ; hit length ; hit direction ; total density ; hit material
struct sHit {vec3 position;float totalLength; vec3 direction; float density; int mat;};
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

float rand2D(in vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453)/2+0.5; //from 0.5 to 1.0
}

float rand3D(in vec3 co){
    return fract(sin(dot(co.xyz ,vec3(12.9898,78.233,144.7272))) * 43758.5453);
}

vec2 mix2(vec2 v1, vec2 v2, vec2 a)
{
    return vec2(mix(v1.x,v2.x,a.x),mix(v1.y,v2.y,a.y));
}

//i forgot from where i think that one webgl ashima/webgl-noise
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
//until here
//from https://www.science-and-fiction.org/rendering/noise.html#perlin_noise
float dotNoise2D(in float x, in float y, in float fractionalMaxDotSize, in float dDensity)
{
    float integer_x = x - fract(x);
    float fractional_x = x - integer_x;

    float integer_y = y - fract(y);
    float fractional_y = y - integer_y;

    if (rand2D(vec2(integer_x+1.0, integer_y +1.0)) > dDensity)
    {return 0.0;}

    float xoffset = (rand2D(vec2(integer_x, integer_y)) -0.5);
    float yoffset = (rand2D(vec2(integer_x+1.0, integer_y)) - 0.5);
    float dotSize = 0.5 * fractionalMaxDotSize * max(0.25,rand2D(vec2(integer_x, integer_y+1.0)));

    vec2 truePos = vec2 (0.5 + xoffset * (1.0 - 2.0 * dotSize) , 0.5 + yoffset * (1.0 -2.0 * dotSize));

    float distance = length(truePos - vec2(fractional_x, fractional_y));

    return 1.0 - smoothstep (0.3 * dotSize, 1.0* dotSize, distance);

}
float simple_interpolate(in float a, in float b, in float x)
{
    return a + smoothstep(0.0,1.0,x) * (b-a);
}
float interpolatedNoise3D(in float x, in float y, in float z)
{
    float integer_x = x - fract(x);
    float fractional_x = x - integer_x;

    float integer_y = y - fract(y);
    float fractional_y = y - integer_y;

    float integer_z = z - fract(z);
    float fractional_z = z - integer_z;

    float v1 = rand3D(vec3(integer_x, integer_y, integer_z));
    float v2 = rand3D(vec3(integer_x+1.0, integer_y, integer_z));
    float v3 = rand3D(vec3(integer_x, integer_y+1.0, integer_z));
    float v4 = rand3D(vec3(integer_x+1.0, integer_y +1.0, integer_z));

    float v5 = rand3D(vec3(integer_x, integer_y, integer_z+1.0));
    float v6 = rand3D(vec3(integer_x+1.0, integer_y, integer_z+1.0));
    float v7 = rand3D(vec3(integer_x, integer_y+1.0, integer_z+1.0));
    float v8 = rand3D(vec3(integer_x+1.0, integer_y +1.0, integer_z+1.0));

    float i1 = simple_interpolate(v1,v5, fractional_z);
    float i2 = simple_interpolate(v2,v6, fractional_z);
    float i3 = simple_interpolate(v3,v7, fractional_z);
    float i4 = simple_interpolate(v4,v8, fractional_z);

    float ii1 = simple_interpolate(i1,i2,fractional_x);
    float ii2 = simple_interpolate(i3,i4,fractional_x);

    return simple_interpolate(ii1 , ii2 , fractional_y);
}

float Noise3D(in vec3 coord, in float wavelength)
{
    return interpolatedNoise3D(coord.x/wavelength, coord.y/wavelength, coord.z/wavelength);
}
// science and fiction end
vec3 noiseComplete(in vec3 Dir, in float time)
{
    //colors
    const vec3 clFog = vec3(0.361, 0.337, 0.278);
    const vec3 clSmallStarsOrange = vec3(1.0,0.85,0.75);
    const vec3 clBigStars = vec3(0.88,0.88,1.0);
    const vec3 clBase = vec3(0.1,0.093,0.213);
    const vec3 clGalaxy1 = vec3(0.282, 0.29, 0.141);

    vec2 noisePos;
    //vectors for dot products are random Basisvektoren from random Orthonormalbasen
    //fog
    noisePos = vec2(dot(vec3(0,0.9216353751,0.3880570000),Dir),
                    dot(vec3(0.5168869748,-0.3321976121,0.7889693287),Dir))*2;
    float fogval = snoise(noisePos);
    vec3 fog = fogval*fogval*fogval*clFog;
    //stars
    noisePos = vec2(dot(vec3(-0.6085806194,0.4260064336,-0.6694386813),Dir),
                         dot(vec3(0.0695795410,-0.8117613123,-0.5798295088),Dir))*2.123456789;
    vec3 smallStars = clSmallStarsOrange*dotNoise2D(noisePos.x,noisePos.y,0.02,5.123456789);
    noisePos = vec2(dot(vec3(0.1944974411,0.8298557490,0.5229820084),Dir),
                    dot(vec3(0.8741572761,-0.3885143449,0.2913857587),Dir))*2.123456789;
    vec3 bigStars = clBigStars*dotNoise2D(noisePos.x,noisePos.y,0.08,1.0);

    //base
    const float wavelength = 0.25;
    vec3 base = clBase*(Noise3D(Dir+1,wavelength)
                      + Noise3D(Dir-1,wavelength*0.5)*0.5
                      + Noise3D(Dir+vec3(1,-1,0),wavelength*0.25)*0.25
                      + Noise3D(Dir+vec3(-1,0,1),wavelength*0.125)*0.125);

    //galaxy1
    const float wavelengthG1 = 0.15;
    float g1val = (Noise3D(Dir+vec3(-7.432,-4.874,-8.9812),wavelengthG1)*Noise3D(Dir+vec3(2.75,9.93,-9.28734),wavelengthG1))
                      * (Noise3D(Dir+vec3(-10.1526,6.56894,10.532),wavelengthG1/3)
                      + Noise3D(Dir+vec3(2.637,-3.67676,4.6143),wavelengthG1/9)/3
                      + Noise3D(Dir+vec3(-6.12343,7.927364,8.6352),wavelengthG1/27)/9);
    g1val = g1val * g1val;
    vec3 G1 = clGalaxy1*g1val;

    //return base;
    return (fog + smallStars*smallStars + bigStars*bigStars + base + G1);
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
    float radial = -0.8*abs(length(p.xyz)-biggerRadius);
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
    ray.stepSize *= rand2D(pos.zx);
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
    hit.direction = ray.direction;
    hit.density = 0;
    hit.mat = 1; //if i reaches maxIter, it means the ray is orbiting outside photon sphere. return hit material as glowing.
    for(int i = 0;i<maxIter;i++){
        hit.position += ray.direction;
        hit.density += densityFieldAVG(hit.position)*ray.stepSize;
        hit.totalLength += ray.stepSize;
        hit.direction = normalize(ray.direction);
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

vec3 getColor(in sHit hit, in vec3 startDir, in float time)
{
    float avgDensity = hit.density*hit.totalLength;
    hit.mat = 1;
    switch(hit.mat) {
        case 0:
            //return max(vec3(avgDensity-0.5,(avgDensity-0.5)/2,(avgDensity-0.5)/8),vec3(0,0,0));
            return vec3(avgDensity,avgDensity/2,avgDensity/8);
            break;
        case 1:
            return vec3(avgDensity,avgDensity/2,avgDensity/8) + noiseComplete(hit.direction, time)/(avgDensity+1);
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
    return getColor(hit, startDir, uTimeSeconds);
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