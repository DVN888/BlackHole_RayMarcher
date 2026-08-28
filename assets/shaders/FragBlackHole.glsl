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

const int MAX_ITER = 200; //128 to 256, default 200
const float PSphereRadius = 1.5f;     //default 1.5, main scaling value
const float EHRadius = PSphereRadius/1.5;
const float ADiskRadius = 6.0;        // in PSpheres, default 5.0
const float LIGHT_SPEED = 2.0*ADiskRadius*PSphereRadius/MAX_ITER;        //min step size, only near black hole (aka when it actually matters) the ray has fixed light speed.
const float MAX_RADIUS = 40;      //get from uniform later
float MAX_LENGTH = max(2*ADiskRadius*PSphereRadius,2.0*length(uCamPos));


float rand2D(in vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453)/2+0.5; //from 0.5 to 1.0
}

float rand3D(in vec3 co){
    return fract(sin(dot(co, vec3(12.9898, 78.233, 45.5432))) * 43758.5453123);
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
//modified the 3d variant
float interpolatedNoise2D(in float x, in float y)
{
    float integer_x = x - fract(x);
    float fractional_x = x - integer_x;

    float integer_y = y - fract(y);
    float fractional_y = y - integer_y;

    float v1 = rand3D(vec3(integer_x,0, integer_y));
    float v2 = rand3D(vec3(integer_x+1.0,0, integer_y));
    float v3 = rand3D(vec3(integer_x,0, integer_y+1.0));
    float v4 = rand3D(vec3(integer_x+1.0,0, integer_y +1.0));

    float i1 = simple_interpolate(v1,v2,fractional_x);
    float i2 = simple_interpolate(v3,v4,fractional_x);

    return simple_interpolate(i1 , i2 , fractional_y);
}

float Noise2D(in vec2 coord, in float wavelength)
{
    return interpolatedNoise2D(coord.x/wavelength, coord.y/wavelength);
}

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
    float fogval = snoise(noisePos/2);
    vec3 fog = fogval*fogval*fogval*clFog;
    //stars
    noisePos = vec2(dot(vec3(-0.6085806194,0.4260064336,-0.6694386813),Dir),
                         dot(vec3(0.0695795410,-0.8117613123,-0.5798295088),Dir))*2.123456789;
    vec3 smallStars = clSmallStarsOrange*dotNoise2D(noisePos.x,noisePos.y,0.03,5.123456789);
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
    return (fog + smallStars + bigStars*bigStars + base + G1 + vec3(0.04,0.022,0.014)*(Noise3D(Dir.yzx+3.141592654,0.005)-1));
}

vec2 rotate(vec2 v,float angle)
{
    return vec2(v.x*cos(angle)-v.y*sin(angle),v.x*sin(angle)+v.y*cos(angle));
}

float PerlinNoiseSumADisk(vec3 p)
{
    float quotient = (PSphereRadius+0.1)/(length(p.xyz)+0.1);
    return Noise2D(rotate(p.xz,uTimeSeconds/12+5*quotient),PSphereRadius/1.25)
          +Noise2D(rotate(p.xz,uTimeSeconds/8+4*quotient),PSphereRadius/2.5)/2
          +Noise2D(rotate(p.xz,uTimeSeconds/4+3*quotient),PSphereRadius/5)/2;
          //+Noise2D(rotate(p.xz,uTimeSeconds/3+10*quotient),PSphereRadius/3.5)/8;
}

//distance field=========================================distance field

float sdSphere( in vec3 p, in float r )
{
    return length(p) - r;
}

//pure distance field, no hit info
float distanceField( in vec3 p )
{
    return sdSphere(p,EHRadius);
}

//density field for the accretion disk
//                                   x y z
const vec3 yvector = normalize(vec3(0,1,   0.176776   )); //ALWAYS x=0 AND y=1
const vec3 xvector = normalize(vec3(1,0,0));  //ALWAYS X=1 AND y=0 AND z=0
const vec3 zvector = normalize(vec3(0,-yvector.z,yvector.y));
float densityField( in vec3 p)
{
    float len = length(p.xyz);
    if(!(len>(ADiskRadius+1)*PSphereRadius)) {
        float radial = 1-smoothstep(0, (ADiskRadius+1)*PSphereRadius, len);
        float vertical = -8*abs(dot(p,yvector))/PSphereRadius+1;
        vertical = max(0, vertical * vertical * vertical * 16);
        vec3 pInDiskSpace = vec3(dot(xvector,p),dot(yvector,p),dot(zvector,p));
        return radial*vertical*PerlinNoiseSumADisk(pInDiskSpace);
    } else return 0;
}

