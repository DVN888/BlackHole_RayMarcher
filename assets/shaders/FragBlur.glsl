#version 330 core

in vec2 textureCoords;

out vec4 out_Color;

uniform sampler2D Texture;
#define s2(a, b) { vec4 temp = a; a = min(a, b); b = max(temp, b); }

void main(void){
// box blur
//    out_Color = texture(Texture, textureCoords);
//    vec2 pixelInTexSize = 1/vec2(textureSize(Texture, 0));
//    const int radius = 2;
//    vec4 sumCol = vec4(0);
//    for(int x = -radius; x <= radius; x++) {
//        for(int y = -radius; y <= radius; y++) {
//            sumCol+=texture(Texture, textureCoords + vec2(x,y)*pixelInTexSize);
//        }
//    }
//    out_Color = sumCol/((2*radius+1)*(2*radius+1));
//    out_Color.w = 1.0;

// blur + shaped
//    vec2 pixelInTexSize = 1/vec2(textureSize(Texture, 0));
//    const int radius = 2;
//    vec4 sumCol = vec4(0);
//    for(int x = -radius; x <= radius; x++) {
//        sumCol+=texture(Texture, textureCoords + vec2(x,0)*pixelInTexSize);
//    }
//    for(int y = -radius; y <= radius; y++) {
//        sumCol+=texture(Texture, textureCoords + vec2(0,y)*pixelInTexSize);
//    }
//    out_Color = (sumCol)/(4*radius+2);
//    out_Color.w = 1.0;

// median blur
//    vec4 v[9];
//    vec2 pixelInTexSize = 1/vec2(textureSize(Texture, 0));
//    int k = 0;
//    for(int y = -1; y <= 1; ++y) {
//        for(int x = -1; x <= 1; ++x) {
//            vec2 offset = vec2(float(x), float(y)) * pixelInTexSize;
//            v[k] = texture(Texture, textureCoords + offset);
//            k++;
//        }
//    }
//    s2(v[1], v[2]); s2(v[4], v[5]); s2(v[7], v[8]);
//    s2(v[0], v[1]); s2(v[3], v[4]); s2(v[6], v[7]);
//    s2(v[1], v[2]); s2(v[4], v[5]); s2(v[7], v[8]);
//    s2(v[0], v[3]); s2(v[5], v[8]); s2(v[4], v[7]);
//    s2(v[3], v[6]); s2(v[1], v[4]); s2(v[2], v[5]);
//    s2(v[4], v[7]); s2(v[4], v[2]); s2(v[6], v[4]);
//    s2(v[4], v[2]);
//    out_Color = v[4];

// x shaped blur
    vec2 pixelInTexSize = 1/vec2(textureSize(Texture, 0));
    const int radius = 2;
    vec4 sumCol = vec4(0);
    for(int x = -radius; x <= radius; x++) {
        sumCol+=texture(Texture, textureCoords + vec2(x,x)*pixelInTexSize);
    }
    for(int y = -radius; y <= radius; y++) {
        sumCol+=texture(Texture, textureCoords + vec2(y,-y)*pixelInTexSize);
    }
    out_Color = (sumCol)/(4*radius+2);
    out_Color.w = 1.0;
}

