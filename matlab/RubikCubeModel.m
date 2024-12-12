classdef RubikCubeModel < matlab.System
    % RubikCubeModel: This class manages the animation sequence of the
    % virtual cube, following the movements of the physical robotic sovler 

    % Public, tunable properties
    properties

    end

    properties (DiscreteState)
        % Storage variables for the value of the 4 servo motors duty cycles
        % at the previous simulation step
        BL_duty_old;
        TL_duty_old;
        BR_duty_old;
        TR_duty_old;

        % duty cycle values for different servo motor positions
        min_duty;
        max_duty;
        duty_0_deg;
        duty_90_deg;
        duty_180_deg;
        duty_grip_open;
        duty_grip_closed;

        % Offset values to be added to duty cycles of each arm, in order to
        % compensante for mismatch errors between the two motors and therefore to
        % be able to fine tune the motors positions.
        offset_duty_left_arm;
        offset_duty_right_arm;

        % Flag to check if the cube has been successfully read and the
        % animation can start
        cube_ready;
        cube_ready_old;

        % Old status of 'move_done', in order to detect signal edges
        move_done_old;
    end

    % Pre-computed constants
    properties (Access = private)

    end

    methods (Access = protected)
        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
        end

        function stepImpl(obj, BR_duty, TR_duty, BL_duty, TL_duty, move_done, reset)
            global cube;
            global moves;
            global current_move_idx;
            global execute_move;

            % If all the colors of the cube are different from 0,
            % the cube has been successfully acquired (or loaded or generated)
            % and hence it is ready.
            if ~obj.cube_ready
                if all(cube(:) ~= 0)  % Check if all the faces have been read or manually loaded
                    obj.cube_ready = true;
                end
            end

            % Plot the cube only once the first time it becomes available
            % and calculate the sequence of moves to solve it
            if obj.cube_ready && ~obj.cube_ready_old
                % Plot
                rubplot(cube);
                drawnow;

                % Solve
                moves = update_algorithm(moves, true, false, 'cube', cube);
            end

            % Truncate input values to the 4th decimal number
            BR_duty_truncated = (floor(BR_duty * 10^4) / 10^4) - obj.offset_duty_right_arm;
            TR_duty_truncated = floor(TR_duty * 10^4) / 10^4;
            BL_duty_truncated = (floor(BL_duty * 10^4) / 10^4) - obj.offset_duty_left_arm;
            TL_duty_truncated = floor(TL_duty * 10^4) / 10^4;

            if obj.cube_ready
                % Animate the current move and change the algorithm POV at
                % any cube rotation
                if TR_duty_truncated == obj.duty_grip_closed && TL_duty_truncated == obj.duty_grip_open && BR_duty_truncated > obj.BR_duty_old
                    % Counter-clockwise rotation of the right arm with the left
                    % grip open (x1)
                    cube = rubrot2(cube, 'x1', 'animate', 1);
                    drawnow;

                    % Rotate algorithm
                    moves = update_algorithm(moves, false, true, 'rotation', 'x3');
                    %moves = update_algorithm(moves, false, true, 'rotation', 'x1');

                    % If the previous motor angle was at 0 degrees and now
                    % is set to 180 degrees, a 180 degrees turn has
                    % happend: rotate again
                    if obj.BR_duty_old == obj.duty_0_deg && BR_duty_truncated == obj.duty_180_deg
                        cube = rubrot2(cube, 'x1', 'animate', 1);
                        drawnow;
                        moves = update_algorithm(moves, false, true, 'rotation', 'x3');
                    end
                elseif TR_duty_truncated == obj.duty_grip_closed && TL_duty_truncated == obj.duty_grip_open && BR_duty_truncated < obj.BR_duty_old
                    % Clockwise rotation of the right arm with the left grip
                    % open (x3)
                    cube = rubrot2(cube, 'x3', 'animate', 1);
                    drawnow;

                    % Rotate algorithm
                    moves = update_algorithm(moves, false, true, 'rotation', 'x1');
                    %moves = update_algorithm(moves, false, true, 'rotation', 'x3');

                    % If the previous motor angle was at 180 degrees and now
                    % is set to 0 degrees, a 180 degrees turn has
                    % happend: rotate again
                    if obj.BR_duty_old == obj.duty_180_deg && BR_duty_truncated == obj.duty_0_deg
                        cube = rubrot2(cube, 'x3', 'animate', 1);
                        drawnow;
                        moves = update_algorithm(moves, false, true, 'rotation', 'x1');
                    end
                elseif TR_duty_truncated == obj.duty_grip_closed && TL_duty_truncated == obj.duty_grip_closed && BR_duty_truncated > obj.BR_duty_old
                    % Counter-clockwise rotation of the right arm with the left
                    % grip closed (x11)
                    cube = rubplot(cube, 'x11');
                    drawnow;

                    % If the previous motor angle was at 0 degrees and now
                    % is set to 180 degrees, a 180 degrees turn has
                    % happend: rotate again
                    if obj.BR_duty_old == obj.duty_0_deg && BR_duty_truncated == obj.duty_180_deg
                        cube = rubplot(cube, 'x11');
                        drawnow;
                    end
                elseif TR_duty_truncated == obj.duty_grip_closed && TL_duty_truncated == obj.duty_grip_closed && BR_duty_truncated < obj.BR_duty_old
                    % Clockwise rotation of the right arm with the left grip
                    % closed (x13)
                    cube = rubplot(cube, 'x13');
                    drawnow;

                    % If the previous motor angle was at 180 degrees and now
                    % is set to 0 degrees, a 180 degrees turn has
                    % happend: rotate again
                    if obj.BR_duty_old == obj.duty_180_deg && BR_duty_truncated == obj.duty_0_deg
                        cube = rubplot(cube, 'x13');
                        drawnow;
                    end
                elseif TL_duty_truncated == obj.duty_grip_closed && TR_duty_truncated == obj.duty_grip_open && BL_duty_truncated > obj.BL_duty_old
                    % Counter-clockwise rotation of the left arm with the right
                    % grip open (z1)
                    cube = rubrot2(cube, 'z1', 'animate', 1);
                    drawnow;

                    % Rotate algorithm
                    moves = update_algorithm(moves, false, true, 'rotation', 'z3');
                    %moves = update_algorithm(moves, false, true, 'rotation', 'z3');

                    % If the previous motor angle was at 0 degrees and now
                    % is set to 180 degrees, a 180 degrees turn has
                    % happend: rotate again
                    if obj.BL_duty_old == obj.duty_0_deg && BL_duty_truncated == obj.duty_180_deg
                        cube = rubrot2(cube, 'z1', 'animate', 1);
                        drawnow;
                        moves = update_algorithm(moves, false, true, 'rotation', 'z3');
                    end
                elseif TL_duty_truncated == obj.duty_grip_closed && TR_duty_truncated == obj.duty_grip_open && BL_duty_truncated < obj.BL_duty_old
                    % Clockwise rotation of the left arm with the right grip
                    % open (z3)
                    cube = rubrot2(cube, 'z3', 'animate', 1);
                    drawnow;

                    % Rotate algorithm
                    moves = update_algorithm(moves, false, true, 'rotation', 'z1');
                    %moves = update_algorithm(moves, false, true, 'rotation', 'z1');
                        
                    % If the previous motor angle was at 180 degrees and now
                    % is set to 0 degrees, a 180 degrees turn has
                    % happend: rotate again
                    if obj.BL_duty_old == obj.duty_180_deg && BL_duty_truncated == obj.duty_0_deg
                        cube = rubrot2(cube, 'z3', 'animate', 1);
                        drawnow;
                        moves = update_algorithm(moves, false, true, 'rotation', 'z1');
                    end
                elseif TL_duty_truncated == obj.duty_grip_closed && TR_duty_truncated == obj.duty_grip_closed && BL_duty_truncated > obj.BL_duty_old
                    % Counter-clockwise rotation of the left arm with the right
                    % grip closed (z31)
                    cube = rubplot(cube, 'z31');
                    drawnow;

                    % If the previous motor angle was at 0 degrees and now
                    % is set to 180 degrees, a 180 degrees turn has
                    % happend: rotate again
                    if obj.BL_duty_old == obj.duty_0_deg && BL_duty_truncated == obj.duty_180_deg
                        cube = rubplot(cube, 'z31');
                        drawnow;
                    end
                elseif TL_duty_truncated == obj.duty_grip_closed && TR_duty_truncated == obj.duty_grip_closed && BL_duty_truncated < obj.BL_duty_old
                    % Clockwise rotation of the left arm with the right grip
                    % closed (z33)
                    cube = rubplot(cube, 'z33');
                    drawnow;

                    % If the previous motor angle was at 180 degrees and now
                    % is set to 0 degrees, a 180 degrees turn has
                    % happend: rotate again
                    if obj.BL_duty_old == obj.duty_180_deg && BL_duty_truncated == obj.duty_0_deg
                        cube = rubplot(cube, 'z33');
                        drawnow;
                    end
                end
            end

            % After applying rotations (rising edge of move_done), update current move index if the
            % move is completed and start move execution
            if move_done == 1 && obj.move_done_old == 0
                current_move_idx = uint16(current_move_idx + 1);
            elseif move_done == 0
                execute_move = 0;
            elseif move_done == 1
                execute_move = 1;
            end

            % Update duty cycle values
            obj.BR_duty_old = BR_duty_truncated;
            obj.TR_duty_old = TR_duty_truncated;
            obj.BL_duty_old = BL_duty_truncated;
            obj.TL_duty_old = TL_duty_truncated;

            obj.cube_ready_old = obj.cube_ready;

            obj.move_done_old = move_done;

            if reset
                %reset class variables
                obj.BL_duty_old = 0;
                obj.TL_duty_old = 0;
                obj.BR_duty_old = 0;
                obj.TR_duty_old = 0;
                obj.cube_ready = false;
                obj.cube_ready_old = false;
                obj.move_done_old = 1;

                %reset global parameters
                moves=uint8(zeros(45, 2));
                current_move_idx = uint16(1);

                %close the cube's window
                close all;
            end
        end

        function resetImpl(obj)
            % Initialize / reset discrete-state properties
            obj.BL_duty_old = 0;
            obj.TL_duty_old = 0;
            obj.BR_duty_old = 0;
            obj.TR_duty_old = 0;

            obj.min_duty = 0.025;
            obj.max_duty = 0.125;
            obj.duty_0_deg = obj.min_duty;
            obj.duty_90_deg = obj.min_duty + (obj.max_duty-obj.min_duty)/2;
            obj.duty_180_deg = obj.max_duty;
            obj.duty_grip_open = obj.min_duty + (obj.max_duty-obj.min_duty)/3;
            obj.duty_grip_closed = obj.min_duty + (obj.max_duty-obj.min_duty)/13;
            obj.offset_duty_left_arm = (obj.max_duty-obj.min_duty)/30;
            obj.offset_duty_right_arm = 0;

            % Truncate values to the 4th decimal number
            obj.duty_90_deg = floor(obj.duty_90_deg * 10^4) / 10^4;
            obj.duty_180_deg = floor(obj.duty_180_deg * 10^4) / 10^4;
            obj.duty_grip_closed = floor(obj.duty_grip_closed * 10^4) / 10^4;
            obj.duty_grip_open = floor(obj.duty_grip_open * 10^4) / 10^4;
            obj.offset_duty_left_arm = floor(obj.offset_duty_left_arm * 10^4) / 10^4;
            obj.offset_duty_right_arm = floor(obj.offset_duty_right_arm * 10^4) / 10^4;


            obj.cube_ready = false;
            obj.cube_ready_old = false;

            obj.move_done_old = 1; % This is necessary so that initialization doesn't trigger the update of the current move
        end
    end
end
