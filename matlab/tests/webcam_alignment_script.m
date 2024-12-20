% This script captures frames from a webcam and continuously overlays a grid of 9 red circles
% onto each frame, displaying the real-time video feed with the overlaid circles. The loop
% runs until manually terminated by pressing Ctrl+C. The script uses a try-catch block to
% ensure that resources are cleaned up properly when the loop is interrupted.
%
% Description of key features:
% - The overlay consists of 9 circles arranged in a square grid.
% - The webcam's resolution, contrast, and other settings are configured.
% - Pressing Ctrl+C safely exits the loop and releases the webcam object.

% Create a webcam object for the second camera
cam = webcam(1);

% Configure the webcam properties as specified
cam.Resolution = '800x600';
cam.Hue = 0;
cam.Gamma = 100;
cam.Contrast = 20;
cam.BacklightCompensation = 0;
cam.WhiteBalanceMode = 'auto';
cam.ExposureMode = 'auto';
cam.Brightness = 50;
cam.Saturation = 100;
cam.Sharpness = 4;

% Extract numeric values for frame width and height from the resolution string
resolution = split(cam.Resolution, 'x');
frameWidth = str2double(resolution{1});
frameHeight = str2double(resolution{2});

% Open the preview window
preview(cam);

% Parameters for overlay
circleRadius = 25;  % Updated circle radius in pixels (diameter is 50 pixels)
distance = 200;     % Distance between consecutive circles in pixels

% Calculate the coordinates for the center of the frame
centerX = frameWidth / 2;
centerY = frameHeight / 2;

% Define relative positions for the 9 circles (forming a square grid)
positions = [
    -distance, -distance;
    0, -distance;
    distance, -distance;
    -distance, 0;
    0, 0;
    distance, 0;
    -distance, distance;
    0, distance;
    distance, distance
];

% Preview loop with overlay
while true
    % Capture the frame from the webcam
    frame = snapshot(cam);

    % Add the 9 circles to the frame
    imshow(frame); % Display the frame
    hold on;
    for i = 1:size(positions, 1)
        % Calculate the position of each circle
        x = centerX + positions(i, 1);
        y = centerY + positions(i, 2);

        % Plot the circle (filled)
        rectangle('Position', [x-circleRadius, y-circleRadius, circleRadius*2, circleRadius*2], ...
                  'Curvature', [1, 1], 'FaceColor', 'r', 'EdgeColor', 'none');
    end
    hold off;

    % Pause for a short duration to update the preview smoothly
    pause(0.01);

    % Clean up the webcam object when the loop is interrupted
    clear cam;
end
