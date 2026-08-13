package jade;

public class BlackholeScene extends Scene {

    public BlackholeScene(){
        System.out.println("blackhol");
        Window.get().r = 1;
        Window.get().g = 1;
        Window.get().b = 1;

    }

    @Override
    public void update(float width,float height,Camera camera,float dt) {

    }
}
