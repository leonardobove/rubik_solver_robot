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

        function stepImpl(obj, BR_duty, TR_duty, BL_duty, TL_duty, move_done, SIL)
            global cube;
            global alignment_done;
            global moves;
            global current_move_idx;
            global execute_move;

            % If the alignment has been done and we are in SIL execution,
            % the cube is simulated and is ready
            if ~obj.cube_ready
                if alignment_done == 1 && SIL == 1
                    obj.cube_ready = true;
                elseif all(cube(:) ~= 0) && SIL == 0 % If not in SIL execution, check if all the faces have been read
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
            BR_duty_truncated = floor(BR_duty * 10^4) / 10^4;
            TR_duty_truncated = floor(TR_duty * 10^4) / 10^4;
            BL_duty_truncated = floor(BL_duty * 10^4) / 10^4;
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
                elseif TR_duty_truncated == obj.duty_grip_closed && TL_duty_truncated == obj.duty_grip_open && BR_duty_truncated < obj.BR_duty_old
                    % Clockwise rotation of the right arm with the left grip
                    % open (x3)
                    cube = rubrot2(cube, 'x3', 'animate', 1);
                    drawnow;

                    % Rotate algorithm
                    moves = update_algorithm(moves, false, true, 'rotation', 'x1');
                elseif TR_duty_truncated == obj.duty_grip_closed && TL_duty_truncated == obj.duty_grip_closed && BR_duty_truncated > obj.BR_duty_old
                    % Counter-clockwise rotation of the right arm with the left
                    % grip closed (x11)
                    cube = rubplot(cube, 'x11');
                    drawnow;
                elseif TR_duty_truncated == obj.duty_grip_closed && TL_duty_truncated == obj.duty_grip_closed && BR_duty_truncated < obj.BR_duty_old
                    % Clockwise rotation of the right arm with the left grip
                    % closed (x13)
                    cube = rubplot(cube, 'x13');
                    drawnow;
                elseif TL_duty_truncated == obj.duty_grip_closed && TR_duty_truncated == obj.duty_grip_open && BL_duty_truncated > obj.BL_duty_old
                    % Counter-clockwise rotation of the left arm with the right
                    % grip open (z1)
                    cube = rubrot2(cube, 'z1', 'animate', 1);
                    drawnow;

                    % Rotate algorithm
                    moves = update_algorithm(moves, false, true, 'rotation', 'z3');
                elseif TL_duty_truncated == obj.duty_grip_closed && TR_duty_truncated == obj.duty_grip_open && BL_duty_truncated < obj.BL_duty_old
                    % Clockwise rotation of the left arm with the right grip
                    % open (z3)
                    cube = rubrot2(cube, 'z3', 'animate', 1);
                    drawnow;

                    % Rotate algorithm
                    moves = update_algorithm(moves, false, true, 'rotation', 'z1');
                elseif TL_duty_truncated == obj.duty_grip_closed && TR_duty_truncated == obj.duty_grip_closed && BL_duty_truncated > obj.BL_duty_old
                    % Counter-clockwise rotation of the left arm with the right
                    % grip closed (z31)
                    cube = rubplot(cube, 'z31');
                    drawnow;
                elseif TL_duty_truncated == obj.duty_grip_closed && TR_duty_truncated == obj.duty_grip_closed && BL_duty_truncated < obj.BL_duty_old
                    % Clockwise rotation of the left arm with the right grip
                    % closed (z33)
                    cube = rubplot(cube, 'z33');
                    drawnow;
                end
            end

            % After applying rotations (rising edge of move_done), update current move index if the
            % move is completed and start move execution
            if move_done == 1 && obj.move_done_old == 0
                current_move_idx = uint16(current_move_idx + 1);
                execute_move = 1;
            elseif move_done == 0
                execute_move = 0;
            end

            % Update duty cycle values
            obj.BR_duty_old = BR_duty_truncated;
            obj.TR_duty_old = TR_duty_truncated;
            obj.BL_duty_old = BL_duty_truncated;
            obj.TL_duty_old = TL_duty_truncated;

            obj.cube_ready_old = obj.cube_ready;

            obj.move_done_old = move_done;
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
            obj.duty_grip_closed = obj.min_duty + (obj.max_duty-obj.min_duty)/15;

            % Truncate values to the 4th decimal number
            obj.duty_90_deg = floor(obj.duty_90_deg * 10^4) / 10^4;
            obj.duty_180_deg = floor(obj.duty_180_deg * 10^4) / 10^4;
            obj.duty_grip_closed = floor(obj.duty_grip_closed * 10^4) / 10^4;
            obj.duty_grip_open = floor(obj.duty_grip_open * 10^4) / 10^4;

            obj.cube_ready = false;
            obj.cube_ready_old = false;

            obj.move_done_old = 0;
        end
    end
end
