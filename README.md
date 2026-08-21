# Black Hole Simulation
The Ray Marching happens in the fragment shader, the ray's step direction gets updated after every step to simulate gravitational lensing.

Using a density field function, the accretion disk is rendered by the rays summing up density along their journey around/into the black hole.

The background is computed every frame (which is quite slow but oh well) and is made of multiple noise functions.

There's a KeyListener, so inputs with keyboard (WASD, ArrowUp, ArrowDown, T) are recognized.

If you have epilepsy, don't move the camera near the top or near the bottom, it flickers. 

If you don't have epilepsy, also don't move the camera near the top or near the bottom, because it looks trash.

I do not recommend maximizing the window if you know your GPU is on the weaker side (especially if it's integrated), the preset 800x600 size should be enough for viewing.

This implementation is not finished, it still needs to be thoroughly optimized, but it does work well.

Use at your own risk. Instructions for executing the program soon. Simple double click executable `.exe` for Windows soon.



## For those interested
The ray's direction is changed every frame by Newtonian Gravitation. This makes this implementation not accurate to real life physics. Even though I used classic physics to change the photon (the ray), it does not have a varying velocity (ray's step distance). E.g. a classical object that gets closer to the mass of attraction tends to accelerate (gravity assist). This ray's velocity (step distance) does not accumulate like that. Instead, the velocity is determined by the distance to the black hole. Near the accretion disk the step size becomes near minimal to catch as much detail as possible. Everything farther away than the accretion disk has linear scaling to get to / away from the black hole faster.

The density field has a vertical (uses only y-component of input) and a radial (uses all components of input) component, which are then multiplied to receive the density. The input is the current position of the ray in world space. In the future, the density field could be modified to angle the accretion disk.

The noise functions used are Simplex Noise, Dot Noise, Perlin Noise and Worley Noise. In one big function they are computed and modified, then summed. This compute happens at the end of a ray's life, and only when the ray has not hit the event horizon. The higher the total summed density is, the less the noise background contributes to the final fragment color.

### Performance
Due to the nature of the rendered subject, the regular "ray shooting off to infinity quickly" phenomenon is not present. This is because the step distance is not dependent on the distance field. A regular Ray Marcher would potentially "skip" or "miss" the high density regions of the accretion disk. This means the ray cannot quickly terminate after it has passed the vicinity of the black hole. Except for something mentioned in the section before: the step size is increased linearly the further you get away from the black hole. With that, the "ray shooting off to infinity quickly" is accomplished on a quadratic order, not as fast as exponential, but better than linear.<sup>1</sup> **This results in the Ray Marching loop taking a little longer to terminate, stunting performance.** 

Another concern is the noise being computed every frame, for every single pixel (actually every pixel except the ones whose ray has hit the event horizon). This should be mitigated by rendering a 3D texture at the beginning and sampling from it when needed. But since this has not been implemented yet, **it adds a significant mathematical load, decreasing performance.**

1. *Why not just scale step size regularly exponentially?*
   At some point, the step size gets so big due to the exponential that one step skips the entire scene. Distance (as a dimension) scales linearly, so anything higher than a linear order step size will not work for this specific situation. 
