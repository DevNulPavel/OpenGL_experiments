//
//  Model3D.h
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import <Foundation/Foundation.h>
#import "glUtil.h"
#import "RenderObject.h"
#import "glm.hpp"
#import "ext.hpp"
#import "Camera.h"
#import "btBulletCollisionCommon.h"
#import "btBulletDynamicsCommon.h"

using namespace glm;

@interface Model3D: RenderObject{
    // модель
    GLint _modelVAO;
    GLuint _modelElementsCount;
    GLuint _modelElementsType;
    
    // текстуры
    GLint _modelTexture;
    GLint _normalsTexture;
    
    // шейдер тени
    GLint _shadowMVPLocation;
    GLint _shadowWorldLocation;
    GLint _shadowLightPosLocation;
    
    // в G буффер
    GLint _gBuf_mvpMatrixLocation;
    GLint _gBuf_modelMatrixLocation;
    GLint _gBuf_modelTextureLocation;
    GLint _gBuf_normalsTextureLocation;
}

@property (nonatomic, assign) btRigidBody* body;
@property (nonatomic, assign) btCollisionShape* shape;

-(id)initWithObjFilename:(NSString *)filename withBody:(BOOL)withBody;
-(id)initWithFilename:(NSString *)filename;

-(void)addToPhysicsWorld;
-(void)setMass:(float)mass;
-(void)setVelocity:(vec3)velocity;

@end
