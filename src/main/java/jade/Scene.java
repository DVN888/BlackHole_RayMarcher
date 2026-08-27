package jade;

public abstract class Scene {

    public Scene() {

    }

    public void init() {

    }

    public abstract void update(int width, int height, Camera camera, float dt);
}
