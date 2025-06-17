function [rec_data, fileToRead1, par_data, par_txt] = import_parrec_special_WT2_LH( in_type, name_filter, filename)
%% 

% [rec_data, par_data, par_txt] = import_parrec()
%  Imports data from the specified file
%  FILETOREAD1:  file to read
%  Maarten Versluis: read PAR / REC files

DELIMITER = ' ';
if (nargin == 4)
    % old PAR/REC format version 4.2 has 97 headerlines
    HEADERLINES = 97;
else
    HEADERLINES = 99;
end
if (nargin == 1)
    [file, dir] = uigetfile('*.PAR');  
    fileToRead1 = strcat(dir, file);
elseif (nargin == 2)
    [file, dir] = uigetfile(strcat('*',name_filter,'*.PAR'));
    fileToRead1 = strcat(dir, file);
else
    fileToRead1 = filename;
    dir = sprintf('%s',pwd);
end
assignin('base','directory',dir);

base_name = fileToRead1(1: (length(fileToRead1)-3));
par_name = strcat(base_name, 'PAR');
rec_name = strcat(base_name, 'REC');

% Import the PAR-file
parData = importdata(par_name, DELIMITER, HEADERLINES);
par_txt = parData.textdata;
par_data = parData.data;
assignin('base','par_data',par_data);
% Import the REC-file
fid = fopen(rec_name);

%put right dimensions...
x_dim = max(par_data(:,10)); % maximale waarde van kolom 10 van numerieke gedeelte par file
y_dim = max(par_data(:,11));
slices = max(par_data(:,1));
echoes = max(par_data(:,2));
dynamics = max(par_data(:,3));
phases = max(par_data(:,4));
index = max(par_data(:,7))+1;
types = max(par_data(:,5))+1;
pca_types = length(count_unique(par_data(:,6)));
lab_types=max(par_data(:,49));
rec_data = zeros(x_dim, y_dim, slices, echoes, phases, dynamics,types,pca_types,lab_types,'single');

assignin('base','x_dim',x_dim); % exports variable x_dim to base work space (with name 'x_dim') so it can be used in script that calls the function
assignin('base','y_dim',y_dim);
assignin('base','z_dim',slices);
assignin('base','lab_types',lab_types);
assignin('base','dyn_cnt',dynamics);
assignin('base','phase_cnt',phases);
assignin('base','x_size',par_data(1,29));
assignin('base','y_size',par_data(1,30));
assignin('base','z_size',par_data(1,23)+par_data(1,24));
assignin('base','echoes',echoes);
assignin('base','img_types',types);
assignin('base','img_cnt',index);

for i = 1:index
    slice = par_data(i,1);
    echo = par_data(i,2);
    phase = par_data(i,4);
    dynamic = par_data(i,3);
    type = par_data(i,5)+1;
    pca_type = find(count_unique(par_data(:,6)) == par_data(i,6));
    %    pca_type = par_data(i,6)+1;
    lab_type = par_data(i,49);
    RI = par_data(i, 12); % scaling parameters
    RS = par_data(i, 13); % scaling parameters
    SS = par_data(i, 14); % scaling parameters
    if ((type == in_type) || (type == 8)) %type == 8 i B1 map
        STATUS = fseek(fid, (i-1)*x_dim*y_dim*2, -1);
        temp = ((fread(fid,x_dim*y_dim,'int16')* RS) + RI) / (RS * SS);
        rec_data(:, :, slice, echo, phase, dynamic, type, pca_type,lab_type) = fliplr(reshape(temp,x_dim,y_dim));
    end
end
fclose(fid);
rec_data = squeeze(rec_data);
end

