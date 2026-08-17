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
//                                                                   0:Photon Sphere(black)  1:background with glow

const float PSphereRadius = 1.5f;
const float biggerRadius = 1.4*PSphereRadius;
const float EHRadius = 1;

const int MAX_ITER = 256;
const float MIN_STEP_SIZE = 0.078125;
float MAX_STEP_SIZE = length(uCamPos)*length(uCamPos)/405;

float MAX_LENGTH = length(uCamPos)+3*PSphereRadius;
float STEP_SIZE = MAX_LENGTH/MAX_ITER;

float rand2D(in vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453)/2+0.5; //from 0.5 to 1.0
}

float rand3D(in vec3 co){
    return fract(sin(dot(co.xyz ,vec3(12.9898,78.233,144.7272))) * 43758.5453);
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
// from https://thebookofshaders.com/12/
vec3 random3( vec3 p ) {
    return fract(sin(vec3(dot(p,vec3(127.1,311.7,432.9473)),dot(p,vec3(269.5,183.3,67.987)),dot(p,vec3(214.256,658.245,324.678))))*43758.5453);
}

float CellularNoise(vec3 seed, float frequency) {
    vec3 st = seed;
    float color = 0;

    // Scale
    st *= frequency;

    // Tile the space
    vec3 i_st = floor(st);
    vec3 f_st = fract(st);

    float m_dist = 1.;  // minimum distance

    for (int y= -1; y <= 1; y++) {
        for (int x= -1; x <= 1; x++) {
            for (int z= -1; z <= 1; z++) {
                // Neighbor place in the grid
                vec3 neighbor = vec3(float(x), float(y), float(z));

                // Random position from current + neighbor place in the grid
                vec3 point = random3(i_st + neighbor);

                // Animate the point
                //point = 0.5 + 0.5*sin(u_time + 6.2831*point);

                // Vector between the pixel and the point
                vec3 diff = neighbor + point - f_st;

                // Distance to the point
                float dist = length(diff);

                // Keep the closer distance
                m_dist = min(m_dist, dist);
            }
        }
    }

    // Draw the min distance (distance field)
    color += m_dist;

    // Draw cell center
    //color += 1.-step(.02, m_dist);

    // Draw grid
    //color.r += step(.98, f_st.x) + step(.98, f_st.y);

    // Show isolines
    // color -= step(.7,abs(sin(27.0*m_dist)))*.5;

    return color;
}
//
vec3 noiseComplete(in vec3 Dir, in float time)
{
    //colors
    const vec3 clFog = vec3(0.361, 0.337, 0.278);
    const vec3 clSmallStarsOrange = vec3(1.0,0.85,0.75);
    const vec3 clBigStars = vec3(0.88,0.88,1.0);
    const vec3 clBase = vec3(0.1,0.093,0.183);
    const vec3 clGalaxy1 = vec3(0.612, 0.305, 0.609);

    vec2 noisePos;
    //vectors for dot products are random Basisvektoren from random Orthonormalbasen, NOTE: do not touch the magic numbers!!!
    //fog
    noisePos = vec2(dot(vec3(0,0.9216353751,0.3880570000),Dir),
                    dot(vec3(0.5168869748,-0.3321976121,0.7889693287),Dir))*2;
    float fogval = snoise(noisePos);
    vec3 fog = fogval*fogval*fogval*clFog;
    //stars
    noisePos = vec2(dot(vec3(-0.6085806194,0.4260064336,-0.6694386813),Dir),
                         dot(vec3(0.0695795410,-0.8117613123,-0.5798295088),Dir))*2.123456789;
    vec3 smallStars = clSmallStarsOrange*dotNoise2D(noisePos.x,noisePos.y,0.02,5.123456789);
    noisePos = vec2(dot(vec3(0.6085806194,-0.4260064336,0.6694386813),Dir),
    dot(vec3(-0.0695795410,0.8117613123,0.5798295088),Dir))*1.564738219;
    smallStars += clSmallStarsOrange*dotNoise2D(noisePos.x,noisePos.y,0.02,5.123456789);

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
    const float wavelengthG1 = 0.5;
    float g1val =  (CellularNoise(Dir,3.4211472295201472125514)*CellularNoise(Dir,5.1472125514229520421147))*(Noise3D(-Dir,0.2295204211471472125514)+Noise3D(-Dir,0.4211471472125514229520));
    //g1val = g1val/2;
    g1val = exp(-5*(g1val-0.75))+1;
    g1val = 1/g1val;
    g1val *=(Noise3D(Dir,wavelengthG1)/2
           + Noise3D(Dir,wavelengthG1/2)/4
           + Noise3D(Dir,wavelengthG1/4)/8
           + Noise3D(Dir,wavelengthG1/8)/16);
    vec3 G1 = clGalaxy1*g1val;

    //return G1;
    return (fog + smallStars*smallStars + bigStars*bigStars + base + G1 + vec3(0.04,0.022,0.014)*(Noise3D(Dir.yzx+3.141592654,0.005)-1));
}

//distance field=========================================distance field
float sdSphere( in vec3 p, in float r )
{
    return length(p) - r;
}

//t: radius from center to ring middle , radius of the ring cross section
float sdTorus(in vec3 p,in vec2 t )
{
    vec2 q = vec2(length(p.xz)-t.x,p.y);
    return length(q)-t.y;
}

float sdDisk(in vec3 p, in vec2 radii)
{
    vec3 q = p;
    q.y *= 16;
    float d;
    if(dot(p.xz,p.xz)>radii.x*radii.x){
        q.xz = vec2(radii.x+sqrt(radii.y*radii.y-(min(length(p.xz),radii.x+radii.y)-radii.x-radii.y)*(min(length(p.xz),radii.x+radii.y)-radii.x-radii.y)),0);
        d = sdTorus(q,radii);
    } else {
        d = sdTorus(q,radii);
    }
    return max(d,-sdSphere(p,EHRadius));
}

float sdEH( in vec3 p )
{
    return sdSphere(p,EHRadius);
}

//density field for the accretion disk
float densityField( in vec3 p)
{
    return max(-sdDisk(p,vec2(PSphereRadius,4*PSphereRadius)),0);
}

float densityFieldRandom(in vec3 p)
{
    const float randradius = 0.05;
    float dense = densityField(p);
    vec3 randpos = p + (2*random3(p)-1)*randradius;
    dense += densityField(randpos);
    randpos = randpos + (2*random3(p)-1)*randradius;
    dense += densityField(randpos);
    randpos = randpos + (2*random3(p)-1)*randradius;
    dense += densityField(randpos);
    return dense/4;
}
//march===========================================================march
void initRay( in vec2 uv, out sRay ray)
{
    ray.origin = uCamPos;
    ray.stepSize = STEP_SIZE;
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
    ray.stepSize = STEP_SIZE;
    //ray.stepSize *= rand2D(pos.zx);
    float G = getGravityConstant(ray.stepSize);
    //not actual concept of force btw
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
        float density = densityFieldRandom(hit.position);
        if(density>0){
            hit.density += ray.stepSize;
        }
        hit.totalLength += ray.stepSize;
        hit.direction = normalize(ray.direction);
        // if                           escaped           or                   hit EH                 or      enough samples
        //render                background and glow                             black                       background and glow
        if(!(dot(hit.position,hit.position)<squaredOrigin+1)||!(sdEH(hit.position)>epsilon)||!(hit.totalLength<maxLength)) {
            hit.mat = 1; //say its background time
            break;
        }

        updateRay(hit.position,ray);
    }
    if(!(sdEH(hit.position)>0.1)){
        hit.mat = 0;       //if it actually EH/inside Photon Sphere
    }
}

vec3 getColor(in sHit hit, in vec3 startDir, in float time)
{
    float totalDensity = hit.density;
    switch(hit.mat) {
        case 0:
            //return max(vec3(avgDensity-0.5,(avgDensity-0.5)/2,(avgDensity-0.5)/8),vec3(0,0,0));
            return vec3(1,0.5,0.125)*totalDensity;
        case 1:
            return vec3(1,0.5,0.125)*totalDensity+ noiseComplete(hit.direction, time);
        default:
            return vec3(1,0,1);
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

vec3 applyVignette(in vec3 col, in vec2 uv)
{
    uv -= 0.5;
    uv *= 2;
    uv.x *= (float(uResolution.x) /uResolution.y);
    return col*min(1,smoothstep(1,0,(length(uv)-0.8*(float(uResolution.x) /uResolution.y))*1));
}

void main()
{
    vec2 uv = gl_FragCoord.xy / uResolution;
    vec3 result = Raymarcher(uv);
    result = applyVignette(result, uv);
    color = vec4(result,1.0);
}