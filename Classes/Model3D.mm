//
//  Model3D.m
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import "Model3D.h"
#import "GlobalValues.h"
#import "ObjModelVAO.h"
#import "VAOCreate.h"
#import "TextureCreate.h"
#import "ShadersCache.h"
#import "GlobalValues.h"
#import "ObjModelPhysShape.h"
#import "PhysicsLogic.h"
#import "GLStatesCache.h"
#import "LightObject.h"

@implementation Model3D

-(id)initWithObjFilename:(NSString *)filename withBody:(BOOL)withBody{
    if ((self = [super init])) {
        BoudndingBox box;
        _modelVAO = buildObjVAO(filename, &_modelElementsCount, box);
        _modelElementsType = GL_UNSIGNED_INT;
        _modelTexture = buildTexture(filename);
        _normalsTexture = buildTexture([NSString stringWithFormat:@"%@_normals", filename]);

        self.boundBox = box;
        
        [self generateShader];
        if (withBody) {
            [self createPhysicsShape:filename];
        }
    }
    return self;
}

-(id)initWithFilename:(NSString *)filename{
    if ((self = [super init])) {
        BoudndingBox box;
        _modelVAO = buildModelVAO(&_modelElementsCount, &_modelElementsType, box);
        _modelTexture = buildTexture(filename);
        _normalsTexture = buildTexture([NSString stringWithFormat:@"%@_normals", filename]);
        
        self.boundBox = box;
        
        [self generateShader];
    }
    return self;
}

#pragma mark - Physics

-(void)createPhysicsShape:(NSString*)modelName{
    if ([modelName isEqualToString:@"sphere"]) {
        self.shape = new btSphereShape(1.0);
    }else{
        self.shape = buildObjShape(modelName);
    }
    self.shape->setLocalScaling(btVector3(self.scale, self.scale, self.scale));
    
    // углы поворота через zyx
    btQuaternion rotation(self.rotateQuat.x, self.rotateQuat.y, self.rotateQuat.z, self.rotateQuat.w);
    
    // позиция фигуры
    btVector3 position = btVector3(self.modelPos.x, self.modelPos.y, self.modelPos.z);
    
    // движение
    btDefaultMotionState* motionState = new btDefaultMotionState(btTransform(rotation, position));
    
    // масса и инерция
    btScalar bodyMass = 0.0;
    btVector3 bodyInertia;
    self.shape->calculateLocalInertia(bodyMass, bodyInertia);
    
    //5
    btRigidBody::btRigidBodyConstructionInfo bodyCI = btRigidBody::btRigidBodyConstructionInfo(bodyMass, motionState, self.shape, bodyInertia);
    
    //6
    bodyCI.m_restitution = 0.1f;    // сила отскока 0 - нету, 0-1 - с затуханием, >1 - с усилением
    bodyCI.m_friction = 0.8f;       // сопротивление скольжению
    
    //7
    self.body = new btRigidBody(bodyCI);
    
    //8
    self.body->setUserPointer((__bridge void*)self);
    
    //9
    self.body->setAngularFactor(0.3);   // угол ?
    self.body->setLinearFactor(btVector3(1.2, 1.2, 1.2));   // небольшой отскок
    self.body->setDamping(0.4, 0.7);  // затухание полета и поворота (сопр-е воздуха)
}

-(void)addToPhysicsWorld{
    PhysI.world->addRigidBody(self.body);
}

-(void)setModelPos:(vec3)modelPos {
    [super setModelPos:modelPos];
    [self updateBody];
}

-(void)setRotateQuat:(quat)rotateQuat{
    [super setRotateQuat:rotateQuat];
    [self updateBody];
}

-(void)setScale:(float)scale{
    [super setScale:scale];
    [self updateBody];
}

-(void)updateBody{
    if (self.body) {
        btTransform trans = self.body->getWorldTransform();
        // углы поворота через zyx
        btQuaternion rotation(self.rotateQuat.x, self.rotateQuat.y, self.rotateQuat.z, self.rotateQuat.w);
        trans.setRotation(rotation);
        // позиция
        btVector3 position = btVector3(self.modelPos.x, self.modelPos.y, self.modelPos.z);
        trans.setOrigin(position);
        // обновляем
        self.body->setWorldTransform(trans);
        
        // скейл
        self.shape->setLocalScaling(btVector3(self.scale, self.scale, self.scale));
    }
}

-(mat4)modelTransformMatrix{
    if (self.body) {
        btTransform trans = self.body->getWorldTransform();
        // позиция
        btVector3 pos = trans.getOrigin();
        // повороты
        btQuaternion rotationQuanterion = trans.getRotation();
        float angle = rotationQuanterion.getAngle();
        btVector3 axis = rotationQuanterion.getAxis();
        
        // скейл
        btVector3 scaleVec = self.shape->getLocalScaling();
        
        // обновляем матрицу модели (ОБРАТНЫЙ ПОРЯДОК)
        mat4 modelMat;
        modelMat = translate(modelMat, vec3(pos.x(), pos.y(), pos.z()));
        modelMat = rotate(modelMat, angle, vec3(axis.x(), axis.y(), axis.z()));
        modelMat = scale(modelMat, vec3(scaleVec.x(), scaleVec.y(), scaleVec.z()));
        return modelMat;
    }else{
        return [super modelTransformMatrix];
    }
}