% included function count_unique
function [uniques,numUnique] = count_unique(x,option)
%COUNT_UNIQUE  Determines unique values, and counts occurrences
%   [uniques,numUnique] = count_unique(x)
%
%   This function determines unique values of an array, and also counts the
%   number of instances of those values.
%
%   This uses the MATLAB builtin function accumarray, and is faster than
%   MATLAB's unique function for intermediate to large sizes of arrays for integer values.  
%   Unlike 'unique' it cannot be used to determine if rows are unique or 
%   operate on cell arrays.
%
%   If float values are passed, it uses MATLAB's logic builtin unique function to
%   determine unique values, and then to count instances.
%
%   Descriptions of Input Variables:
%   x:  Input vector or matrix, N-D.  Must be a type acceptable to
%       accumarray, numeric, logical, char, scalar, or cell array of
%       strings.
%   option: Acceptable values currently only 'float'.  If 'float' is
%           specified, the input x vector will be treated as containing
%           decimal values, regardless of whether it is a float array type.
%
%   Descriptions of Output Variables:
%   uniques:    sorted unique values
%   numUnique:  number of instances of each unique value
%
%   Example(s):
%   >> [uniques] = count_unique(largeArray);
%   >> [uniques,numUnique] = count_unique(largeArray);
%
%   See also: unique, accumarray

% Author: Anthony Kendall
% Contact: anthony [dot] kendall [at] gmail [dot] com
% Created: 2009-03-17

testFloat = false;
if nargin == 3 && strcmpi(option,'float')
    testFloat = true;
end

nOut = nargout;
if testFloat
    if nOut < 2
        [uniques] = float_cell_unique(x,nOut);
    else
        [uniques,numUnique] = float_cell_unique(x,nOut);
    end
else
    try %this will fail if the array is float or cell
        if nOut < 2
            [uniques] = int_log_unique(x,nOut);
        else
            [uniques,numUnique] = int_log_unique(x,nOut);
        end
    catch %default to standard approach
        if nOut < 2
            [uniques] = float_cell_unique(x,nOut);
        else
            [uniques,numUnique] = float_cell_unique(x,nOut);
        end
    end
end

end

function [uniques,numUnique] = int_log_unique(x,nOut)
%Check to see if accumarray is appropriate for this function
maxVal = max(x(:));
if maxVal / numel(x) > 1000
    error('Accumarray is inefficient for arrays when ind values are >> than the number of elements')
end
%First, determine the offset for negative values
minVal = min(x(:));
if minVal < 1
    %Now, offset to get the index
    index = x(:) - minVal + 1;

    %Get the number of duplicates with accumarray
    numUnique = accumarray(index,1);

    %Get the sum of those duplicate values
    sumDups = accumarray(index,x(:));
else
    %Get the number of duplicates with accumarray
    numUnique = accumarray(x(:),1);

    %Get the sum of those duplicate values
    sumDups = accumarray(x(:),x(:));
end

%Find numUnique > 0
test = (numUnique > 0);

%Determine the unique values
uniques = sumDups(test) ./ (numUnique(test));

if nOut == 2
    %Trim the numUnique array
    numUnique = numUnique(test);
end
end

function [uniques,numUnique] = float_cell_unique(x,nOut)

if ~iscell(x)
    %First, sort the input vector
    x = sort(x(:));
    numelX = numel(x);
    
    %Check to see if the array type needs to be converted to double
    currClass = class(x);
    isdouble = strcmp(currClass,'double');
    
    if ~isdouble
        x = double(x);
    end
    
    %Check to see if there are any NaNs or Infs, sort returns these either at
    %the beginning or end of an array
    if isnan(x(1)) || isinf(x(1)) || isnan(x(numelX)) || isinf(x(numelX))
        %Check to see if the array contains nans or infs
        xnan = isnan(x);
        xinf = isinf(x);
        testRep = xnan | xinf;
        
        %Remove all of these from the array
        x = x(~testRep);
    end
    
    %Determine break locations of unique values
    uniqueLocs = [true;diff(x) ~= 0];
else
    isdouble = true; %just to avoid conversion on finish
    
    %Sort the rows of the cell array
    x = sort(x(:));
    
    %Determine unique location values
    uniqueLocs = [true;~strcmp(x(1:end-1),x(2:end)) ~= 0] ;
end

%Determine the unique values
uniques = x(uniqueLocs);

if ~isdouble
    x = feval(currClass,x);
end

%Count the number of duplicate values
if nOut == 2
    numUnique = diff([find(uniqueLocs);length(x)+1]);
end
end
