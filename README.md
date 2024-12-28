# Rubik's Cube Automatic Solver
A servo motor actuated Rubik cube solver robot, controlled by S32K144EVB. Developed using Simulink MBD.
The structure of the project is taken from the following [thingiverse](https://www.thingiverse.com/thing:3826740).

## Wiring
The power supply of the 4 servo motors comes from the Arduino "Braccio Shield V4". The Motors are connected as follows:

 - M1 > PWM on PTB4 (left arm, bottom left)
 - M2 > PWM on PTB5 (left grip, top left)
 - M3 > PWM on PTD15 (right arm, bottom right)
 - M4 > PWM on PTD16 (right grip, top right)

## Vision
The colors of the face are detected using a USB 2.0 PC camera (resolution 640x480) and MATLAB.
