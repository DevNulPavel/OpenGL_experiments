
// gBuffer
uniform vec2 u_screenSize;
uniform sampler2D u_posTexture;
uniform sampler2D u_colorTexture;
uniform sampler2D u_normalTexture;
uniform sampler2D u_depthTexture;

// данные для теней
uniform samplerCube u_shadowMap;
uniform vec3 u_worldCameraPos;
uniform mat4 u_viewProj;
uniform vec3 u_worldLightPos;
uniform vec3 u_lightColor;
uniform float u_attConst;
uniform float u_attLinear;
uniform float u_attExp;


out vec4 fragColor;


vec2 calcTexCoord() {
    return gl_FragCoord.xy / u_screenSize;
}

void main (void) {
    vec2 texCoord = calcTexCoord();
    vec3 worldPos = texture(u_posTexture, texCoord).xyz;
    vec3 color = texture(u_colorTexture, texCoord).rgb;
    vec3 normal = texture(u_normalTexture, texCoord).xyz;
    float depth = texture(u_depthTexture, texCoord).x;
    
    vec3 toCameraVec = normalize(u_worldCameraPos - worldPos);
    vec3 reflectVec = normalize(reflect(-toCameraVec, normal));
    vec3 lightDirection = u_worldLightPos - worldPos;
    float lightLen = length(lightDirection);
    vec3 toLightVec = normalize(lightDirection);

    float lightPower = 0.2;
    // диффузный
    float diffuseFactor = max(dot(toLightVec, normal), 0.0);
    lightPower += diffuseFactor;

    // блики
    vec3 reflectLightVector = normalize(reflect(-toLightVec, normal)); // вычисляем вектор отраженного света для пикселя
    float specFactor = max(dot(toCameraVec, reflectLightVector), 0.0); // насколкьо сильно совпадают вектара отражения и направления на камеру
    specFactor = pow(specFactor, 12.0);
    lightPower += specFactor;
    
    // затухание
    float lightAttenuation = u_attConst + u_attLinear * lightLen + u_attExp * pow(lightLen, 2.0);
    lightAttenuation = max(1.0, lightAttenuation);
    lightPower /= lightAttenuation;
        
    // тень
    float depthVal = texture(u_shadowMap, normalize(-toLightVec)).r;
    float shadowCoeff = 1.0;
    if (depthVal < lightLen-2.0){
        shadowCoeff = clamp(lightLen/250.0, 0.2, 0.9);  // расстояние полного прекращения тени - 200
    }
    
    fragColor = vec4(color * (u_lightColor * lightPower) * shadowCoeff, 1.0);
//    fragColor = vec4(normal, 1.0);
}



//vec3 getPosition(vec2 UV, float depth) {
//    vec4 position = vec4(1.0);
//    
//    position.x = UV.x * 2.0 - 1.0;
//    position.y = -(UV.y * 2.0 - 1.0);
//    
//    position.z = depth;
//    
//    position = inverse(u_viewProj) * position;
//    
//    position /= position.w;
//    
//    return position.xyz;
//}
//
//vec3 getUV(vec3 position) {
//    vec4 pVP = u_viewProj * vec4(position, 1.0);
//    pVP.xy = vec2(0.5, 0.5) + vec2(0.5f, 0.5f) * pVP.xy / pVP.w;
//    return vec3(pVP.xy, pVP.z / pVP.w);
//}
//
//vec3 findReflectedVector(vec3 position, vec3 reflectVec){
//    vec3 currentRay = vec3(0.0);
//    
//    vec3 nuv = vec3(0.0);
//    float stepVal = 1;
//    
//    for(int i = 0; i < 3; i++){
//        currentRay = position + reflectVec * stepVal;
//        
//        nuv = getUV(currentRay); // проецирование позиции на экран
//        float depthVal = texture(u_depthTexture, nuv.xy).x; // чтение глубины из DepthMap по UV
//        
//        vec3 newPosition = getPosition(nuv.xy, depthVal);
//        stepVal = length(position - newPosition);
//    }
//    return vec3(nuv.xy, stepVal / 20.0);
//}

//    float depthVal = texture(u_shadowMap[0], vec3(texCoord, -1.0)).r / 1000.0;
//    fragColor = vec4(depthVal, depthVal, depthVal, 1.0);

// отражение
//    float fresnel = 3.8 * pow(1.0 + dot(-toCameraVec, normal), 1.5) - 1.0;
//    if (fresnel > 0) {
//        vec3 reflectionUV = findReflectedVector(worldPos, reflectVec);
//        vec4 reflectedColor = texture(u_colorTexture, reflectionUV.xy) / reflectionUV.z;
//        reflectedColor *= fresnel;
//        fragColor += reflectedColor;
//    }