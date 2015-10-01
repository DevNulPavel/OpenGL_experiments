
in vec4  inPosition;
uniform mat4 u_mvp;

void main (void) {
    gl_Position	= u_mvp * inPosition;
}
