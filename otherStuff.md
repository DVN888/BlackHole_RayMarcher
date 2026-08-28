# For those interested
## Gravitational Lensing and Step Size
The ray's direction is changed every frame by Newtonian Gravitation. This makes the implementation not accurate to real life (relativistic) physics. Even though I used classic physics to change the photon (the ray), it does not have a varying speed (ray's step distance) due to gravitation. E.g. a classical object that gets closer to the mass of attraction tends to accelerate (gravity assist). This ray's velocity (step distance) does not accumulate like that. Instead, the speed is determined by the distance to the black hole. Near the accretion disk the step size becomes minimal to catch as much detail as possible. Everything farther away than the accretion disk has linear scaling to get to / away from the black hole faster. Due to this function of the step size, the regular "ray shooting off to infinity quickly" phenomenon is not present in its full form (exponential). A regular Ray Marcher with exponential would potentially "skip" or "miss" many regions of the accretion disk when approaching the disk. This means the ray cannot quickly terminate after it has passed the vicinity of the black hole. With that, the "ray shooting off to infinity quickly" is accomplished on a quadratic order, not as fast as exponential, but better than linear (constant step size).

## Density Field
The input is the current position of the ray in world space. The density field has a vertical (input relative to an upwards pointing vector) and a radial (uses all components of input) component, which are then multiplied to receive the regular density. This is multiplied with a sum of Perlin Noises, whose domain is rotated along the upwards pointing vector to create a spiral pattern in the accretion disk.

## Background
The noise functions used are Simplex Noise, Dot Noise, Perlin Noise and Worley Noise. In one big function they are computed and modified, then summed. This compute happens at the end of a ray's life, and only when the ray has not hit the event horizon. The higher the total summed density is, the less the noise background contributes to the final fragment color.

## Future Plans
I have it planned to implement Bloom in the future. For this I have a new pipeline planned:

1. Ray March Compute, does the Ray Marching and outputs a texture with the ray's final direction (for the background) and a density value (for the accretion disk).
2. Horizontal Blur, uses the texture to make a horizontally blurred texture which only contains the blurred density value.
3. Vertical Blur, uses the blurred texture to vertically blur the density value, creating a Gaussian Blur.
4. Coloring, adds the blurred values to the original texture to bloom the accretion disk and colors the accretion disk and the background through the direction vector in the texture.

In the future I will implement Doppler beaming, which will probably happen in the last moments of the Ray March Compute.

Another thing is the noise being computed every frame, for almost every single pixel. I might pass in a cube map and render the background by sampling a galaxy skybox. This also means the background might get more interesting...