float densityFieldAVG(in vec3 p)
{
    vec3 offset = vec3(0.01,0,0);
    float dense = densityField(p-offset.xyy)
                 +densityField(p-offset.yxy)
                 +densityField(p-offset.yyx)
                 +densityField(p-offset.xxx);
    return dense/4;
//    const float randradius = PSphereRadius/8;
//    float smallTime = uTimeSeconds/10;
//    vec3 randvec = vec3(2*random3(p+cos(smallTime)).x-1,0,0)*randradius;
//    float dense = densityField(p);
//    vec3 randpos = p + randvec.xyz;
//    dense += densityField(randpos);
//    randpos = randpos + randvec.yzx;
//    dense += densityField(randpos);
//    randpos = randpos + randvec.zxy;
//    dense += densityField(randpos);
//    return dense/4;
}
//march===========================================================march

//                world space  world space
float getStepSize(in vec3 pos,in float min)
{
    float d = length(pos);
    if(d<PSphereRadius*ADiskRadius*1.625){
        return exp((d/PSphereRadius-1.625*ADiskRadius)/2)+min;
    }
    else{
        return (d/PSphereRadius-1.625*ADiskRadius)/2+1+min;
    }
}


void initRay( in vec2 uv, out sRay ray)
{
    ray.origin = uCamPos;
    ray.stepSize = getStepSize(ray.origin,LIGHT_SPEED);
    ray.direction = uCamDir-uCamUp-uResolution.x/uResolution.y*uCamRight;
    ray.direction += 2*uv.y*uCamUp+2*uv.x*uResolution.x/uResolution.y*uCamRight;
    ray.direction = ray.stepSize * normalize(ray.direction);
}

vec3 getGravityAcceleration( in float currentLightSpeed, in vec3 position)
{
    return -PSphereRadius*currentLightSpeed*currentLightSpeed/dot(position, position)*normalize(position);
}

void updateRay(in vec3 pos, inout sRay ray)
{
    // at a distance of 4 Photon Sphere, quickly get to regular LIGHT_SPEED
    ray.stepSize = getStepSize(pos,LIGHT_SPEED);
    ray.stepSize *= rand2D(gl_FragCoord.xy+vec2(uTimeSeconds/170,-uTimeSeconds/290))/2+0.5;                     //randomize steps from 0.875 to 1.125

    vec3 acc = getGravityAcceleration(ray.stepSize,pos);                     //new classic bending, its EXACT!!!
    ray.direction = ray.stepSize * normalize(ray.direction);
    ray.direction += acc;
    ray.direction = ray.stepSize * normalize(ray.direction);
}

void march(in sRay ray, out sHit hit, in int maxIter, in float maxLength)
{
    const float epsilon = 1E-2;
    float squaredMax = max(length(uCamPos),1.5*ADiskRadius*PSphereRadius);
    squaredMax *= squaredMax;
    hit.position = ray.origin;
    hit.direction = ray.direction;
    hit.density = densityField(ray.origin);
    hit.totalLength = 0;
    hit.mat = 1; //if i reaches maxIter, it means the ray is orbiting outside photon sphere. return hit material as glowing.
    int i = 0;
    do {
        hit.position += ray.direction;
        hit.density += densityField(hit.position);
        hit.totalLength += ray.stepSize;
        hit.direction = normalize(ray.direction);
        updateRay(hit.position,ray);
        i += 1;
    }
    while( (i<maxIter)                              //for loop
    && (dot(hit.position,hit.position)<squaredMax)  //not escaped
    && (distanceField(hit.position)>epsilon)        //not hit EH
    && (hit.totalLength<maxLength));                //not enough samples (not enough orbiting)

    if((distanceField(hit.position)<epsilon*1.5)){
        hit.mat = 0;       //if it actually EH/inside Photon Sphere
    } else {
        hit.mat = 1;
    }
}

vec3 interpolationColor(float val)
{
    //float value = log2(val+1);
    //float value = sqrt(val);
    //float value = 5-25/(val+5);
    //float value = smoothstep(0,6,val);
    float value = sqrt(1-1/(val/10+1))+val/20;
    //float value = val/8;
    vec3 col = vec3(1.00,0.40,0.25);
    return value * col;
}

vec3 getColor(in sHit hit, in vec3 startDir, in float time)
{
    vec3 val = interpolationColor(hit.density);
    switch(hit.mat) {
        case 0:
            return val;
        case 1:
            return val + noiseComplete(hit.direction, time)*max(1-val.x,0);
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
    //result = applyVignette(result, uv);
    color = vec4(result,1.0);
}