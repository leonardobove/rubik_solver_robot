% Create a webcam object for the second camera
cam = webcam(2);

% Configure the webcam properties as specified
cam.Resolution = '800x600';
cam.Hue = 0;
cam.Gamma = 100;
cam.Contrast = 70;
cam.BacklightCompensation = 0;
cam.WhiteBalanceMode = 'auto';
cam.ExposureMode = 'auto';
cam.Brightness = 80;
cam.Saturation = 100;
cam.Sharpness = 4;

% Extract numeric values for frame width and height from the resolution string
resolution = split(cam.Resolution, 'x');
frameWidth = str2double(resolution{1});
frameHeight = str2double(resolution{2});

% Parameters for circles
circleRadius = 25;  % Circle radius in pixels (diameter is 50 pixels)
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

% Capture a picture from the webcam
frame = snapshot(cam);

% Display the captured image (optional for visualization)
imshow(frame);
hold on;

% Initialize arrays to store the detected colors and average RGB values
detectedColors = strings(1, 9);
avgRGBValues = zeros(9, 3);

% Define RGB ranges for Rubik's Cube colors (these ranges are approximate and can be fine-tuned)
colorRanges = {
    'white',   [200, 200, 200], [255, 255, 255];
    'red',     [150, 0, 0],     [255, 90, 90];
    'green',   [0, 150, 0],     [190, 255, 190];
    'yellow',  [200, 200, 0],   [255, 255, 100];
    'blue',    [0, 0, 150],     [150, 150, 255];
    'orange',  [200, 100, 0],   [255, 180, 80]
};

% Loop to calculate the average RGB color for each circle and classify based on ranges
for i = 1:size(positions, 1)
    % Calculate the circle's center position
    xCenter = centerX + positions(i, 1);
    yCenter = centerY + positions(i, 2);
    
    % Create a mask for the circular region
    [X, Y] = meshgrid(1:frameWidth, 1:frameHeight);
    circleMask = ((X - xCenter).^2 + (Y - yCenter).^2) <= circleRadius^2;
    
    % Extract the RGB values within the circle
    redChannel = frame(:,:,1);
    greenChannel = frame(:,:,2);
    blueChannel = frame(:,:,3);
    
    % Calculate the average RGB values within the circle
    avgR = mean(redChannel(circleMask));
    avgG = mean(greenChannel(circleMask));
    avgB = mean(blueChannel(circleMask));
    avgColor = [avgR, avgG, avgB];
    
    % Store the average RGB values
    avgRGBValues(i, :) = avgColor;
    
    % Determine which color the average RGB value falls into
    detectedColor = 'unknown';  % Default value
    for j = 1:size(colorRanges, 1)
        colorName = colorRanges{j, 1};
        minRGB = colorRanges{j, 2};
        maxRGB = colorRanges{j, 3};
        
        % Check if the average color falls within the specified RGB range
        if all(avgColor >= minRGB) && all(avgColor <= maxRGB)
            detectedColor = colorName;
            break;
        end
    end
    
    % Store the detected color
    detectedColors(i) = detectedColor;
    
    % Optional: plot the circle for visualization
    rectangle('Position', [xCenter-circleRadius, yCenter-circleRadius, circleRadius*2, circleRadius*2], ...
              'Curvature', [1, 1], 'EdgeColor', 'r', 'LineWidth', 1);
end

hold off;

% Display the detected colors and corresponding average RGB values
disp('Detected colors for the 9 circles:');
disp(detectedColors);
disp('Average RGB values for the 9 circles:');
disp(avgRGBValues);

% Clean up the webcam object
clear cam;
