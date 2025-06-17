%% WRITEXMLREC     Write a Philips XMLREC image file pair
%
% [SUCCESS] = WRITEXMLREC(FILENAME,DATA,INFO)
%
%   FILENAME is a string containing a file prefix or name of the XML header
%   file or REC data file, e.g. SURVEY_1 or SURVEY_1.XML or SURVEY_1.REC
%
%   DATA is an N-dimensional array holding the image data.
%
%   INFO is a structure containing details from the XML header file.
%
%   DATA and INFO should have the format as that returned by LOADXMLREC
%
% [SUCCESS] = WRITEXMLREC(FILENAME,[],INFO)
%
%   When DATA is an empty array, only the XML file is written using the
%   INFO structure.
%
%  See also: LOADXMLREC
%
%  Dependencies: XMLRECWRITEEXML
%

%% Revision History
% * 2009.03.21    initial version - brianwelch

%% Function definition
function success = writeXMLREC(filename,data,info)

% Assume successful unless proven to be otherwise
success = 1;

%% Parse the filename.
% It may be the XML filename, REC filename or just the filename prefix
% Instead of REGEXP, use REGEXPI which igores case
filename = regexprep(filename,'\\*','/');
toks = regexpi(filename,'^(.*?)(\.XML|\.REC)?$','tokens');
fileprefix = toks{1}{1};
xmlname = sprintf('%s.XML',fileprefix);
recname = sprintf('%s.REC',fileprefix);

%% Determine order for writing
% sort linearized info.table_row_index_array and keep sorted indices
[dummy, write_order_indices] = sort(info.table_row_index_array(:)); 

%% Write XML file
if isfield(info,'xmlrec_struct'),
    XMLRECwritexml(info.xmlrec_struct,xmlname);
else
    error('info.xmlrec_struct does not exist');
end

%% Write REC file if data is not empty
if ~isempty(data),
    
fidrec = fopen(recname,'wb','ieee-le');
 
% temporarily reshape data to a continuous stack of images
size_data = size(data);
data = reshape(data,[size_data(1) size_data(2) info.n_data_imgs]);

% loop through all image dimensions
for k=1:length(write_order_indices),
    
    % find the table_row_index that is associated with this image
    table_row_index = info.table_row_index_array( write_order_indices(k) );
   
    if(table_row_index>0),        
        % rescale intercept
        ri = info.imgdef.rescale_intercept.vals(table_row_index);

        % rescale slope
        rs = info.imgdef.rescale_slope.vals(table_row_index);

        % scale slope
        ss = info.imgdef.scale_slope.vals(table_row_index);

        % convert data for writing
        tmpimg = data(:,:, write_order_indices(k) );
        % Apply image scaling by using info.table_index & info.table
        switch info.loadopts.scale
            case 'FP',
                %data(:,:,k) = (data(:,:,k) * rs + ri)/(rs * ss);
                tmpimg = ( tmpimg * (rs * ss) - ri ) / rs;
            case 'DV',
                %data(:,:,k) = data(:,:,k) * rs + ri;
                tmpimg = ( tmpimg - ri ) / rs;
            case 'PV',
                % do nothing
                % values are already the pixel value stored in the REC file
                % tmpimg = tmpimg;
            otherwise,
                if(k==1),
                    warning( sprintf('Unkown scale type option : ''%s''.  Will assumme floating point (''FP'') instead',info.loadopts.scale) );
                end
                tmpimg = ( tmpimg * (rs * ss) - ri ) / rs;
        end   
        % transpose image
        tmpimg = tmpimg.';       
        if info.pixel_bits==16,
            count = fwrite(fidrec,tmpimg(:),'int16','ieee-le');
        elseif info.pixel_bits==8,
            count = fwrite(fidrec,tmpimg(:),'int8','ieee-le');
        else
            error( sprintf('Unsupported image pixel bits : %d', info.pixel_bits) );
        end    
    end 
end
fclose(fidrec);

end

%% end parent function writeXMLREC
end

