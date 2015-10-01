//
//  ShadersCache.h
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 11.04.15.
//
//

#import <Foundation/Foundation.h>

#define ShadI [ShadersCache instance]

@interface ShadersCache : NSObject

@property(nonatomic, assign) GLint billboardShaderProgram;
@property(nonatomic, assign) GLint particlesShader;
@property(nonatomic, assign) GLint cubeShader;
@property(nonatomic, assign) GLint skyModelShaderProgram;
@property(nonatomic, assign) GLint skyboxShader;
@property(nonatomic, assign) GLint animatedModelShader;
@property(nonatomic, assign) GLint heightRenderShaderProgram;
@property(nonatomic, assign) GLint heightSpriteProgram;
@property(nonatomic, assign) GLint spriteShaderProgram;
@property(nonatomic, assign) GLint textShader;
@property(nonatomic, assign) GLint toGBufferShader;
@property(nonatomic, assign) GLint gBufferShader;
@property(nonatomic, assign) GLint toShadowProgram;
@property(nonatomic, assign) GLint toShadowAnimatedProgram;

+ (ShadersCache *)instance;

@end
