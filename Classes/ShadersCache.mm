//
//  ShadersCache.m
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 11.04.15.
//
//

#import "ShadersCache.h"
#import "ShaderCreate.h"

static ShadersCache *shadersInstance = nil;

@implementation ShadersCache

+ (ShadersCache *)instance {
    @synchronized(self) {
        if (shadersInstance == nil) {
            shadersInstance = [[self alloc] init];
        }
    }
    return shadersInstance;
}

-(id)init{
    if ((self = [super init])) {
        self.skyModelShaderProgram = buildSkyCharacter();
        self.billboardShaderProgram = buildBillboardProgram();
        self.particlesShader = buildParticlesProgram();
        self.cubeShader = buildCubeProgram();
        self.skyboxShader = buildSkyboxProgram();
        self.heightRenderShaderProgram = buildHeightProgram();
        self.heightSpriteProgram = buildHeightSpriteProgram();
        self.spriteShaderProgram = buildSpriteProgram();
        self.textShader = buildTextProgram();
        self.toGBufferShader = buildToGBufferProgram();
        self.gBufferShader = buildGBufferRenderProgram();
        self.toShadowProgram = buildToShadowProgramFunc();
    }
    return self;
}

-(void)dealloc{
    glDeleteProgram(self.skyModelShaderProgram);
    glDeleteProgram(self.billboardShaderProgram);
    glDeleteProgram(self.particlesShader);
    glDeleteProgram(self.cubeShader);
    glDeleteProgram(self.toShadowProgram);
    glDeleteProgram(self.skyboxShader);
    glDeleteProgram(self.heightRenderShaderProgram);
    glDeleteProgram(self.heightSpriteProgram);
    glDeleteProgram(self.spriteShaderProgram);
    glDeleteProgram(self.textShader);
    glDeleteProgram(self.toGBufferShader);
    glDeleteProgram(self.gBufferShader);
    glDeleteProgram(self.toShadowAnimatedProgram);
    
    [super dealloc];
}

@end
