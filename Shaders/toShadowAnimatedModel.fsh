in vec3 worldPos;
uniform vec3 u_lightPos;
out float fragColor;

void main (void) {
    fragColor = length(worldPos - u_lightPos);
}