#version 400

layout(location=0) out vec4 FragColor;
layout(location=1) out vec3 FragXYZ;
layout(location=2) out uvec2 FragID;

in vec2 TexCoords;

uniform sampler2DMS colorTex;
uniform sampler2DMS camDistTex;
uniform sampler2DMS xyzTex;
uniform usampler2DMS idTex;
uniform int msaa = 1;
uniform bool edlWithBackground = false;
uniform float edlStrength = 0.2f;
uniform bool edlActive = true;

ivec2 foffset[4] = ivec2[](
ivec2(-1,0),
ivec2(1,0),
ivec2(0,-1),
ivec2(0,1)
);

vec3 edlStep(ivec2 tc, int msaaIdx, float mean_scrSize)
{
    vec2 neighboor;
    vec2 camDist = texelFetch(camDistTex,tc,msaaIdx).rg;
    vec3 color = texelFetch(colorTex,tc,msaaIdx).rgb;

    if (!edlWithBackground && camDist.r == 0) return color;
    
    float shade = 0.0f;
    float d = camDist.r == 0 ? 100.0e6 : log2(camDist.r);
    float mult = camDist.g;
    for (int i=0;i<4;i++)
    {
        neighboor = texelFetch(camDistTex,tc + foffset[i],msaaIdx).rg;
        mult = max(mult,neighboor.g);
        shade -= (neighboor.r > 0) ? max(0.0,d-log2(neighboor.r)) : 0.0f;
    }
    shade = exp2(edlStrength*mean_scrSize*shade);
    shade = clamp(shade/mult,0.0,1.0);
    return clamp(color * shade,0.0,1.0);
}

void main(){
    vec2 scrSz = vec2(textureSize(colorTex));
    ivec2 tc = ivec2(TexCoords * scrSz);
    float mean_scrSize = (scrSz.x + scrSz.y) / 2.0f;
    vec3 color = vec3(0.0);
    if (edlActive)
    {
        for (int i=0;i<msaa;i++)
        {
            color += edlStep(tc,i,mean_scrSize);
        }
    } else {
        for (int i=0;i<msaa;i++)
        {
            color += texelFetch(colorTex,tc,i).rgb;
        }
    }
    FragColor = vec4(color / float(msaa),1.0);
    FragXYZ = texelFetch(xyzTex,tc,0).xyz;
    FragID = texelFetch(idTex,tc,0).xy;
}
