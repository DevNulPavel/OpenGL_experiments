//
//  LightObject.m
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import "LightObject.h"
#import "GlobalValues.h"
#import "FrameBufferCreate.h"
#import "GlobalValues.h"
#import "Model3D.h"

#define CUBEMAP_SIZE 1024

@implementation LightObject

-(id)init{
    if ((self = [super init])) {
        self.lightPos = vec3(0, 0, 0);
        self.lightColor = vec3(1.0);
        
        self.shadowFBO = -1;
        self.shadowCubeTexture = -1;
        
        self.visualizeModel = [[[Model3D alloc] initWithObjFilename:@"sphere" withBody:FALSE] autorelease];
        
        // фреймбуффер для тени
        GLuint cubeTexture;
        self.shadowFBO = buildShadowFBO(CUBEMAP_SIZE, CUBEMAP_SIZE, &cubeTexture);
        self.shadowCubeTexture = cubeTexture;
    }
    return self;
}

-(void)dealloc{
    self.visualizeModel = nil;
    
    // теневой буффер
    GLint oldShadowBuffer = self.shadowFBO;
    if (oldShadowBuffer >= 0) {
        destroyFBO(oldShadowBuffer);
    }
    [super dealloc];
}

-(void)setLightPos:(vec3)lightPos{
    [self.visualizeModel setModelPos:lightPos];
    _lightPos = lightPos;
}

-(void)begin{
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, self.shadowFBO);
    glViewport(0, 0, CUBEMAP_SIZE, CUBEMAP_SIZE);
    // рендерим в 32 битную числовую текстуру
    glClearColor(FLT_MAX, FLT_MAX, FLT_MAX, FLT_MAX);
}

-(void)end{
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    glViewport(0, 0, GlobI.viewWidth, GlobI.viewHeight);
}

-(void)enableLightFace:(int)faceIndex{
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_CUBE_MAP_POSITIVE_X + faceIndex, self.shadowCubeTexture, 0);
    glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
}

-(float) calcLightSphereScale {
    float maxChannel = fmax(fmax(self.lightColor.r, self.lightColor.g), self.lightColor.z);
    
    float diffuseIntensive = 1.0;
    
    float ret = (-self.attLinear + sqrtf(self.attLinear * self.attLinear - 4 * self.attExp * (self.attExp - maxChannel * diffuseIntensive)))
    /
    (2 * self.attExp);
    
    return ret * 2.0;
}

@end
