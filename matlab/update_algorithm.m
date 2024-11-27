function moves = update_algorithm(moves, solve, rotate, varargin)
% This function manages the sequence of moves needed to solve the given
% Rubik's cube.
% If 'solve' is set to true, the cube configuration must be given as argument
% ('cube'), so that the solution can be initialized. Otherwise, if 'rotate'
% is set to ,true the sequence of moves is retrieved from the global scope and
% updated according to the given rotation ('rotation').
% The moves sequence is always converted back to an array of chars vectors.

if solve
    if nargin == 5 && strcmpi(varargin{1}, 'cube') % Check if cube configuration was given
        moves_str = Solve45(rubgen(3,23)); % Solve cube
    else
        disp("No cube configuration was given. Did you mean update_algortihm(true, false, 'cube', cube)?");
        return;
    end

    % Convert double inverted moves into two distinct moves
    k = 1;
    while k <= length(moves_str)
         % Check if the current string has length 3 and ends with "'"
         if strlength(moves_str(k)) == 3 && moves_str(k).endsWith("'")
             % Extract the first two characters of the string
             firstTwoChars = extractBefore(moves_str(k), 3); 
             % Create two new moves of length 2
             newMove1 = firstTwoChars; % Same as the first two characters
             newMove2 = firstTwoChars; % Same as the first two characters
             % Substitute the current element with the first new string
             moves_str(k) = newMove1;
             % Insert the second new move immediately after the current index
             moves_str = [moves_str(1:k), newMove2, moves_str(k+1:end)];
             % Move to the next element after the newly
             % inserted move
             k = k + 1; 
         end
          % Increment the index
         k = k + 1;
    end
    % Update the object moves sequence, converting moves_str to
    % an array of chars vectors
    moves = arrayfun(@(s) uint8(char(s)), moves_str, 'UniformOutput', false);
elseif rotate
    if nargin == 5 && strcmpi(varargin{1}, 'rotation')
        % Convert first the moves uint8 matrix back to a single row cell array
        % of strings, trimming off all those rows set to 0. This is needed
        % for compatibility with algrot
        first_null_row_idx = find(all(moves == 0, 2), 1); % Index of the first row of all zeros
        moves_cell_array = arrayfun(@(row) char(moves(row, :)), 1:size(moves, 1), 'UniformOutput', false); % Convert it to a cell array of strings

        % Rotate the POV of the moves sequence
        new_moves = algrot(moves_cell_array(1:(first_null_row_idx-1)), varargin{2});
        
        % Update the object moves sequence, converting new_moves to
        % an array of chars vectors
        moves = arrayfun(@(s) uint8(char(s)), new_moves, 'UniformOutput', false);
        
    else
        disp("No cube rotation was given. Did you mean update_algortihm(false, true, 'rotation', rotation)?");
        return;
    end

end

new_moves = uint8((zeros(45, 2)));

% Convert the moves from a single row cell array of chars vectors back to a
% matrix of uint8, where each row is a move
for i = 1:length(moves)
    new_moves(i, :) = uint8([cell2mat(moves(:, i)), zeros(1, 2 - length(cell2mat(moves(:, i))))]);
end

% Update moves
moves = new_moves;
