package jade;

import org.lwjgl.BufferUtils;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.lwjgl.opengl.GL20.*;
import static org.lwjgl.opengl.GL30.*;

public class MarchScene extends Scene{

    private final String vertexShaderSrcBlackHole = "#version 330 core\n" +
            "layout (location=0) in vec3 aPos;\n" +
            "layout (location=1) in vec4 aColor;\n" +
            "\n" +
            "out vec4 fColor;\n" +
            "\n" +
            "void main()\n" +
            "{\n" +
            "    fColor = aColor;\n" +
            "    gl_Position = vec4(aPos, 1.0);\n" +
            "}";

    private final String fragmentShaderSrcBlackHole;
    {
        try {
            fragmentShaderSrcBlackHole = Files.readString(Path.of("assets","shaders", "FragBlackHole.glsl"), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private final String vertexShaderSrcBlur = "#version 330 core\n" +
            "layout (location=0) in vec3 position;\n" +
            "layout (location=1) in vec4 aColor;\n" +
            "\n" +
            "out vec2 textureCoords;\n" +
            "\n" +
            "void main()\n" +
            "{\n" +
            "    gl_Position = vec4(position, 1.0);\n" +
            "    textureCoords = (position * 0.5 + 0.5).xy;\n" +
            "}";

    private final String fragmentShaderSrcBlur;
    {
        try {
            fragmentShaderSrcBlur = Files.readString(Path.of("assets","shaders", "FragBlur.glsl"), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private int vertexIDBlackHole, fragmentIDBlackHole, shaderProgramBlackHole;
    private int vertexIDBlur, fragmentIDBlur, shaderProgramBlur;

    private final float[] vertexArray = {
        //positions                         color
        1.0f, -1.0f,  0.0f,           1.0f, 0.0f, 0.0f, 0.0f, //bottom right            1        2
       -1.0f,  1.0f,  0.0f,           0.0f, 1.0f, 0.0f, 0.0f, //top left
        1.0f,  1.0f,  0.0f,           1.0f, 1.0f, 0.0f, 0.0f, //top right
       -1.0f, -1.0f,  0.0f,           0.0f, 0.0f, 1.0f, 0.0f, //bottom left             3        0
    };
// IMBORTANT: COUNTER CLOCKWISE!!!        which means 210210 and 013013
    private final int[] elementArray = {
        2,1,0, // top right tri
        0,1,3  // bottom left tri
    };

    private int vaoID, vboID, eboID;
    private int fboID, texture;

    private int lastWidth = -1;
    private int lastHeight = -1;

    private int resLocation,posLocation,dirLocation,upLocation,rightLocation,timeLocation;

    public MarchScene() {

    }

    @Override
    public void init() {
//BLACK HOLE
        //load and compile vertex shader
        vertexIDBlackHole = glCreateShader(GL_VERTEX_SHADER);
        //pass the shader source to the gpu
        glShaderSource(vertexIDBlackHole, vertexShaderSrcBlackHole);
        glCompileShader(vertexIDBlackHole);

        //check error
        int success = glGetShaderi(vertexIDBlackHole,GL_COMPILE_STATUS);
        if(success == GL_FALSE) {
            int len = glGetShaderi(vertexIDBlackHole,GL_INFO_LOG_LENGTH);
            System.out.println("ERROR Black Hole Shader \n\tVertex shader compile failed");
            System.out.println(glGetShaderInfoLog(vertexIDBlackHole,len));
            assert false : "";
        }

        //load and compile fragment shader
        fragmentIDBlackHole = glCreateShader(GL_FRAGMENT_SHADER);
        //pass the shader source to the gpu
        glShaderSource(fragmentIDBlackHole, fragmentShaderSrcBlackHole);
        glCompileShader(fragmentIDBlackHole);

        //check error
        success = glGetShaderi(fragmentIDBlackHole,GL_COMPILE_STATUS);
        if(success == GL_FALSE) {
            int len = glGetShaderi(fragmentIDBlackHole,GL_INFO_LOG_LENGTH);
            System.out.println("ERROR Black Hole Shader \n\tFragment shader compile failed");
            System.out.println(glGetShaderInfoLog(fragmentIDBlackHole,len));
            assert false : "";
        }

        //link shaders
        shaderProgramBlackHole = glCreateProgram();
        glAttachShader(shaderProgramBlackHole, vertexIDBlackHole);
        glAttachShader(shaderProgramBlackHole, fragmentIDBlackHole);
        glLinkProgram(shaderProgramBlackHole);

        //check errors
        success = glGetProgrami(shaderProgramBlackHole,GL_LINK_STATUS);
        if(success == GL_FALSE) {
            int len = glGetProgrami(shaderProgramBlackHole, GL_INFO_LOG_LENGTH);
            System.out.println("ERROR Black Hole Shader \n\tshader link failed");
            System.out.println(glGetProgramInfoLog(shaderProgramBlackHole,len));
            assert false : "";
        }


        resLocation = glGetUniformLocation(shaderProgramBlackHole,"uResolution");
        posLocation = glGetUniformLocation(shaderProgramBlackHole,"uCamPos");
        dirLocation = glGetUniformLocation(shaderProgramBlackHole,"uCamDir");
        upLocation = glGetUniformLocation(shaderProgramBlackHole,"uCamUp");
        rightLocation = glGetUniformLocation(shaderProgramBlackHole,"uCamRight");
        timeLocation = glGetUniformLocation(shaderProgramBlackHole, "uTimeSeconds");
//BLACK HOLE END

//VAO VBO EBO
        // generate VAO, VBO and EBO buffer objects and send to gpu
        vaoID = glGenVertexArrays();
        glBindVertexArray(vaoID);

        // create a float buffer of vertices
        FloatBuffer vertexBuffer = BufferUtils.createFloatBuffer(vertexArray.length);
        vertexBuffer.put(vertexArray).flip();

        //create vbo upload vertex buffer
        vboID = glGenBuffers();
        glBindBuffer(GL_ARRAY_BUFFER,vboID);
        glBufferData(GL_ARRAY_BUFFER, vertexBuffer, GL_STATIC_DRAW);

        //create indices and upload
        IntBuffer elementBuffer = BufferUtils.createIntBuffer(elementArray.length);
        elementBuffer.put(elementArray).flip();

        eboID = glGenBuffers();
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, eboID);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, elementBuffer, GL_STATIC_DRAW);

        // add vertex attrib pointers
        int positionsSize = 3; //count how many values
        int colorSize = 4;
        int floatSizeBytes = 4;//bytes per float value
        int vertexSizeBytes = (positionsSize +colorSize) * floatSizeBytes;
        glVertexAttribPointer(0,positionsSize,GL_FLOAT,false,vertexSizeBytes,0);
        glEnableVertexAttribArray(0);

        glVertexAttribPointer(1,colorSize,GL_FLOAT,false,vertexSizeBytes,positionsSize*floatSizeBytes);
        glEnableVertexAttribArray(1);
//VAO VBO EBO END

//BLUR SHADER PROGRAM
        //load and compile vertex shader
        vertexIDBlur = glCreateShader(GL_VERTEX_SHADER);
        //pass the shader source to the gpu
        glShaderSource(vertexIDBlur, vertexShaderSrcBlur);
        glCompileShader(vertexIDBlur);

        //check error
        success = glGetShaderi(vertexIDBlur,GL_COMPILE_STATUS);
        if(success == GL_FALSE) {
            int len = glGetShaderi(vertexIDBlur,GL_INFO_LOG_LENGTH);
            System.out.println("ERROR Blur Shader \n\tVertex shader compile failed");
            System.out.println(glGetShaderInfoLog(vertexIDBlur,len));
            assert false : "";
        }

        //load and compile fragment shader
        fragmentIDBlur = glCreateShader(GL_FRAGMENT_SHADER);
        //pass the shader source to the gpu
        glShaderSource(fragmentIDBlur, fragmentShaderSrcBlur);
        glCompileShader(fragmentIDBlur);

        //check error
        success = glGetShaderi(fragmentIDBlur,GL_COMPILE_STATUS);
        if(success == GL_FALSE) {
            int len = glGetShaderi(fragmentIDBlur,GL_INFO_LOG_LENGTH);
            System.out.println("ERROR Blur Shader \n\tFragment shader compile failed");
            System.out.println(glGetShaderInfoLog(fragmentIDBlur,len));
            assert false : "";
        }

        //link shaders
        shaderProgramBlur = glCreateProgram();
        glAttachShader(shaderProgramBlur, vertexIDBlur);
        glAttachShader(shaderProgramBlur, fragmentIDBlur);
        glLinkProgram(shaderProgramBlur);

        //check errors
        success = glGetProgrami(shaderProgramBlur,GL_LINK_STATUS);
        if(success == GL_FALSE) {
            int len = glGetProgrami(shaderProgramBlur, GL_INFO_LOG_LENGTH);
            System.out.println("ERROR Blur Shader \n\tshader link failed");
            System.out.println(glGetProgramInfoLog(shaderProgramBlur,len));
            assert false : "";
        }
    }

    @Override
    public void update(int width, int height, Camera camera, float sTime) {
        //check width height change, new fbo if needed
        if((width != lastWidth)||(height != lastHeight)) {
            lastWidth = width;
            lastHeight = height;
            setNewFBO(width,height);
        }

        //bind fbo here, attach texture to fbo
        glBindTexture(GL_TEXTURE_2D, 0);
        glBindFramebuffer(GL_FRAMEBUFFER, fboID);
        glViewport(0, 0, width, height);

        //bind shader Black Hole
        glUseProgram(shaderProgramBlackHole);

        //uniforms
        glUniform2f(resLocation,(float) width, (float) height);
        glUniform3f(posLocation,camera.getPos()[0],camera.getPos()[1],camera.getPos()[2]);
        glUniform3f(dirLocation,camera.getView()[0],camera.getView()[1],camera.getView()[2]);
        glUniform3f(upLocation,camera.getUp()[0],camera.getUp()[1],camera.getUp()[2]);
        glUniform3f(rightLocation,camera.getRight()[0],camera.getRight()[1],camera.getRight()[2]);
        glUniform1f(timeLocation,sTime);
        //bind vao
        glBindVertexArray(vaoID);
        //enable vertex attrib pointer
        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);

        glDrawElements(GL_TRIANGLES, elementArray.length,GL_UNSIGNED_INT,0);

        //unbind
        glDisableVertexAttribArray(0);
        glDisableVertexAttribArray(1);

        glBindVertexArray(0);

        glUseProgram(0);
        //unbind fbo? bind texture to blur shader
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        glViewport(0,0, width, height);



        //bind vao
        glBindVertexArray(vaoID);
        glEnableVertexAttribArray(0);
        glEnableVertexAttribArray(1);
        glDisable(GL_DEPTH_TEST);

        //run blur
        glUseProgram(shaderProgramBlur);
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D,texture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glDrawElements(GL_TRIANGLES, elementArray.length,GL_UNSIGNED_INT,0);
        //blur end

        glEnable(GL_DEPTH_TEST);
        glDisableVertexAttribArray(0);
        glDisableVertexAttribArray(1);
        glBindVertexArray(0);
        glUseProgram(0);
    }

    public void setNewFBO(int width, int height) {
        cleanUp();
        //create fbo
        fboID = glGenFramebuffers();
        glBindFramebuffer(GL_FRAMEBUFFER, fboID);
        glDrawBuffer(GL_COLOR_ATTACHMENT0);
        //create fbo texture attachment
        texture = glGenTextures();
        glBindTexture(GL_TEXTURE_2D, texture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, (ByteBuffer) null);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glFramebufferTexture2D(GL_FRAMEBUFFER,GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0);
    }

    public void cleanUp() {
        glDeleteFramebuffers(fboID);
        glDeleteTextures(texture);
    }
}
