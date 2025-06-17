%% WRITEPARREC     Write a Philips PARREC image file
%
% [SUCCESS] = WRITEPARREC(FILENAME,DATA,INFO)
%
%   FILENAME is a string containing a file prefix or name of the PAR header
%   file or REC data file, e.g. SURVEY_1 or SURVEY_1.PAR or SURVEY_1.REC
%
%   DATA is an N-dimensional array holding the image data.
%
%   INFO is a structure containing details from the PAR header file.
%
%   VERSION is a string specifying the PARREC version to which to convert,
%   e.g. '3', '4', '4.1' or '4.2'
%
%   DATA and INFO should have the format as that returned by LOADPARREC
%
% [SUCCESS] = WRITEPARREC(FILENAME,[],INFO)
%
%   When DATA is an empty array, only the PAR file is written using the
%   INFO structure.  Useful for conversions.
%
%  See also: LOADPARREC, CONVERTPARREC
%

%% Revision History
% * 2008.05.01    initial version - welcheb
% * 2008.05.16    cleaned up and commented - welcheb
% * 2008.05.20    corrected filename parse bug - welcheb
% * 2011.10.20    write dynamic scans as sorted - welcheb
% * 2011.10.26    changed sort order to  {'sl' 'dyn' 'ec'  'ph'  'ty'  'seq'  'b'  'grad'  'asl'} - welcheb
% * 2011.12.07    correct sorted DTI problem - welcheb
% * 2011.12.07    changed sort order to  {'b'  'sl' 'dyn' 'ec'  'ph'  'ty'  'seq'  'grad'  'asl'} - welcheb

%% Function definition
function success = writeParRec(filename,data,info,version)

% Assume successful unless proven to be otherwise
success = 1;

%% If no version provided, default to the version in the info structure
if nargin<4,
    version=info.version;
end
if ischar(version),
    version = str2num(version);
end

%% Parse the filename.
% It may be the PAR filename, REC filename or just the filename prefix
% Instead of REGEXP, use REGEXPI which igores case
filename = regexprep(filename,'\\*','/');
toks = regexpi(filename,'^(.*?)(\.PAR|\.REC)?$','tokens');
fileprefix = toks{1}{1};
parname = sprintf('%s.PAR',fileprefix);
recname = sprintf('%s.REC',fileprefix);

%% Load Philips PAR description structure
philips = dictPARREC;
pardef_names = fieldnames(philips.pardef);
parformat_names = fieldnames(philips.parformat);
imgdef_names = fieldnames(philips.imgdef);

%% Determine order for writing
% sort linearized info.table_row_index_array and keep sorted indices
%[dummy, write_order_indices] = sort(info.table_row_index_array(:)); 

% sort write_order_indices
%
% {'sl'  'ec'  'dyn'  'ph'  'ty'  'seq'  'b'  'grad'  'asl'} in PAR table column order
%
% becomes
%
% {'b'  'sl' 'dyn' 'ec'  'ph'  'ty'  'seq'  'grad'  'asl'} % b-value first for DTI/DWI convenience
%
% slice_number then echo_number then cardiac_phase_number then image_type_mr then scanning_sequence then diffusion_b_value_number_imagekey then gradient_orientation_number_imagekey then label_type_ASL then dynamic
%
row_indices_1 = info.table_row_index_array(:);
invalid_indices = find(row_indices_1==0);
row_indices_2 = row_indices_1;
row_indices_2(invalid_indices) = 1; % invalid row indices are replaced just temporarily to build matrix to calculate sort order
tmp = [ ...
    info.imgdef.diffusion_b_value_number_imagekey.vals(row_indices_2) ...
    info.imgdef.slice_number.vals(row_indices_2) ...
    info.imgdef.dynamic_scan_number.vals(row_indices_2) ... 
    info.imgdef.echo_number.vals(row_indices_2) ...
    info.imgdef.cardiac_phase_number.vals(row_indices_2) ...
    info.imgdef.image_type_mr.vals(row_indices_2) ...
    info.imgdef.scanning_sequence.vals(row_indices_2) ...
    info.imgdef.gradient_orientation_number_imagekey.vals(row_indices_2) ...
    info.imgdef.label_type_ASL.vals(row_indices_2) ...
    ]; 
% before the sort, the invalid indices must be replaced by Inf (will be placed at the end)
tmp(invalid_indices,:) = Inf;
[dummy, write_order_indices_sorted] = sort(tmp);
write_order_indices_sorted = write_order_indices_sorted(:,1);

