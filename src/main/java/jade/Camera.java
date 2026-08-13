package jade;

import java.util.Vector;

import static org.joml.Math.sqrt;

public class Camera {
    private float[] pos = new float[3];
    private float[] forward = new float[3];     // normalized
    private float[] up = new float[3];
    private float[] right = new float[3];
    private float focalLength; //   distance from camera to projecting surface
    //private float vignetteStrength = 0.0f;

    //init
    public Camera() {
        this.pos[0] = 5.0f;             //                           +y
        this.pos[1] = -2.0f;            //                            |
        this.pos[2] = 5.0f;             //                         +z/ \+x

        updateVectors();

        this.focalLength = 0.5f;
    }

//    public Camera(float[] positionVector, float[] viewVector, float focalLength) {
//        this.pos[0] = positionVector[0];             //  x                         +y
//        this.pos[1] = positionVector[1];             //  y                          |
//        this.pos[2] = positionVector[2];             //  z                       +z/ \+x
//
//        this.forward[0] = viewVector[0];
//        this.forward[1] = viewVector[1];
//        this.forward[2] = viewVector[2];
//
//        this.focalLength = focalLength;
//    }

    //get
    public float[] getPos() {
        return this.pos;
    }

    public float[] getView() {
        return this.forward;
    }

    public float[] getUp() {
        return this.up;
    }

    public float[] getRight() {
        return this.right;
    }

    public float getFocalLength() {
        return this.focalLength;
    }

    //set
    public void setPos(float[] newPos) {
        if ((newPos.length != 3)||(newPos[0]==0f && newPos[2]==0f)) return;
        this.pos[0] = newPos[0];
        this.pos[1] = newPos[1];
        this.pos[2] = newPos[2];
    }

    public void setFocalLength(float newFL) {
        if (newFL<=0f) return;
        this.focalLength = newFL;
    }

//CONTROLS -----------------------------------------------------------------BEGIN
    public void moveIn(float dt) {
        addVectors(this.pos,this.forward,10*dt);

        if(sumSquares(this.pos)<=6.25f) {
            this.normalize(this.pos);
            this.scalar(this.pos,2.5f);
        }

        updateVectors();
    }

    public void moveOut(float dt) {
        subVectors(this.pos,this.forward,10*dt);

        if(sumSquares(this.pos)>=900f) {
            this.normalize(this.pos);
            this.scalar(this.pos,30f);
        }

        updateVectors();
    }

    public void moveUp(float dt) {
        float distance = sqrt(sumSquares(this.pos));
        addVectors(this.pos,this.up,10*dt);

        if(this.pos[0]==0f && this.pos[2]==0f) {
            addVectors(this.pos,this.up,10*dt);
        }
        normalize(this.pos);
        scalar(this.pos,distance);

        updateVectors();
    }

    public void moveDown(float dt) {
        float distance = sqrt(sumSquares(this.pos));
        subVectors(this.pos,this.up,10*dt);

        if(this.pos[0]==0f && this.pos[2]==0f) {
            subVectors(this.pos,this.up,10*dt);
        }
        normalize(this.pos);
        scalar(this.pos,distance);

        updateVectors();
    }

    public void moveRight(float dt) {
        float distance = sqrt(sumSquares(this.pos));
        addVectors(this.pos,this.right,10*dt);
        normalize(this.pos);
        scalar(this.pos,distance);
        updateVectors();
    }

    public void moveLeft(float dt) {
        float distance = sqrt(sumSquares(this.pos));
        subVectors(this.pos,this.right,10*dt);
        normalize(this.pos);
        scalar(this.pos,distance);
        updateVectors();
    }

//CONTROLS -------------------------------------------------------------------END

    //math updates
    private void updateVectors() {
        calcForward();
        calcUp();
        calcRight();
    }

    private void calcForward() {
        this.forward[0] = -(this.pos[0]);
        this.forward[1] = -(this.pos[1]);
        this.forward[2] = -(this.pos[2]);

        this.normalize(this.forward);
    }

    private void calcUp() {
        this.up[0] = -(this.forward[0]);
        this.up[2] = -(this.forward[2]);

        if(this.forward[1]!=0f) {
            this.up[1] = 1f/this.forward[1]-(this.forward[1]);  //what if fw{0,+-1,0}?
        } else {
            this.up[1] = 100000f;
        }

        if (this.up[1] < 0) {
            for (int i = 0 ; i < this.up.length ; i++) {
                this.up[i] *= -1f;
            }
        }

        this.normalize(this.up);
    }

    private void calcRight() {
        this.right[0] = this.forward[1]*this.up[2]-this.forward[2]*this.up[1];
        this.right[1] = this.forward[2]*this.up[0]-this.forward[0]*this.up[2];
        this.right[2] = this.forward[0]*this.up[1]-this.forward[1]*this.up[0];

        this.normalize(this.right);
    }

    //math utils
    private void normalize(float[] in) {
        float len = sqrt(sumSquares(in));
        for (int i = 0 ; i < in.length ; i++) {
            in[i] = in[i]/len;
        }
    }

    public float sumSquares(float[] in) {
        float sum = in[0]*in[0];
        for (int i = 1 ; i < in.length ; i++) {
            sum += in[i]*in[i];
        }
        return sum;
    }

    private void addVectors(float[] target,float[] arg, float argScale) {
        for (int i = 0; i<target.length; i++) {
            target[i] += argScale*arg[i];
        }
    }

    private void subVectors(float[] target,float[] arg, float argScale) {
        for (int i = 0; i<target.length; i++) {
            target[i] -= argScale*arg[i];
        }
    }

    private void scalar(float[] vec, float value) {
        for(int i = 0 ; i < vec.length ; i++) {
            vec[i] *= value;
        }
    }
}
