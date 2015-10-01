#import "OpenGLRenderer.h"
#import <glm.hpp>
#import <ext.hpp>
#import "imageUtil.h"
#import "modelUtil.h"
#import "sourceUtil.h"
#import "VAOCreate.h"
#import "ShaderCreate.h"
#import "TextureCreate.h"
#import "FrameBufferCreate.h"
#import "GlobalValues.h"
#import "RenderObject.h"
#import "SkyModel3D.h"
#import "btBulletCollisionCommon.h"
#import "btBulletDynamicsCommon.h"
#import "AnimatedModel3D.h"
#import "GLStatesCache.h"
#import "ShadersCache.h"
#import "HeightMap.h"
#import "ObjModelVAO.h"
#import <map>


#define LIGTS_COUNT 3

using namespace glm;

@implementation OpenGLRenderer

GLint _spriteTextureLocation;
GLint _spriteVAO;
GLint _spriteElementsCount;

GLint _gBufVAO;
GLuint _gBufElementsCount;
GLint _gBufScreenSizeLocation;
GLint _gBufMVPLocation;
GLint _gBufPosTexLocation;
GLint _gBufColorTexLocation;
GLint _gBufNormalTexLocation;
GLint _gBufDepthTexLocation;
GLint _gBufCameraPosLocation;
GLint _gBufViewProjMatrixLocation;
GLint _gBufLightPosLocation;
GLint _gBufShadowMapLocation;
GLint _gBufLightColorLocation;
GLint _gBufAttConstLocation;
GLint _gBufAttLinearLocation;
GLint _gBufAttExpLocation;


-(void) resizeWithWidth:(GLuint)width AndHeight:(GLuint)height {
	glViewport(0, 0, width, height);
    
	GlobI.viewWidth = width;
	GlobI.viewHeight = height;
    
    // G буффер
    GLint oldGbuffer = GlobI.gBufferFBO;
    map<GBufferTextures, uint> texturesMap;
    GlobI.gBufferFBO = createGBufferFBO(GlobI.viewWidth, GlobI.viewHeight, texturesMap);
    GlobI.gbufferTextures = texturesMap;
    if (oldGbuffer >= 0) {
        // TODO: !!!
//        destroyFBO(oldGbuffer);
    }
}

-(void)renderToShadowMap{
    for (int i = 0; i < self.lights.count; i++) {
        LightObject* light = self.lights[i];
        // включаем фреймбуффер
        [light begin];
        for(int i = 0; i < 6; i++){
            // включаем второну в которую рендерим
            [light enableLightFace:i];
            
            // рендерим специальным шейдером
            for (RenderObject* model in self.gBufferModels) {
                [model renderModelToLight:light faceIndex:i];
            }
            for (RenderObject* model in self.animatedModels) {
                [model renderModelToLight:light faceIndex:i];
            }
            for (RenderObject* model in self.normalModels) {
                [model renderModelToLight:light faceIndex:i];
            }
            @synchronized(self.bullets) {
                for (RenderObject* bullet in self.bullets) {
                    [bullet renderModelToLight:light faceIndex:i];
                }
            }
        }
        [light end];
    }
}

-(void)renderToGBuffer{
    // цвет фона
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, GlobI.gBufferFBO);   // включаем для записи
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    for (RenderObject* model in self.gBufferModels) {
        [model renderToGBuffer:self.camera];
    }
    for (RenderObject* model in self.animatedModels) {
        [model renderToGBuffer:self.camera];
    }
    for (LightObject* light in self.lights) {
        [light.visualizeModel renderToGBuffer:self.camera];
    }
    @synchronized(self.bullets) {
        for (RenderObject* bullet in self.bullets) {
            [bullet renderToGBuffer:self.camera];
        }
    }
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
    glClearColor(0.5, 0.5, 0.5, 1.0);
}

