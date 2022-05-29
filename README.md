## Utilizing cloud storage for realistic augmented reality on mobile.
### Introduction
This is the Senior Project of my Computer Science major in Earlham College. The senior project revolves around utilizing augmented reality on mobile with great emphasis on realism. Furthermore, the project also utilizes cloud storage to see how the performance of the rendering drop when rendering through cloud versus through local storage.

### Abstract
As for today, augmented reality technologies are shifting towards small devices with a focus on user interaction. As more techniques in rendering AR objects are developed, more computing powers are needed to keep up. Mobile AR technology has all functions built in, in addition to GPS and compass for realistic AR rendering technology. However, mobile devices lack storage and the raw power for 3D rendering of complex objects. The paper discusses the possibility of integrating cloud to fix these problems, and conclude that using cloud for performance is difficult while using cloud for storage is possible. Results show that performance drop when utilizing cloud storage for 3D objects are minimal. As for now, cloud fetched objects are rendered without textures, leading to a reduce in realism compared to local fetched objects. Thus, the next step of the pro ject is implementing textures fetch from cloud DB on top of the 3D object file fetch.

### Screenshots
Object Rendering             |  Plane Detection
:-------------------------:|:-------------------------:
![Screenshot1](Screenshots/Screenshot1.png?raw=true "Screenshot1") | ![Screenshot2](Screenshots/Screenshot2.png?raw=true "Screenshot2")


### Paper component
The project has two components, a paper component and a software component. For more details of the software demo and first look, refer to the [paper](https://portfolios.cs.earlham.edu/wp-content/uploads/2017/12/paper.pdf).

### Software component
To try out the project, open and build ARShow.xcworkspace to a device with support for arkit capabilities (devices that have A9, A10 or A11 chip)

Once you have installed it on the device, wave around any surface so that the phone can detect the surface. 
After you have a surface detected, you can tap on the surface to project a 3D chair on top of the surface. 
It is recommended to try to project the chair on the ground instead of on the table or other surfaces, since the chair is quite big. (A normal sized chair)


