
in vec3 worldPos;
in vec3 normal;
in vec2 texCoord;
in mat3 tbn;

uniform sampler2D u_texture;
uniform sampler2D u_normalsTexture;

out vec3 fragColor;
out vec3 fragPos;
out vec3 fragNormal;


vec3 calcBumpedNormal() {
    vec3 textureNormal = (texture(u_normalsTexture, texCoord, 0.0).xyz - 0.5)*2.0;
    vec3 newNormal = tbn * textureNormal;
    newNormal = normalize(newNormal);
    return newNormal;
}

void main (void) {
    // выводим в отдельные таргеты
    fragPos = worldPos;
    fragColor = texture(u_texture, texCoord).rgb;
    fragNormal = calcBumpedNormal();
}