-(void)renderFromGBuffer{
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    [StatesI enableState:GL_CULL_FACE];
    glCullFace(GL_FRONT);
    
    [StatesI useProgramm:ShadI.gBufferShader];
    // позиция
    [StatesI setUniformInt:_gBufPosTexLocation val:0];
    [StatesI activateTexture:GL_TEXTURE0 type:GL_TEXTURE_2D texId:GlobI.gbufferTextures[GBUFFER_POSITION_ATTACH]];
    // цвет
    [StatesI setUniformInt:_gBufColorTexLocation val:1];
    [StatesI activateTexture:GL_TEXTURE1 type:GL_TEXTURE_2D texId:GlobI.gbufferTextures[GBUFFER_DIFFUSE_ATTACH]];
    // нормаль
    [StatesI setUniformInt:_gBufNormalTexLocation val:2];
    [StatesI activateTexture:GL_TEXTURE2 type:GL_TEXTURE_2D texId:GlobI.gbufferTextures[GBUFFER_NORMALS_ATTACH]];
    // глубина
    [StatesI setUniformInt:_gBufDepthTexLocation val:3];
    [StatesI activateTexture:GL_TEXTURE3 type:GL_TEXTURE_2D texId:GlobI.gbufferTextures[GBUFFER_DEPTH_ATTACH]];
    
    // позиция камеры
    [StatesI setUniformVec3:_gBufCameraPosLocation val:self.camera.cameraPos];

    // проекционная матрица для отражений
    mat4 cameraMat = [self.camera cameraMatrix];
    mat4 cameraViewProj = GlobI.projectionMatrix * cameraMat;
    [StatesI setUniformMat4:_gBufViewProjMatrixLocation val:cameraViewProj];
    
    // размер экрана
    [StatesI setUniformVec2:_gBufScreenSizeLocation val:vec2(GlobI.viewWidth, GlobI.viewHeight)];

    // ррасположение тени
    [StatesI setUniformInt:_gBufShadowMapLocation val:4];
    
    for (int i = 0; i < self.lights.count; i++) {
        LightObject* light = self.lights[i];
        
        float radius = light.calcLightSphereScale;
        
        // трансформ для источника света
        mat4 model;
        model = translate(model, light.lightPos);
        model = scale(model, vec3(radius));
        mat4 camera = [self.camera cameraMatrix];
        mat4 mvp = GlobI.projectionMatrix * camera * model;
        [StatesI setUniformMat4:_gBufMVPLocation val:mvp];
        
        // позиция света
        [StatesI setUniformVec3:_gBufLightPosLocation val:light.lightPos];
        // цвет
        [StatesI setUniformVec3:_gBufLightColorLocation val:light.lightColor];
        // конст затухания
        [StatesI setUniformFloat:_gBufAttConstLocation val:light.attConst];
        // линейное
        [StatesI setUniformFloat:_gBufAttLinearLocation val:light.attLinear];
        // эксп
        [StatesI setUniformFloat:_gBufAttExpLocation val:light.attExp];

        // карта тени
        [StatesI activateTexture:GL_TEXTURE4 type:GL_TEXTURE_CUBE_MAP texId:light.shadowCubeTexture];
        
        [StatesI bindVAO:_gBufVAO];
        glDrawElements(GL_TRIANGLES, _gBufElementsCount, GL_UNSIGNED_INT, 0);
    }
    glCullFace(GL_BACK);
    glClearColor(0.5, 0.5, 0.5, 1.0);
}

-(void)updatePhysics{
    if (self.isPhysicsCalc == TRUE) {
        return;
    }
    self.isPhysicsCalc = TRUE;
    float delta = GlobI.deltaTime;
    [GlobI rendered];
    PhysI.world->stepSimulation(delta);
    self.isPhysicsCalc = FALSE;
}

-(void)calcFPS{
    double now = [NSDate timeIntervalSinceReferenceDate];
    if((self.lastFPSUpdateTime + FPS_UPDATE_PERION) < now){
        float frameDelta = now - self.lastRenderTime;
        float curFps = 1.0 / frameDelta;
        [self.fpsLabel setText:[NSString stringWithFormat:@"%.1ffps", curFps]];
        self.lastFPSUpdateTime = now;
    }
    self.lastRenderTime = now;
}

