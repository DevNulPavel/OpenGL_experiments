//
//  FrameBufferCreate.m
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 05.04.15.
//
//

#import "FrameBufferCreate.h"
#import "TextureCreate.h"



GLuint createGBufferFBO(uint width, uint height, map<GBufferTextures, uint>& textures){
    // создаем текстуры, куда все будет рендерится
    // GL_RGB32F - обязательно такой формат для аппаратной поддержки
    uint colorTexture = buildEmpty2DTexture(GL_RGB32F, GL_RGB, width, height);
    uint positionTexture = buildEmpty2DTexture(GL_RGB32F, GL_RGB, width, height);
    uint normalsTexture = buildEmpty2DTexture(GL_RGB32F, GL_RGB, width, height);
    uint depthTexture = buildEmpty2DTexture(GL_DEPTH_COMPONENT32F, GL_DEPTH_COMPONENT, width, height);
    
    // сохраняем
    textures[GBUFFER_DIFFUSE_ATTACH] = colorTexture;
    textures[GBUFFER_POSITION_ATTACH] = positionTexture;
    textures[GBUFFER_NORMALS_ATTACH] = normalsTexture;
    textures[GBUFFER_DEPTH_ATTACH] = depthTexture;
    
    // создание буффера
    uint fbo;
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    
    // теперь присоединяем текстуры к FBO
    glFramebufferTexture2D(GL_FRAMEBUFFER, GBUFFER_DIFFUSE_ATTACH, GL_TEXTURE_2D, colorTexture, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GBUFFER_POSITION_ATTACH, GL_TEXTURE_2D, positionTexture, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GBUFFER_NORMALS_ATTACH, GL_TEXTURE_2D, normalsTexture, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GBUFFER_DEPTH_ATTACH, GL_TEXTURE_2D, depthTexture, 0);

    // включаем отрисовку в эти буфферы
    GLenum drawBuffers[] = {GBUFFER_DIFFUSE_ATTACH,
                            GBUFFER_POSITION_ATTACH,
                            GBUFFER_NORMALS_ATTACH,};
    glDrawBuffers(3, drawBuffers);
    
    int status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        printf("FB error, status: 0x%x\n", status);
        return -1;
    }
    return fbo;
}

GLuint createPixelBuffer(uint size){
    GLuint pixelBuffer;
    glGenBuffers(1, &pixelBuffer);
    glBindBuffer(GL_PIXEL_PACK_BUFFER, pixelBuffer);
    glBufferData(GL_PIXEL_PACK_BUFFER, size, nil, GL_DYNAMIC_DRAW);
    glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);
    return pixelBuffer;
}

GLuint createHeightFBO(uint width, uint height, uint& pixelBufferSize, uint& pixelBufferVertex, uint& pixelBufferNormal, uint& pixelBufferTexCoord){
    // создаем пиксельные буфферы для вершин, нормалей и текстурных координат
    pixelBufferSize = width * height * 4 * 3; // 4 байта на значение, по 3 значения
    pixelBufferVertex = createPixelBuffer(pixelBufferSize);    // вершины
    pixelBufferNormal = createPixelBuffer(pixelBufferSize);    // нормали
    pixelBufferTexCoord = createPixelBuffer(pixelBufferSize);  // текстурные координаты
    
    // создаем текстуры, куда все будет рендерится
    // GL_RGB32F - обязательно такой формат для аппаратной поддержки
    uint colorTexture = buildEmpty2DTexture(GL_RGB32F, GL_RGB, width, height);
    uint normalsTexture = buildEmpty2DTexture(GL_RGB32F, GL_RGB, width, height);
    uint texCoordsMap = buildEmpty2DTexture(GL_RGB32F, GL_RGB, width, height);
    
    // создание буффера
    uint fbo;
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    
    // теперь присоединяем текстуры к FBO
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, colorTexture, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, normalsTexture, 0);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT2, GL_TEXTURE_2D, texCoordsMap, 0);
    
    int status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        printf("FB error, status: 0x%x\n", status);
        return -1;
    }
    return fbo;
}

GLuint buildShadowFBO(int viewWidth, int viewHeight, GLuint* depthCubemap){
    // создаем текстуры
    *depthCubemap = buildEmptyCubeTexture(GL_R32F, GL_RED, viewWidth, viewHeight);
    
    // глубина
    GLuint depthRenderbuffer;
    glGenRenderbuffers(1, &depthRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT32F, viewWidth, viewHeight);
    
    // фреймбуффер + глубинная текстура
    GLuint fbo;
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    
    // отрисовки в буффер цвета нету
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, *depthCubemap, 0);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
    
    glDrawBuffer(GL_COLOR_ATTACHMENT0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        printf("FB error, status: 0x%x\n", status);
        return -1;
    }
    
    return fbo;
}

GLuint buildCubeFBO(GLuint* colorTexture, uint width, uint height){
    // цвет
    *colorTexture = buildEmptyCubeTexture(GL_RGB16, GL_RGB, width, height);
    // глубина
    GLuint depthRenderbuffer;
    glGenRenderbuffers(1, &depthRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, width, height);
    
    // подключенник к буфферам
    GLuint fbo;
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, *colorTexture, 0);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
    
    // отрисовка в буффер цвета
    glDrawBuffer(GL_COLOR_ATTACHMENT0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        printf("FB error, status: 0x%x\n", status);
        return -1;
    }
    return fbo;
}

// удалить присоединенные текстуры из буффера кадра
void deleteFBOAttachment(GLenum attachment) {
    GLint param;
    GLuint objName;
    
    glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, attachment,
                                          GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE,
                                          &param);
    
    if(GL_RENDERBUFFER == param) {
        glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, attachment,
                                              GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
                                              &param);
        
        objName = ((GLuint*)(&param))[0];
        glDeleteRenderbuffers(1, &objName);
    }
    else if(GL_TEXTURE == param){
        glGetFramebufferAttachmentParameteriv(GL_FRAMEBUFFER, attachment,
                                              GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
                                              &param);
        
        objName = ((GLuint*)(&param))[0];
        glDeleteTextures(1, &objName);
    }
    
}

void destroyFBO(GLuint fboName) {
    
    glBindFramebuffer(GL_FRAMEBUFFER, fboName);
    GLint maxColorAttachments = 0;
    glGetIntegerv(GL_MAX_COLOR_ATTACHMENTS, &maxColorAttachments);
    
    GLint colorAttachment;
    for(colorAttachment = 0; colorAttachment < maxColorAttachments; colorAttachment++) {
        deleteFBOAttachment(GL_COLOR_ATTACHMENT0+colorAttachment);
    }
    
    // удаляем буффер глубины
    deleteFBOAttachment(GL_DEPTH_ATTACHMENT);
    // и маски
    deleteFBOAttachment(GL_STENCIL_ATTACHMENT);
    
    glDeleteFramebuffers(1,&fboName);
}
