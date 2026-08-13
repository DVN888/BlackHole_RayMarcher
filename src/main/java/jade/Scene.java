package jade;

public abstract class Scene {

    public Scene() {

    }

    public void init() {

    }

    public abstract void update(float width,float height,Camera camera,float dt);
}
