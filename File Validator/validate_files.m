%% iKids Validate Files
% Parse two results files from iKids experiment and determine the degree of
% overlap between the two results.
%
% _validate_files(first_validation_filename, second_validation_filename,
% digits_of_precision, verbose_mode)_ - performs the parsing on the
% _first_validation_filename_ (string) and _second_validation_filename_
% (string) using the _digits_of_precision_ (optional integer) and
% _verbose_mode_ (optional integer where 0=no output, 1=minimal output,
% 2=verbose output). The output is a struct which contains the validation
% metrics. The struct contents are as follows:
%
% _total_count_ - the total number of time steps evaluated.
% _failure_count_ - the number of time steps in which the two files
% disagree.
%
% Last revised 9/15/15 by Kevin Horecka (kevin.horecka@gmail.com).
%
function [validation_metrics]=validate_files(first_validation_filename, second_validation_filename, digits_of_precision, verbose_mode)

% Check to make sure the proper number of arguments are being used
if nargin > 4 || nargin < 2
    error(['validate_files requires 2 inputs (filenames) plus 2 ' ...
        'optional input (digits of precision and verbose mode). ' ...
        'Check function call and try again.']);
end

% If optional argument is not provided, set it to default value
switch nargin
    case 2
        digits_of_precision = 3; % Default value for precision (MAGIC#)
        verbose_mode = 1;
    case 3
        verbose_mode = 1;
end

% Warn user if the digits of precision are too large
if digits_of_precision >= 4 % Warning level of precision (MAGIC#)
    warning(['Warning: Increasing the digits of precision beyond 4 ' ...
        'may make the processing time very long. Use CTRL+C to break' ...
        ' execution.']);
end

% Load the files using external loading script responsible for parsing
% the data into three arrays (1D cell array of strings, 1D cell array of
% strings, and 1D double matrix). The getValidationData function should
% throw an error if there was a problem loading the files.
if verbose_mode ~= 0 ; fprintf('Loading first validation file...\n'); end
[Phase1,Type1,Time1] = getValidationData(first_validation_filename);
if verbose_mode ~= 0 ; fprintf('Loading second validation file...\n'); end
[Phase2,Type2,Time2] = getValidationData(second_validation_filename);

% Validate that the Phase, Type and Time for the first file are the same
% length. If they aren't, this is a problem because it would mean the files
% somehow loaded items with missing data. Force stop with an error if this
% is the case.
if length(Phase1) ~= length(Type1) || length(Phase1) ~= length(Time1)
    error(['Error: The lengths of the phase, type, and time ' ...
    'variables are not equal for the first validation file. ' ...
    'Check the first validation file for formatting errors and ' ...
    'run the getValidationData script independently to confirm ' ...
    'the format is correct.']);
end

if length(Phase2) ~= length(Type2) || length(Phase2) ~= length(Time2)
    error(['Error: The lengths of the phase, type, and time ' ...
    'variables are not equal for the second validation file.' ...
    'Check the first validation file for formatting errors and ' ...
    'run the getValidationData script independently to confirm ' ...
    'the format is correct.']);
end

% Check to see if there's a perfect match in the number of phases in the
% files. If this warning is triggered, we already know there won't be 100%
% agreement. This allows individuals running this script to early terminate
% if they expect 100% agreement.
if length(Phase1) ~= length(Phase2)
    warning(['Warning: The lengths of the two validation files are ' ...
        'not equal. This is most likely not a problem but indicates ' ...
        'some level if inaccuracy in one of the files relative to the ' ...
        'other.']);
end

% BEGIN VALIDATION METRICS STRUCTURE

validation_metrics = struct('total_count', 0, ...
                            'total_failed', 0, ...
                            'proportion', 0, ...
                            'start_time_difference', 0, ...
                            'end_time_difference', 0);

% END VALIDATION METRICS STRUCTURE

% Calculate min, max and step for the two files time series in order to
% determine the window of time for comparison. The digits of precision are
% used to determine the step.

% Note: There is a design decision made here to use the minimum end time
% and the maximum start time thus excluding the data between the
% disparities in the start and end times. This decision can easily be 
step = 1/(10^digits_of_precision);

max1 = max(Time1);
max2 = max(Time2);
max_rounded = round(min(max1, max2) * 10^digits_of_precision) / ...
                                      10^digits_of_precision;

min1 = min(Time1);
min2 = min(Time2);
min_rounded = round(max(min1, min2) * 10^digits_of_precision) / ...
                                      10^digits_of_precision;

validation_metrics.start_time_difference = abs(min1 - min2);
validation_metrics.end_time_difference = abs(max1 - max2);
                                  
if verbose_mode ~= 0
    fprintf('Parsing files in time steps of %f from %f to %f...\n', ...
        step, min_rounded, max_rounded);
end

% Begin parse loop which will look ahead one time point in each file and
% iterate through the time series at fixed steps until the next time step
% is reached at which point the state index is iterated. This index is used
% to look up each line's phase and type for comparison. Upon a mismatch,
% whatever matrics should be run can be in order to calculate the agreement
% of both files.
first_index = 1;
second_index = 1;
first_time_next = Time1(first_index + 1);
second_time_next = Time2(first_index + 1);

for i = min_rounded:step:max_rounded
    % Check if first or second time stream need to be advanced by a sample
    if(first_time_next <= i)
        if verbose_mode == 2 ; fprintf('Advancing first index.\n'); end
        if first_index < numel(Time1) - 1
            first_index = first_index + 1; % Advance to next sample
        else
            if verbose_mode == 2
                fprintf('Cannot advance first index. End of Stream.\n');
            end
        end
        first_time_next = Time1(first_index+1); % Reload look ahead time
    end
    if second_time_next <= i
        if verbose_mode == 2 ; fprintf('Advancing second index.\n'); end
        if second_index < numel(Time2) - 1
            second_index = second_index + 1; % Advance to next sample
        else
            if verbose_mode == 2
                fprintf('Cannot advance second index. End of Stream.\n');
            end
        end
        second_time_next = Time2(second_index+1); % Reload look ahead time
    end
    
    if verbose_mode == 2 ; fprintf('t=%f\n', i); end
    % Check equality at time step i
    if ~strcmp(Phase1{first_index}, Phase2{second_index}) || ...
       ~strcmp(Type1{first_index}, Type2{second_index})
        % Failure case (two files are unequal)
        validation_metrics.total_failed = ...
            validation_metrics.total_failed + 1;
        validation_metrics.total_count = ...
            validation_metrics.total_count + 1;
        if verbose_mode == 2 
            fprintf('Value mismatch at %f. (%s, %s) ~= (%s, %s).\n', ...
                    i, Phase1{first_index}, Type1{first_index}, ...
                    Phase2{second_index}, Type2{second_index});
        end
    else
        % Success case (two files are equal)
        validation_metrics.total_count = ...
            validation_metrics.total_count + 1;
    end
end

validation_metrics.proportion = ...
    (validation_metrics.total_failed/validation_metrics.total_count);

% Print summary information
if verbose_mode ~= 0
    fprintf(['Of a total of %d indicies processed, %d did not match. ' ...
        'This is a %f percent failure rate.\n'], ...
        validation_metrics.total_count, ...
        validation_metrics.total_failed, ...
        validation_metrics.proportion*100);
end