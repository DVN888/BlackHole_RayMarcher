package jade;

import org.lwjgl.BufferUtils;

import java.awt.event.KeyEvent;
import java.io.IOException;
import java.nio.FloatBuffer;
import java.nio.IntBuffer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static java.lang.Math.round;
import static java.lang.Math.sin;
import static org.lwjgl.opengl.GL20.*;
import static org.lwjgl.opengl.GL30.glBindVertexArray;
import static org.lwjgl.opengl.GL30.glGenVertexArrays;

public class MarchScene extends Scene{

    private String vertexShaderSrc = "#version 330 core\n" +
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
    private String fragmentShaderSrc;

    {
        try {
            fragmentShaderSrc = Files.readString(Path.of("assets","shaders", "FragBlackHole.glsl"), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private int vertexID, fragmentID, shaderProgram;

    private float[] vertexArray = {
        //positions                         color
        1.0f, -1.0f,  0.0f,           1.0f, 0.0f, 0.0f, 0.0f, //bottom right            1        2
       -1.0f,  1.0f,  0.0f,           0.0f, 1.0f, 0.0f, 0.0f, //top left
        1.0f,  1.0f,  0.0f,           1.0f, 1.0f, 0.0f, 0.0f, //top right
       -1.0f, -1.0f,  0.0f,           0.0f, 0.0f, 1.0f, 0.0f, //bottom left             3        0
    };
// IMBORTANT: COUNTER CLOCKWISE!!!        which means 210210 and 013013
    private int[] elementArray = {
        2,1,0, // top right tri
        0,1,3  // bottom left tri
    };

    private int vaoID, vboID, eboID;

    private int resLocation,posLocation,dirLocation,upLocation,rightLocation,timeLocation;

    public MarchScene() {

    }

    @Override
    public void init() {
        //compile and link shaders
        //load and compile vertex shader
        vertexID = glCreateShader(GL_VERTEX_SHADER);
        //pass the shader source to the gpu
        glShaderSource(vertexID,vertexShaderSrc);
        glCompileShader(vertexID);

        //check error
        int success = glGetShaderi(vertexID,GL_COMPILE_STATUS);
        if(success == GL_FALSE) {
            int len = glGetShaderi(vertexID,GL_INFO_LOG_LENGTH);
            System.out.println("ERROR BlackHole.glsl \n\tVertex shader compile failed");
            System.out.println(glGetShaderInfoLog(vertexID,len));
            assert false : "";
        }

        //load and compile fragment shader
        fragmentID = glCreateShader(GL_FRAGMENT_SHADER);
        //pass the shader source to the gpu
        glShaderSource(fragmentID,fragmentShaderSrc);
        glCompileShader(fragmentID);

        //check error
        success = glGetShaderi(fragmentID,GL_COMPILE_STATUS);
        if(success == GL_FALSE) {
            int len = glGetShaderi(fragmentID,GL_INFO_LOG_LENGTH);
            System.out.println("ERROR BlackHole.glsl \n\tfragment shader compile failed");
            System.out.println(glGetShaderInfoLog(fragmentID,len));
            assert false : "";
        }

        //link shaders
        shaderProgram = glCreateProgram();
        glAttachShader(shaderProgram, vertexID);
        glAttachShader(shaderProgram, fragmentID);
        glLinkProgram(shaderProgram);

        //check errors
        success = glGetProgrami(shaderProgram,GL_LINK_STATUS);
        if(success == GL_FALSE) {
            int len = glGetProgrami(shaderProgram, GL_INFO_LOG_LENGTH);
            System.out.println("ERROR BlackHole.glsl \n\tshader link failed");
            System.out.println(glGetProgramInfoLog(shaderProgram,len));
            assert false : "";
        }

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

        //create indicies and upload
        IntBuffer elementBuffer = BufferUtils.createIntBuffer(elementArray.length);
        elementBuffer.put(elementArray).flip();

        eboID = glGenBuffers();
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, eboID);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, elementBuffer, GL_STATIC_DRAW);

        // add vertex attrib pointers
        int positionsSize = 3;
        int colorSize = 4;
        int floatSizeBytes = 4;
        int vertexSizeBytes = (positionsSize +colorSize) * floatSizeBytes;
        glVertexAttribPointer(0,positionsSize,GL_FLOAT,false,vertexSizeBytes,0);
        glEnableVertexAttribArray(0);

        glVertexAttribPointer(1,colorSize,GL_FLOAT,false,vertexSizeBytes,positionsSize*floatSizeBytes);
        glEnableVertexAttribArray(1);

        resLocation = glGetUniformLocation(shaderProgram,"uResolution");
        posLocation = glGetUniformLocation(shaderProgram,"uCamPos");
        dirLocation = glGetUniformLocation(shaderProgram,"uCamDir");
        upLocation = glGetUniformLocation(shaderProgram,"uCamUp");
        rightLocation = glGetUniformLocation(shaderProgram,"uCamRight");
        timeLocation = glGetUniformLocation(shaderProgram, "uTimeSeconds");
    }

    @Override
    public void update(float width,float height,Camera camera,float dt) {
        //bind shader
        glUseProgram(shaderProgram);

        //uniforms
        glUniform2f(resLocation,width,height);
        glUniform3f(posLocation,camera.getPos()[0],camera.getPos()[1],camera.getPos()[2]);
        glUniform3f(dirLocation,camera.getView()[0],camera.getView()[1],camera.getView()[2]);
        glUniform3f(upLocation,camera.getUp()[0],camera.getUp()[1],camera.getUp()[2]);
        glUniform3f(rightLocation,camera.getRight()[0],camera.getRight()[1],camera.getRight()[2]);
        glUniform1f(timeLocation,((float) java.lang.System.nanoTime()/1E9f));
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
    }
}
