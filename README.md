A Black Hole RayMarcher that uses GLFW for the window. 

The Ray Marching happens in the fragment shader, the ray's step direction gets updated after every step to simulate gravitational lensing.

Using a density field function, the accretion disk is rendered by the rays summing up density along their journey around/into the black hole.

The background is computed every frame (which is quite slow but oh well) and is made of multiple noise functions.

There's a KeyListener, so inputs with keyboard (WASD, ArrowUp, ArrowDown, T) are recognized.

If you have epilepsy, don't move the camera near the top or near the bottom, it flickers. 

If you don't have epilepsy, also don't move the camera near the top or near the bottom, because it looks trash.

I do not recommend maximizing the window if you know your GPU is on the weaker side, the preset 800x600 size should be enough for viewing.

This implementation is not finished, it still needs to be thoroughly optimized, but it does work well.

Use at your own risk?

I don't know how to give instructions to run this program, I'm new to GitHub. 

lemaoaoao