-(void)render {
    [self.camera update];
    
    // крутим свет
    for (LightObject* light in self.lights) {
        light.lightPos = toMat3(angleAxis(0.004f, vec3(0.0, 1.0, 0.0))) * light.lightPos;
    }
    
    // обновление трансформов анимированных моделей
    for (AnimatedModel3D* animatedModel in self.animatedModels) {
        [animatedModel updateTransforms];
    }
    
    [StatesI enableState:GL_DEPTH_TEST];    // тест глубины
    // карте теней
    [self renderToShadowMap];
    // рендеринг в экранный буффер
    [self renderToGBuffer];
    [StatesI disableState:GL_DEPTH_TEST];    // тест глубины
    
    glEnable(GL_BLEND);
    glBlendEquation(GL_FUNC_ADD);
    glBlendFunc(GL_ONE, GL_ONE);
    [self renderFromGBuffer];
    glDisable(GL_BLEND);
    
    // ФПС
    [self calcFPS];
    [self.fpsLabel renderModelFromCamera:self.camera light:nil toShadow:FALSE customProj:nil];
}

-(void)shootCube{
    if (self.lastHitTime + 0.05 > [NSDate timeIntervalSinceReferenceDate]) {
        return;
    }
    self.lastHitTime = [NSDate timeIntervalSinceReferenceDate];
    
    Model3D* head = [[[Model3D alloc] initWithObjFilename:@"cube" withBody:TRUE] autorelease];
    head.modelPos = self.camera.cameraPos + self.camera.cameraTargetVec * vec3(4.0);
    head.scale = 1.0;
    [head setMass:30];
    
    // через матрицы
//    mat4 rotateMat;
//    rotateMat = rotate(rotateMat, self.camera.horisontalAngle, vec3(0.0, 1.0, 0.0));
//    rotateMat = rotate(rotateMat, self.camera.verticalAngle, vec3(0.0, 0.0, 1.0));
//    head.rotateQuat = toQuat(rotateMat);
    
    // !!! через кватерионы !!!  
    // ищем поворот между направлением вперед и нужным направлением (чтобы стреляло вперед)
    quat rot1 = rotation(vec3(0.0f, 0.0f, 1.0f), self.camera.cameraTargetVec);
    // просчитываем направление направо
    vec3 desiredUp(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(self.camera.cameraTargetVec, desiredUp));
    // пересчитываем вектор вверх
    desiredUp = normalize(cross(right, self.camera.cameraTargetVec));
    vec3 newUp = normalize(rot1 * vec3(0.0f, 1.0f, 0.0f));
    // находим поворот вычисленного поворота пули для того, чтобы пуля сама по себе не вертелась вокруг оси z
    // если не вычислить - будет крутиться вокруг своей оси непонятно как
    quat rot2 = rotation(newUp, desiredUp);
    // финальный поворот в обратном порядке
    head.rotateQuat = rot2 * rot1;
    
    // в цель
    vec3 toVec = self.camera.cameraTargetVec * vec3(300.0);
    [head setVelocity:toVec];
    
    [head addToPhysicsWorld];
    
    @synchronized(self.bullets) {
        [self.bullets addObject:head];
    }
}

-(void)keyButtonUp:(NSString*)chars{
    [self.camera keyButtonUp:chars];
}

-(void)keyButtonDown:(NSString*)chars{
    [self.camera keyButtonDown:chars];
    
    for (int i = 0; i < chars.length; i++) {
        unichar character = [chars characterAtIndex:i];
        switch (character) {
            case 'r':{
                [self shootCube];
            }break;
        }
    }
}

-(void)mouseMoved:(float)deltaX deltaY:(float)deltaY{
    self.needCalcLookTarget = TRUE;
    [self.camera mouseMoved:deltaX deltaY:deltaY];
}

