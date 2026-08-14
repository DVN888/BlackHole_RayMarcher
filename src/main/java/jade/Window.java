package jade;

import org.lwjgl.Version;
import org.lwjgl.glfw.GLFWErrorCallback;
import org.lwjgl.opengl.GL;
import util.Time;

import static java.lang.Math.*;
import static org.lwjgl.glfw.Callbacks.glfwFreeCallbacks;
import static org.lwjgl.glfw.GLFW.*;
import static org.lwjgl.opengl.GL11.*;
import static org.lwjgl.system.MemoryUtil.NULL;

public class Window {
    private int width,height;
    private final String title;
    private long glfwWindow;
    private Camera camera;
    private boolean isAutoMove;
    private float toggleLock;
    private final float lockTime=0.2f; //in seconds

    private static Window window = null;

    private static Scene currentScene;

    private Window(){
        this.width = 800;
        this.height = 600;
        this.title = "Black Hole, Controls: [W] [A] [S] [D] [ArrowUp] [ArrowDown] [T] for Move Toggle";
        this.camera = new Camera();
        this.isAutoMove = true;
        this.toggleLock = 0;
    }

    public static void changeScene(int newScene) {
        if (newScene == 0) {
            currentScene = new MarchScene();
            currentScene.init();
        } else {
            assert false : "who tf scene this " + newScene;
        }
    }

    public static Window get() {
        if (Window.window == null) {
            Window.window = new Window();
        }
        return Window.window;
    }

    public void run() {
        System.out.println("running LWJGL " + Version.getVersion() + "!");

        init();
        loop();

        //free
        glfwFreeCallbacks(glfwWindow);
        glfwDestroyWindow(glfwWindow);

        //terminate glfw and free error callback
        glfwTerminate();
        glfwSetErrorCallback(null).free();
    }

    public void init() {
        //error callback setup
        GLFWErrorCallback.createPrint(System.err).set();

        //init glfw
        if(!glfwInit()) {
            throw new IllegalStateException("Unable to init GLFW!");
        }

        //configure glfw
        glfwDefaultWindowHints();
        glfwWindowHint(GLFW_VISIBLE, GLFW_FALSE);
        glfwWindowHint(GLFW_RESIZABLE,GLFW_TRUE);
        glfwWindowHint(GLFW_MAXIMIZED, GLFW_FALSE);

        //create window
        glfwWindow = glfwCreateWindow(this.width, this.height, this.title, NULL, NULL);
        if(glfwWindow == NULL) {
            throw new IllegalStateException("Failed to create the GLFW window!");
        }

        glfwSetCursorPosCallback(glfwWindow, MouseListener::mousePosCallback);
        glfwSetMouseButtonCallback(glfwWindow,MouseListener::mouseButtonCallback);
        glfwSetScrollCallback(glfwWindow,MouseListener::mouseScrollCallback);
        glfwSetKeyCallback(glfwWindow, KeyListener::keyCallback);
        glfwSetFramebufferSizeCallback(glfwWindow,(glfwWindow,w,h)->{
            this.width = w;
            this.height = h;
            glViewport(0,0,w,h);
        });

        //opengl context current
        glfwMakeContextCurrent(glfwWindow);
        //vsync enable
        glfwSwapInterval(1);
        //window position
        glfwSetWindowPos(glfwWindow,75,120);
        // window visible
        glfwShowWindow(glfwWindow);

        //very important thing lol
        GL.createCapabilities();

        Window.changeScene(0);
    }

    public void loop() {
        float beginTime = Time.getTime();
        float endTime;
        float dt = -1.0f;
        this.toggleLock = 0;

        while (!glfwWindowShouldClose(glfwWindow)){
            //poll events
            glfwPollEvents();

            glClear(GL_COLOR_BUFFER_BIT);

            if(dt>=0) {
                currentScene.update(this.width,this.height,camera,dt); //pass in window width and height, and camera
                if(KeyListener.isKeyPressed(GLFW_KEY_W)) camera.moveUp(dt);
                if(KeyListener.isKeyPressed(GLFW_KEY_S)) camera.moveDown(dt);
                if(KeyListener.isKeyPressed(GLFW_KEY_D)) camera.moveRight(dt);
                if(KeyListener.isKeyPressed(GLFW_KEY_A)) camera.moveLeft(dt);
                if(KeyListener.isKeyPressed(GLFW_KEY_UP)) camera.moveIn(dt);
                if(KeyListener.isKeyPressed(GLFW_KEY_DOWN)) camera.moveOut(dt);
                if(this.toggleLock<=0 && KeyListener.isKeyPressed(GLFW_KEY_T)) {
                    toggleAutoMove();
                    this.toggleLock = this.lockTime;
                }
                if(isAutoMove) camera.moveUp((float) (0.2 * dt * sin(Time.getTime()) * sin(Time.getTime()) * signum(sin(Time.getTime()))));
                this.toggleLock -= dt;
            }

            glfwSwapBuffers(glfwWindow);

            //dt calc
            endTime = Time.getTime();
            dt = endTime - beginTime;
            beginTime = endTime;
        }
        System.out.println(sqrt(camera.sumSquares(camera.getPos())));
    }

    private void toggleAutoMove() {
        this.isAutoMove=!this.isAutoMove;
    }

}
