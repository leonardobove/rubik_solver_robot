classdef WebcamManager < matlab.System
    % WebcamManger: Manager class for the webcam. Performs webcam alignment
    % and color reading of the cube faces

    % Public, tunable properties
    properties

    end

    properties (DiscreteState)
        webcam_alignment_trig_status;    % Previous input of the webcam alignment activation trigger
        read_face_trig_status;           % Previous input of the read face activation trigger
        retake_picture_status;           % Previous input of the re-take picture button
        load_face_status;                % Previous input of the load face button
        load_cube_status;                % Previous input of the load cube button

        alignment_in_progress;           % Flag to check if the webcam_alignment script is being executed

        sw3_input_status;                % Previous input of the SW3
    end

    % Pre-computed constants
    properties (Access = private)
        webcam_alignment_process;        % Future for the webcam alignment parallel thread
    end

    methods (Access = protected)
        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
            obj.webcam_alignment_process = parallel.FevalFuture.empty;
            
        end

        function stepImpl(obj, read_face_trig, webcam_alignment_trig, debug, sw3_input, SIL, reset, retake_picture, load_face, load_cube, manual_face, manual_cube, generate_cube, skip_cube_read)
            global read_done;
            global cube;

            if SIL % SIL simulation, generate a random Rubik Cube
                if generate_cube == 1   % If generate_cube is set to 1, generate a random cube and do not wait for the user to manually load the colors
                    if webcam_alignment_trig == 1 && obj.webcam_alignment_trig_status == 0
                        cube = rubgen(3, 10); % Generate a random cube configuration
                        read_done = 1;
                    end
                end
            elseif skip_cube_read == 0 % If the user doesn't want to skip the reading of the cube, enable the webcam scripts
                % Activate webcam scripts on positive edge of the corresponding
                % activation trigger
                if webcam_alignment_trig == 1 && obj.webcam_alignment_trig_status == 0
                    obj.webcam_alignment_process = parfeval(@webcam_alignment, 0);   % Enable webcam alignment in a separate thread
                    obj.alignment_in_progress = true;
                elseif (read_face_trig == 1 && obj.read_face_trig_status == 0) || read_done == 2
                    read_done = 0;
                    [face_colors, rgb_colors] = get_face_colors(debug);
                    disp(face_colors);
                    if (debug)
                        disp(rgb_colors);
                    end
                    if any(face_colors(:) == 0) % Check if any detected color is equal to 0 (invalid color)
                        disp('An unidentified color in the current cube face was found.');
                    else % Valid color values, update the cube color matrix
                        % Get the index of the face by looking at the center
                        % tile color
                        face_index = face_colors(2, 2);

                        % Update the corresponding face colors
                        cube(:, :, face_index) = face_colors;

                        read_done = 1;
                    end
                elseif retake_picture == 1 && obj.retake_picture_status == 0
                    read_done = 2; % Set read_done to 2 in order to re-trigger face colors acquisition
                end
            end

            % Load manually the colors of a face.
            % Useful in case of multiple color detection errors.
            if load_face == 1 && obj.load_face_status == 0 && generate_cube == 0
                if any(manual_face(:) == 0) % Check if any detected color is equal to 0 (invalid color)
                    disp('An unidentified color in the current cube face was found.');
                else
                    % Get the index of the manual face
                    face_index = manual_face(2, 2);
                    disp(manual_face)

                    % Manually update the corresponding face colors
                    cube(:, :, face_index) = manual_face;

                    read_done = 1;
                end
            end

            % Load manually the colors of the whole cube.
            if load_cube == 1 && obj.load_cube_status == 0 && generate_cube == 0
                if any(manual_cube(:) == 0) % Check if any detected color is equal to 0 (invalid color)
                    disp('An unidentified color in the current cube face was found.');
                else
                    disp(manual_cube);
                    cube = manual_cube;                 

                    read_done = 1;
                end
            end
            
            % Stop the webcam alignment thread when SW3 is pressed
            if skip_cube_read == 0 && sw3_input == 1 && obj.sw3_input_status == 0
                if obj.alignment_in_progress
                    obj.alignment_in_progress = false;
                    % Stop the parallel process from running
                    cancel(obj.webcam_alignment_process);
                end

            end

            if reset
                if obj.alignment_in_progress
                    cancel(obj.webcam_alignment_process);
                end
                obj.webcam_alignment_trig_status = 0;
                obj.read_face_trig_status = 0;
                obj.retake_picture_status = 0;
                obj.load_face_status = 0;
                obj.load_cube_status = 0;
                obj.alignment_in_progress = false;
                obj.sw3_input_status = 0;
                obj.webcam_alignment_process = 0;
                cube = zeros(3, 3, 6);
                read_done = 0;
            end

            % Update input triggers status
            obj.webcam_alignment_trig_status = webcam_alignment_trig;
            obj.read_face_trig_status = read_face_trig;
            obj.retake_picture_status = retake_picture;
            obj.load_face_status = load_face;
            obj.load_cube_status = load_cube;
            obj.sw3_input_status = sw3_input;
        end

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.webcam_alignment_trig_status = 0;
            obj.read_face_trig_status = 0;
            obj.retake_picture_status = 0;
            obj.load_face_status = 0;
            obj.load_cube_status = 0;
            obj.alignment_in_progress = false;
            obj.sw3_input_status = 0;
            obj.webcam_alignment_process = 0;
        end


    end
end