-(void)testCode{
    {
        vec3 front(0.0, 0.0, 0.1);
        vec3 right(1.0, 0.0, 0.0);
        vec3 mulValue = normalize(front * right);  // произведение векторов
        mulValue = mulValue;
    }
    {
        vec3 front(0.0, 0.0, 1.0);
        vec3 right(1.0, 0.0, 0.0);
        vec3 sumValue = normalize(front + right);  // сумма векторов
        sumValue = sumValue;
    }
    {
        vec3 front(0.0, 0.0, 1.0);
        vec3 right(0.0, 0.0, 0.5);
        vec3 subValue = normalize(front - right);  // разница векторов (как из второй точки, попасть в первую)
        subValue = subValue;
    }
    {
        vec3 front(0.0, 0.0, 1.0);
        vec3 right(0.5, 0.0, 0.5);
        float cosCoeff = dot(normalize(front), normalize(right)); // насколько сильно эти вектора сонаправлены друг с другом (косинус угла между ними)
        cosCoeff = cosCoeff;
    }
    {
        vec3 front(0.0, 0.0, 1.0);
        vec3 right(1.0, 0.0, 0.0);
        vec3 vectMul = cross(front, right); // векторное произведение по правилу левой руки (указательный вперед 1, средний направо 2 = большой смотрит вверх)
        vectMul = vectMul;
    }
    {
        vec3 front(0.0, 0.0, 1.0);
        vec3 right(1.0, 0.0, 0.0);
        float res = angle(front, right); // угол между векторами
        res = orientedAngle(front, right, vec3(1.0, 0.0, 0.0))/M_PI*180.0; // угол между векторами
        res = res;
    }
    {
        vec3 front(0.0, 0.0, 1.0);
        vec3 right(1.0, 0.0, 0.0);
        float res = angle(front, right)/M_PI*180.0; // угол между векторами
        res = orientedAngle(front, right, vec3(1.0, 0.0, 0.0))/M_PI*180.0; // угол между векторами
        res = res;
    }
}

