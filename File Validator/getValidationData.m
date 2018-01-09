%% iKids Validation Data Loader
% Parse a validation file which is expected to be a delimited (see strsplit
% documentation for valid delimeters) 3 column file which contains a Phase
% string, Type string, and Time double. The two strings in question must
% not contain multiple words or they will be parsed as additional columns
% (use underscores if necessary). Prefix words 'Coder', 'Subject', and
% 'Note' may be used at the beginning of lines which should be ignored by
% the parser. Empty lines are also ignored.
%
% _getValidationData(filename)_ - performs the parsing on the
% _filename_ (string). The output is three arrays. The first array
% represents the first column (labelled Phase) of strings in the form of a
% 1D cell array. The second array represents the second column (labelled
% Type) of strings in the form of a 1D cell array. The third array
% represents the third column (labelled Time) of doubles in the form of a
% 1D matrix.
%
% Last revised 9/15/15 by Kevin Horecka (kevin.horecka@gmail.com).
%
function [Phase,Type,Time]=getValidationData(filename)

fid = fopen(filename);

% If one of the prefix strings is at the beginning of a line it will be
% ignored
ignore_prefixes = {'Coder', 'Subject', 'Note'};

% Create the output arrays and indexer for counting inputs
Phase = [];
Type = [];
Time = [];
index = 1;

% Read first line and parse
tline = fgets(fid);
% Check for prefixes and empty line
ignore_line = strcmp(tline, '');
for prefix=ignore_prefixes
    if ignore_line || strcmp(tline(1:length(prefix{1})), prefix{1})
        ignore_line = true;
        break;
    end
end
% If there is no prefix to rule out the line, add it to the data
if ~ignore_line
    tline_data = strsplit(tline);
    Phase{index} = tline_data{1};
    Type{index} = tline_data{2};
    Time{index} = str2double(tline_data{3});
    index = index + 1;
end
% Continue parsing all lines
while ischar(tline)
    try
        % This gets the next line, but it will fail if the line is at the
        % end of the file - then we break.
        tline = strtrim(fgets(fid));
    catch
        break;
    end
    % Check for prefixes and empty line
    ignore_line = strcmp(tline, '');
    for prefix=ignore_prefixes
        if ignore_line || strcmp(tline(1:length(prefix{1})), prefix{1})
            ignore_line = true;
            break;
        end
    end
    % If there is no prefix to rule out the line, add it to the data
    if ~ignore_line
        tline_data = strsplit(tline);
        Phase{index} = tline_data{1}; %#ok<AGROW>
        Type{index} = tline_data{2}; %#ok<AGROW>
        Time{index} = str2double(tline_data{3}); %#ok<AGROW>
        index = index + 1;
    end
end

% Reformat the Time cell array into a matrix for convenience
Time = cell2mat(Time);

% Close the file reference
fclose(fid);