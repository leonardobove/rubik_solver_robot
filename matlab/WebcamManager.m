classdef WebcamManager < matlab.System
    % WebcamManger: Manager class for the webcam. Performs webcam alignment
    % and color reading of the cube faces

    % Public, tunable properties
    properties

    end

    properties (DiscreteState)
        webcam_alignment_trig_status;    % Previous input of the webcam alignment activation trigger
        read_face_trig_status;           % Previous input of the read face activation trigger
        retake_pcicture_status;          % Previous input of the re-take picture button
        load_face_status;                % Previous input of the load face button

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

        function stepImpl(obj, read_face_trig, webcam_alignment_trig, debug, sw3_input, SIL, reset, retake_picture, load_face, manual_face)
            global stop_alignment;
            global read_done;
            global alignment_done;
            global cube;

            if SIL % SIL simulation, generate a random Rubik Cube
                if webcam_alignment_trig == 1 && obj.webcam_alignment_trig_status == 0
                    cube = rubgen(3, 10); % Generate a random cube configuration
                    alignment_done = 1;
                    read_done = 1;
                end
            else
                % Activate webcam scripts on positive edge of the corresponding
                % activation trigger
                if webcam_alignment_trig == 1 && obj.webcam_alignment_trig_status == 0
                    stop_alignment = false;
                    obj.webcam_alignment_process = parfeval(@webcam_alignment, 0);   % Enable webcam alignment in a separate thread
                    obj.alignment_in_progress = true;
                    alignment_done = 0;
                elseif read_face_trig == 1 && obj.read_face_trig_status == 0
                    [face_colors, rgb_colors] = get_face_colors(debug);
                    disp(face_colors);
                    if (debug)
                        disp(rgb_colors);
                    end
                    if any(face_colors(:) == 0) % Check if any detected color is equal to 0 (invalid color)
                        disp('An unidentified color in the current was found.');
                        read_done = 2;
                    else % Valid color values, update the cube color matrix
                        % Get the index of the face by looking at the center
                        % tile color
                        face_index = face_colors(2, 2);

                        % Update the corresponding face colors
                        cube(:, :, face_index) = face_colors;

                        read_done = 1;
                    end
                elseif retake_picture == 1 && obj.read_face_trig_status == 0
                    read_done = 2;
                end
                
                % Load manually the colors of a face.
                % Useful in case of multiple color detection errors.
                if load_face == 1 && obj.load_face_status == 0                    
                    % Get the index of the manual face
                    face_index = manual_face(2, 2);

                    % Manually update the corresponding face colors
                    cube(:, :, face_index) = manual_face;

                    read_done = 1;
                end
            end
            
            % Stop the webcam alignment thread when SW3 is pressed
            if sw3_input == 1 && obj.sw3_input_status == 0
                if obj.alignment_in_progress
                    stop_alignment = true;
                    obj.alignment_in_progress = false;
                    % Stop the parallel process from running
                    cancel(obj.webcam_alignment_process);
                    alignment_done = 1;
                end

            end

            if reset
                if SIL==0 && obj.alignment_in_progress==1
                    obj.webcam_alignment_trig_status = 0;
                    obj.read_face_trig_status = 0;
                    obj.retake_pcicture_status = 0;
                    obj.load_face_status = 0;
                    obj.alignment_in_progress = false;
                    obj.sw3_input_status = 0;
                    cancel(obj.webcam_alignment_process); 
                    obj.webcam_alignment_process = 0;
                end
                cube = zeros(3, 3, 6);
                stop_alignment = false;
                read_done = 0;
                alignment_done =0;
            end

            % Update input triggers status
            obj.webcam_alignment_trig_status = webcam_alignment_trig;
            obj.read_face_trig_status = read_face_trig;
            obj.retake_pcicture_status = retake_picture;
            obj.load_face_status = load_face;
            obj.sw3_input_status = sw3_input;
        end

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.webcam_alignment_trig_status = 0;
            obj.read_face_trig_status = 0;
            obj.retake_pcicture_status = 0;
            obj.load_face_status = 0;
            obj.alignment_in_progress = false;
            obj.sw3_input_status = 0;
            obj.webcam_alignment_process = 0;
        end


    end
end
