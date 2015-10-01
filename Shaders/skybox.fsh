in vec3 texCoord;
uniform samplerCube u_cubemapTexture;
out vec3 fragColor;

void main (void) {
    fragColor = texture(u_cubemapTexture, texCoord).rgb;
}