-(void)setMass:(float)mass{
    if (self.body) {
        btScalar bodyMass = mass;
        btVector3 bodyInertia;
        self.shape->calculateLocalInertia(bodyMass, bodyInertia);
        
        self.body->setMassProps(mass, bodyInertia);
        self.body->updateInertiaTensor();
    }
}

-(void)setVelocity:(vec3)velocity{
    if (self.body) {
        btVector3 vector = btVector3(velocity.x, velocity.y, velocity.z);
        self.body->setLinearVelocity(vector);
    }
}

#pragma mark - Model

-(void)generateShader{
    // модель
    _shadowMVPLocation = glGetUniformLocation(ShadI.toShadowProgram, "u_mvpMatrix");
    _shadowWorldLocation =  glGetUniformLocation(ShadI.toShadowProgram, "u_modelMatrix");
    _shadowLightPosLocation =  glGetUniformLocation(ShadI.toShadowProgram, "u_lightPos");
    
    // модель
    _gBuf_mvpMatrixLocation = glGetUniformLocation(ShadI.toGBufferShader, "u_mvpMatrix");
    _gBuf_modelMatrixLocation =  glGetUniformLocation(ShadI.toGBufferShader, "u_modelMatrix");
    _gBuf_modelTextureLocation = glGetUniformLocation(ShadI.toGBufferShader, "u_texture");
    _gBuf_normalsTextureLocation = glGetUniformLocation(ShadI.toGBufferShader, "u_normalsTexture");
}

-(void)renderModelToLight:(LightObject*)light faceIndex:(int)faceIndex{
    // обновляем матрицу модели (ОБРАТНЫЙ ПОРЯДОК)
    mat4 modelMat = [self modelTransformMatrix];
    
    // вид из точки света
    mat4 camera = lookAt(light.lightPos, light.lightPos + vec3(0.0, 0.0, -1.0), vec3(0.0, 1.0, 0.0));
    
    // проекция
    mat4 projection = [GlobI cubemapProj:faceIndex];
    
    mat4 mvp = projection * camera * modelMat;
    
    if (self.useVisibleTest && [self isVisible:mvp] == FALSE) {
        return;
    }
    
    // включаем шейдер для отрисовки
    [StatesI useProgramm:ShadI.toShadowProgram];
    
    // помещаем матрицу модельвидпроекция в шейдер (указываем)
    [StatesI setUniformMat4:_shadowMVPLocation val:mvp];
    [StatesI setUniformMat4:_shadowWorldLocation val:modelMat];
    [StatesI setUniformVec3:_shadowLightPosLocation val:light.lightPos];
    
    // включаем объект аттрибутов вершин
    [StatesI bindVAO:_modelVAO];
    glDrawElements(GL_TRIANGLES, _modelElementsCount, _modelElementsType, 0);
}

-(void)renderToGBuffer:(Camera *)cameraObj{
    // обновляем матрицу модели (ОБРАТНЫЙ ПОРЯДОК)
    mat4 modelMat = [self modelTransformMatrix];
    // камера вида
    mat4 camera = [cameraObj cameraMatrix];
    // проекция
    mat4 projection = [self projectionMatrix];
    
    mat4 mvp = projection * camera * modelMat;
    if (self.useVisibleTest && [self isVisible:mvp] == FALSE) {
        return;
    }
    
    // включаем шейдер для отрисовки
    [StatesI useProgramm:ShadI.toGBufferShader];
    
    // помещаем матрицу модельвидпроекция в шейдер (указываем)
    [StatesI setUniformMat4:_gBuf_mvpMatrixLocation val:mvp];
    [StatesI setUniformMat4:_gBuf_modelMatrixLocation val:modelMat];
    // текстура
    [StatesI setUniformInt:_gBuf_modelTextureLocation val:0];
    [StatesI activateTexture:GL_TEXTURE0 type:GL_TEXTURE_2D texId:_modelTexture];
    // текстура нормалей
    [StatesI setUniformInt:_gBuf_normalsTextureLocation val:1];
    [StatesI activateTexture:GL_TEXTURE1 type:GL_TEXTURE_2D texId:_normalsTexture];
    
    // включаем объект аттрибутов вершин
    [StatesI bindVAO:_modelVAO];
    glDrawElements(GL_TRIANGLES, _modelElementsCount, _modelElementsType, 0);
}

-(void)dealloc{
    if (self.shape) {
         delete self.shape;
    }
    if(self.body){
        delete self.body->getMotionState();
        delete self.body;
    }
    
    // TODO: удаление текстур
    [super dealloc];
}

@end