%% Write PAR file
fidpar = fopen(parname,'w');
for k=1:length(parformat_names),
    parformat_name = parformat_names{k};
    if isfield(philips.parformat.(parformat_name),'func_call'),
        eval( philips.parformat.(parformat_name).func_call );
    else
        par_min_version = philips.parformat.(parformat_name).par_min_version;
        par_max_version = philips.parformat.(parformat_name).par_max_version;
        if (version>=par_min_version) & (version<=par_max_version),
            lines = philips.parformat.(parformat_name).lines;
            for n=1:length(lines),
                fprintf(fidpar,'%s\r\n',lines{n});
            end
        end 
    end
end
fclose(fidpar);

%% Write REC file if data is not empty
if ~isempty(data),
    
fidrec = fopen(recname,'wb','ieee-le');
 
% temporarily reshape data to a continuous stack of images
size_data = size(data);
data = reshape(data,[size_data(1) size_data(2) info.n_data_imgs]);

% loop through all image dimensions
for k=1:length(write_order_indices_sorted),
    
    % find the table_row_index that is associated with this image
    table_row_index = info.table_row_index_array( write_order_indices_sorted(k) );
    
    if(table_row_index>0),        
        % rescale intercept
        ri = info.imgdef.rescale_intercept.vals(table_row_index);

        % rescale slope
        rs = info.imgdef.rescale_slope.vals(table_row_index);

        % scale slope
        ss = info.imgdef.scale_slope.vals(table_row_index);

        % convert data for writing
        tmpimg = data(:,:, write_order_indices_sorted(k) );
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

%% begin internal function print_dataset_name
function print_dataset_name
    fprintf(fidpar,'# Dataset name: %s\r\n',fileprefix);
    fprintf(fidpar,'#\r\n');
%% end internal function print_dataset_name
end

%% begin internal function print_pardef
function print_pardef
    for k=1:length(pardef_names),
        pardef_name = pardef_names{k};
        par_min_version = philips.pardef.(pardef_name).par_min_version;
        par_max_version = philips.pardef.(pardef_name).par_max_version;
        if (version>=par_min_version) & (version<=par_max_version),
            par_definition = philips.pardef.(pardef_name).par_definition;
            if length(par_definition)>0,
                pardef_fieldname = philips.pardef.(pardef_name).pardef_fieldname;
                if isfield(info.pardef,pardef_fieldname),
                    pardef_value_str = info.pardef.(pardef_fieldname);
                else
                    pardef_value_str = philips.pardef.(pardef_name).default;
                end
                fprintf(fidpar,'%s%s\r\n',par_definition,pardef_value_str);
            end
        end
    end
%% end internal function print_dataset_name
end

%% begin internal function print_imgdef
function print_imgdef
    for k=1:length(imgdef_names),
        imgdef_name = imgdef_names{k};
        par_min_version = philips.imgdef.(imgdef_name).par_min_version;
        par_max_version = philips.imgdef.(imgdef_name).par_max_version; 
        if (version>=par_min_version) & (version<=par_max_version),
            par_definition = philips.imgdef.(imgdef_name).par_definition;
            if length(par_definition)>0,
                fprintf(fidpar,'%s\r\n',par_definition);
            end
        end
    end
%% end internal function print_imgdef
end

%% begin internal function print_imgdef_table
function print_imgdef_table
    rec_index = 0;
    for k = 1:length(write_order_indices_sorted),
        table_row_index = info.table_row_index_array( write_order_indices_sorted(k) );
        if(table_row_index>0),
            % increment REC index
            rec_index = rec_index + 1;
            for n=1:length(imgdef_names),
                imgdef_name = imgdef_names{n};
                par_min_version = philips.imgdef.(imgdef_name).par_min_version;
                par_max_version = philips.imgdef.(imgdef_name).par_max_version;
                if (version>=par_min_version) & (version<=par_max_version),
                    if isfield(philips.imgdef.(imgdef_name),'imgdef_fieldname'),
                        imgdef_fieldname = philips.imgdef.(imgdef_name).imgdef_fieldname;
                        if isfield(philips.imgdef.(imgdef_name),'par_print'),
                            par_print = philips.imgdef.(imgdef_name).par_print;
                        else
                            par_print = ' %.2f';
                        end
                        if isfield(info.imgdef,imgdef_fieldname),
                            if findstr(imgdef_fieldname,'index_in_REC_file_in_images'),
                                imgtable_value = rec_index-1;
                            else
                                imgtable_value = info.imgdef.(imgdef_fieldname).vals(table_row_index,:);
                            end
                            imgtable_value_str = sprintf(par_print,imgtable_value);
                        else
                            if isfield(philips.imgdef.(imgdef_name),'default'),
                                imgtable_value_str = sprintf(par_print,philips.imgdef.(imgdef_name).default);
                            else
                                imgtable_value_str = sprintf(par_print,0);
                            end
                        end
                        fprintf(fidpar,'%s',imgtable_value_str);
                    end
                end
            end
            fprintf(fidpar,'\r\n');
        end
    end
%% end internal function print_imgdef_table
end
    
%% end parent function writeParRec
end

