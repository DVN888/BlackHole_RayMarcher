A Black Hole RayMarcher that uses GLFW for the window. 
The Ray Marching happens in the fragment shader, the ray's step direction gets updated after every step to simulate gravitational lensing.
Using a density field function, the accretion disk is rendered by the ray summing up density along its journey around/into the black hole.
The background is computed every frame (which is quite slow but ok) and is made of multiple noise functions.
There's a KeyListener, so inputs with keyboard (WASD, ArrowUp, ArrowDown, T) are recognized.

I do not recommend maximizing the window if you know your GPU is on the weaker side, the preset 1000x800 size should be enough for viewing.
This implementation is not finished, it still needs to be thoroughly optimized, but it does work well.
Use at your own risk?
I don't know how to give instructions to run this program, I'm new to GitHub.
