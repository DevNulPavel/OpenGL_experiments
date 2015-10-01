
in vec4  inPosition;

uniform mat4 u_mvpMatrix;
uniform mat4 u_modelMatrix;

out vec3 worldPos;

void main (void) {
	gl_Position	= u_mvpMatrix * vec4(inPosition.xyz, 1.0);
    worldPos = vec3(u_modelMatrix * vec4(inPosition.xyz, 1.0));
}
