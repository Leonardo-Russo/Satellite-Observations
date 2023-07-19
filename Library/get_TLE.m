function [name, tle1, tle2] = get_TLE(tlefile)

TLEData = readlines(tlefile);   % read each line of input file

n = length(TLEData) - 1;    % actual n° of rows in file

% Initialize 3 Arrays to store the Data
name = [];
tle1 = [];
tle2 = [];

% Check the Input File for Missing Lines
if rem(n,3) ~= 0
    error('Invalid Input File')
end


% Build the Data Arrays by appending elements vertically
for i = 1 : n
    
    line = TLEData(i);

    if rem(i,3) == 1
        name = [name; line];
    elseif rem(i,3) == 2
        tle1 = [tle1; char(line)];
    elseif rem(i,3) == 0
        tle2 = [tle2; char(line)];
    end

end

end