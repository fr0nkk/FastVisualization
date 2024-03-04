#version 410 core

layout(location = 0) in vec3 vertex_position;
layout(location = 1) in vec3 vertex_normal;
layout(location = 2) in vec3 vertex_texcoords;

out vec4 camView;
out vec3 v_normal;
out vec3 v_texcoord;
out vec3 myFragPos;

uniform mat4 model = mat4(1.0);
uniform mat4 modelview = mat4(1.0);
uniform mat4 projection = mat4(1.0);
uniform float pointSize = -1.0;
uniform float scrSz = 500.0;
uniform float fov = 45;
uniform float minPointSize = 1.0;
uniform int shaderCull = 0;
uniform float shaderCullOffset = 0.0f;
uniform vec3 viewPos = vec3(0.0f);

float pi = 4.0*atan(1.0);

void main()
{
camView = modelview * vec4(vertex_position,1.0);
gl_Position = projection * camView;

myFragPos = vec3(model * vec4(vertex_position,1.0));
v_normal = mat3(transpose(inverse(model))) * vertex_normal;
v_texcoord = vertex_texcoords;

if (shaderCull != 0)
gl_Position.z = gl_Position.z + shaderCullOffset*float(dot(v_normal,viewPos - myFragPos)*sign(shaderCull) < 0);

float pixScale =  scrSz / (2.0 * tan(fov/180.0*pi/2.0));

gl_PointSize = pointSize < 0 ? -pointSize : max(minPointSize,2*atan(pointSize/2/length(camView.xyz))*pixScale);
}
