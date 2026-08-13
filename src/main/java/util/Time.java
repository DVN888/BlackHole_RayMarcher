package util;

public class Time {
    public static long timeStarted = System.nanoTime();
// outputs seconds
    public static float getTime() {
        return (float)((System.nanoTime()-timeStarted)*(1E-9));
    }
}
