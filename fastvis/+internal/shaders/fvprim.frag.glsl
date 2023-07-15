#version 410 core

layout(location = 0) out vec4 frag_color;
layout(location = 1) out vec2 frag_camDist;
layout(location = 2) out vec3 frag_xyz;
layout(location = 3) out uvec2 frag_id;


in vec4 camView;
in vec3 v_normal;
in vec3 v_texcoord;
in vec3 myFragPos;

uniform float alpha = 1.0f;
uniform uint drawid = 0;
uniform uint elemid = 0;

uniform sampler2D material_tex;
uniform vec4 material_col = vec4(1.0f);
uniform vec3 material_spec = vec3(0.5f);
uniform float material_shin = 10.0f;
uniform float edlDivisor = 1.0f;
uniform uint pointMask = 1;
uniform sampler2D pointMask_tex;

uniform vec3 viewPos = vec3(0.0f);

struct Light
{
    vec3 position;
    vec3 diffuse;
    vec3 ambient;
    vec3 specular;
};

uniform Light light;

subroutine vec3 sr_light_type(vec3, vec3, float);
subroutine uniform sr_light_type lighting;

subroutine(sr_light_type) vec3 phong(vec3 color, vec3 speccol, float shininess)
{
    // diffuse
    vec3 mynorm = normalize(v_normal);
    vec3 lightDir = normalize(light.position - myFragPos);
    float diff = max(dot(mynorm, lightDir), 0.0f);
    vec3 diffuse = color * diff * light.diffuse;

    // ambient
    vec3 ambient = color * light.ambient;
    
    // specular
    vec3 viewDir = normalize(viewPos - myFragPos);
    vec3 reflectDir = reflect(-lightDir, mynorm);  
    float specpow = pow(max(dot(viewDir, reflectDir), 0.0f), shininess);
    vec3 specular = speccol * specpow * light.specular;

    return diffuse + ambient + specular;
}

subroutine(sr_light_type) vec3 none(vec3 color, vec3 speccol, float shininess)
{
    return color;
}


subroutine vec4 color_src(void);
subroutine uniform color_src color_source;

subroutine(color_src) vec4 vertex_color(void)
{
    return vec4(v_texcoord,1.0f);
}

subroutine(color_src) vec4 material_color(void)
{
    return material_col;
}

subroutine(color_src) vec4 material_texture(void)
{
    return texture(material_tex,v_texcoord.xy);
}

void main(){

switch (pointMask) {
    case 1:
        if(length(gl_PointCoord.xy-0.5) > 0.5) discard;
        break;
    case 2:
        if(texture(pointMask_tex,gl_PointCoord.xy).r < 0.5) discard;
        break;
}

frag_color = color_source();
frag_color.a *= alpha;
if(frag_color.a == 0.0f) discard;
frag_color.rgb = lighting(frag_color.rgb,material_spec,material_shin);


//frag_camDist = vec2(-camView.z,edlDivisor);
frag_camDist = vec2(length(camView.xyz),edlDivisor);
frag_xyz = camView.xyz;

frag_id = uvec2(drawid + 65535*elemid,gl_PrimitiveID+1);

}