- (id) initWithWidth:(int)width height:(int)height {
	if((self = [super init])) {
		NSLog(@"%s %s", glGetString(GL_RENDERER), glGetString(GL_VERSION));
        GLint texture_units;
        glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &texture_units);
        
        PhysI;
        GlobI.viewWidth = width;
        GlobI.viewHeight = height;
        
        self.gBufferModels = [NSMutableArray array];
        self.normalModels = [NSMutableArray array];
        self.bullets = [NSMutableArray array];
        self.lights = [NSMutableArray array];
        self.animatedModels = [NSMutableArray array];
        
        [self testCode];
        
        self.camera = [[[Camera alloc] initWithCameraPos:GlobI.cameraInitPos] autorelease];
        
        // светы
        vector<vec3> lightPositions;
        lightPositions.push_back(vec3(-50.0, -20.0, 0.0));
        lightPositions.push_back(vec3(50.0, -20.0, 0.0));
        lightPositions.push_back(vec3(-50.0, -20.0, 50.0));
        vector<vec3> lightColors;
        lightColors.push_back(vec3(1.0, 1.0, 1.0));
        lightColors.push_back(vec3(1.0, 0.0, 1.0));
        lightColors.push_back(vec3(0.0, 1.0, 1.0));

        for (int i = 0; i < LIGTS_COUNT; i++) {
            LightObject* light = [[[LightObject alloc] init] autorelease];
            light.lightPos = lightPositions[i];
            light.lightColor = lightColors[i];
            light.attConst = 0.2;
            light.attLinear = 0.0005;
            light.attExp = 0.00005;
            [self.lights addObject:light];
        }
        
        ////////////////////////////////////////////////
        // буфер рендеринга
        ////////////////////////////////////////////////
        // GBuffer
        map<GBufferTextures, uint> texturesMap;
        GlobI.gBufferFBO = createGBufferFBO(GlobI.viewWidth, GlobI.viewHeight, texturesMap);
        GlobI.gbufferTextures = texturesMap;
        
        
		//////////////////////////////
		// модель //
		//////////////////////////////
        {
            
            // куб
            Model3D* ground = [[[Model3D alloc] initWithObjFilename:@"ground" withBody:FALSE] autorelease];
            ground.modelPos = vec3(0.0, -GlobI.worldSize.y/2.0, 0.0);
            ground.scale = GlobI.worldSize.x/2.0;
            ground.useVisibleTest = FALSE;
            [self.gBufferModels addObject:ground];
            
            // модель
            Model3D* modelOld = [[[Model3D alloc] initWithFilename:@"demon"] autorelease];
            modelOld.modelPos = vec3(-40.0, 0.0, -40.0);
            modelOld.scale = 0.1;
            modelOld.rotateQuat = angleAxis(float(-M_PI_2), vec3(1.0, 0.0, 0.0));
            [self.gBufferModels addObject:modelOld];
            
            // модель голов
            for(int i = 0; i < 15; i++){
                Model3D* head = [[[Model3D alloc] initWithObjFilename:@"african_head" withBody:TRUE] autorelease];
                head.modelPos = vec3(randomFloat(-40.0, 40.0), randomFloat(-40.0, 40.0), randomFloat(-40.0, 40.0));
                head.scale = 8.0;
                
                // в центр
                vec3 toCenterVec = normalize(-head.modelPos) * vec3(10.0);
                [head setVelocity:toCenterVec];
                [head setMass:100.0];
                [head addToPhysicsWorld];
                [self.gBufferModels addObject:head];
            }
        }
        
        AnimatedModel3D* animatedModel = [[[AnimatedModel3D alloc] initWithFilename:@"boblampclean.md5mesh" animIndex:0 withBody:TRUE] autorelease];
        animatedModel.scale = 0.5;
        animatedModel.modelPos = vec3(0.0, -20.0, -20.0);
        animatedModel.rotateQuat = angleAxis(float(-M_PI_2), vec3(1.0, 0.0, 0.0));
        [animatedModel setMass:400.0];
        [animatedModel addToPhysicsWorld];
        [self.animatedModels addObject:animatedModel];
        
        // текст
        self.fpsLabel = [[[LabelModel alloc] initWithText:@"----" fontSize:25] autorelease];
        self.fpsLabel.modelPos = vec3(0, 0, 0);
        
        // тестовый выстрел
        [self shootCube];
        
        // GBuffer
        _gBufVAO = buildObjVAO(@"sphere", &_gBufElementsCount);
        
		////////////////////////////////////////////////////
		// создание шейдера
		////////////////////////////////////////////////////
        
        // GBuffer
        _gBufScreenSizeLocation = glGetUniformLocation(ShadI.gBufferShader, "u_screenSize");
        _gBufMVPLocation = glGetUniformLocation(ShadI.gBufferShader, "u_mvp");
        _gBufPosTexLocation = glGetUniformLocation(ShadI.gBufferShader, "u_posTexture");
        _gBufColorTexLocation = glGetUniformLocation(ShadI.gBufferShader, "u_colorTexture");
        _gBufNormalTexLocation = glGetUniformLocation(ShadI.gBufferShader, "u_normalTexture");
        _gBufDepthTexLocation = glGetUniformLocation(ShadI.gBufferShader, "u_depthTexture");
        _gBufCameraPosLocation = glGetUniformLocation(ShadI.gBufferShader, "u_worldCameraPos");
        _gBufViewProjMatrixLocation = glGetUniformLocation(ShadI.gBufferShader, "u_viewProj");
        _gBufLightPosLocation = glGetUniformLocation(ShadI.gBufferShader, "u_worldLightPos");
        _gBufShadowMapLocation = glGetUniformLocation(ShadI.gBufferShader, "u_shadowMap");
        _gBufLightColorLocation = glGetUniformLocation(ShadI.gBufferShader, "u_lightColor");
        _gBufAttConstLocation = glGetUniformLocation(ShadI.gBufferShader, "u_attConst");
        _gBufAttLinearLocation = glGetUniformLocation(ShadI.gBufferShader, "u_attLinear");
        _gBufAttExpLocation = glGetUniformLocation(ShadI.gBufferShader, "u_attExp");


		////////////////////////////////////////////////
		// настройка GL
		////////////////////////////////////////////////
		
        [StatesI enableState:GL_CULL_FACE];     // не рисует заднюю часть
		
		// цвет фона
		glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
        
        [self render];
        
		// Check for errors to make sure all of our setup went ok
		GetGLError();
	}
	
	return self;
}

- (void) dealloc {
    self.camera = nil;
    self.gBufferModels = nil;
    self.normalModels = nil;
    self.lights = nil;
    self.bullets = nil;
    self.fpsLabel = nil;
    self.animatedModels = nil;
    
    destroyVAO(_spriteVAO);
    
	[super dealloc];
}

@end
