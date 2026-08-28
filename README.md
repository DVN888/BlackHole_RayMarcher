# Black Hole Simulation

<p align="center">
  <img src="https://github.com/DVN888/BlackHole_RayMarcher/blob/master/README_GIF/giphyRMBH.gif?raw=true" alt="My Black Hole Simulation's GIF"/>
</p>

## Intro
The Ray Marching happens in a fragment shader, the ray's step direction gets updated after every step to simulate gravitational lensing.  
Using a density field function, the accretion disk is rendered by the rays summing up density along their journey around/into the black hole.  
The background is computed every frame and is made of multiple noise functions.  
Due to the deterministic nature of computers, the Ray Marching resulted in color banding with the density field function. This was addressed by introducing noise into the Ray Marching, causing very strong very strong grain in the final image. This was reduced by adding a Blur in a secondary fragment shader.

## Controls and Executable
There's a Key Listener, so inputs with keyboard are recognized. (`[W][A][S][D]` for spherical movement, `[ArrowUp]` to zoom in, `[ArrowDown]` to zoom out, `[T]` for toggle of automatic movement) (`[C]` is a backup close button, but the intended method to terminate the program is the window's close button.)

Use at your own risk. A double click executable `.exe` file for Windows is available in the latest Release.

## Other
I wrote about technical details and future ideas in [here](otherStuff.md). Check it out if you are interested.

If you have epilepsy, don't move the camera near the top or near the bottom, it flickers.  
If you don't have epilepsy, also don't move the camera near the top or near the bottom, it looks trash.

I do not recommend maximizing the window if you know your GPU is on the weaker side (especially if it's integrated), the preset 800x600 size should be enough for viewing.  
> GPU this was tested with: RTX 5060 Ti 16GB  
> This was made with JDK21.
