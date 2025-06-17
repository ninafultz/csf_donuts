%% LOADDICOM     Load a Philips DICOM image file
%
% [DATA,INFO] = LOADDICOM(FILENAME)
%
%   FILENAME is a string containing the name of a DICOM
%   DATA is an N-dimensional array holding the image data.
%   INFO is a structure containing details from the DICOM header file
%
% [DATA,INFO] = LOADDICOM([])
%
%   When the passed FILENAME is not provided or is an empty array or empty 
%   string.  The user chooses a file using UIGETFILE.
%
% [DATA,INFO] = LOADDICOM(FILENAME,'OptionName1',OptionValue1,...)
%
%   Options can be passed to LOADDICOM to control the range/pattern of
%   loaded data, the scale of the returned, verbose output, etc.  The list 
%   below shows the avialable options.  Names are case-sensitive
%
%       OptionName          OptionValue     Description     PARREC Version
%       ----------          -----------     -----------     --------------
%       'version'           numeric         PARREC version     
%       'info'              struct          dicom info structure
%       'x'                 numeric         image rows      >=V3
%       'y'                 numeric         image columns   >=V3
%       'sl'                numeric         slices          >=V3
%       'ec'                numeric         echoes          >=V3
%       'dyn'               numeric         dynamics        >=V3
%       'ph'                numeric         cardiac phases  >=V3
%       'ty'                numeric         image types     >=V3
%       'seq'               numeric         scan sequences  >=V3
%       'b'                 numeric         diff b values   >=V4.1
%       'grad'              numeric         diff grad dirs  >=V4.1
%       'asl'               numeric         label types     >=V4.2
%       'scale'             string          [ {'FP'} | 'DV' | 'PV' ]
%       'verbose'           logical         [ true |{false}]
%       'savememory'        logical         [ true |{false}]
%       'reducesingletons'  logical         [{true}| false ]
%       'waitbar'           logical         [ true |{false}]
%
%       When 'savememory' is true, SINGLE precision is used instead of DOUBLE
%
%       When 'reducesingletons' is true, the loaded DATA array is checked 
%       for any dimension that has only one single value with loaded images.  
%       If such a dimension is found, only the single dimension is preserved
%       and the other empty values are eliminated.
%
%   Example:
%       myfile = 'example.dcm';
%       [data,info] = loadDICOM(myfile,'sl',[1 5],'scale','DV','verbose',true);
%
% [DATA,INFO] = LOADDICOM(FILENAME,LOADOPTS)
%
%   LOADOPTS is a structure with fieldnames equal to any of the possible
%   OptionNames.
%
%   Example:
%       loadopts.sl = [1 5];
%       loadopts.scale = 'DV';
%       loadopts.verbose = true;
%       [data,info] = loadDICOM(myfile,loadopts);
%
%   For any dimension, values may be repeated and appear in any order.
%   Values that do not intersect with the available values for that
%   dimension will be ignored.  If the intersection of the user-defined
%   dimension values and the available dimension range has length zero, an
%   error is generated.  The order of the user-defined pattern is preserved.
%
%   Example:
%       % load a specific pattern of slice (-1 will be ignored)
%       loadopts.sl = [1 1 2 1 1 2 -1];
%       [data,info] = loadDICOM(myfile,loadopts);
%
% INFO = LOADDICOM(FILENAME)
%
%   If only one return argument is provided, the INFO structure will be
%   returned.  DATA will not be loaded.
%
% INFO structure contents
%
%   The INFO structure contains all the information from the DICOM header in
%   addition to other useful information to describe and to work with the
%   loaded DATA array.  Most top level fieldnames in the INFO structure
%   correspond closely with the text description within the DICOM file. The 
%   table below describes some of the additional fields found within INFO
%
%   FieldName           Description
%   ---------           -----------
%   FILENAME            filename of the loaded data
%   VERSION             version number of the PARREC created from the DICOM header
%   LOADOPTS            structure containing the load options (see above)
%   IMGDEF              structure containing the image defintion columns
%   N_DICOM_IMGS        number of total images avialable in the DICOM file
%   PIXEL_BITS          bits per pixel for the stored REC data
%   READ_TYPE           REC data file read data type, e.g. 'int16'
%   IMG_PIXELS          number of pixels in one original stored image
%   RECON_X             recontructed image size in the x (row) direction
%   RECON_Y             recontructed image size in the y (column) direction
%   DIMS                structure containing the DATA dimension names and values
%   DATASIZE            array showing the size of the returned DATA array
%   N_LOADED_IMGS       number of images loaded from the DICOM file
%   N_DATA_IMGS         number of total images in the DATA array
%
%   The INFO.IMGDEF structure contains fields for every column decsribed by
%   the image table inside the DICOM file.  It also stores the entire table
%   in INFO.IMGDEF.TABLE.  Finally, the INFO.IMGDEF.TABLE_ROW_INDEX_ARRAY
%   is a special array that is the same size as the DATA array (minus the
%   first two dimensions used to store a single image).  A given index for
%   a given image in the DATA array will return the row number describing
%   the details of that image in the INFO.IMGDEF.TABLE array when that same
%   index is used with the INFO.IMGDEF.TABLE_ROW_INDEX_ARRAY.  This provides
%   a quick way to recall the image defintion details of any individual
%   image contained within DATA.  If the INFO.IMGDEF.TABLE_ROW_INDEX_ARRAY
%   holds a ZERO for a given index, there was no image in the DICOM data 
%   that matched the dimension location in DATA.  This often occurs with
%   diffusion data and B1 mapping data.  Such empty locations will be all
%   ZEROES in the DATA array.
%
%
%  See also: LOADXXPARS, LOADPARREC, LOADXMLREC, LOADLABRAW
%
%  Dependencies: none
%

%% Revision History
% 2008.03.01    Initial version - brianwelch

%% Function definition
function [data,info] = loadDICOM(filename,varargin)

%% Start execution time clock and initialize DATA and INFO to empty arrays
tic;
data=[];
info=[];

%% Initialize INFO structure
% Serves to fix the display order
info.filename = [];
info.version = [];
info.partext = [];
info.loadopts = [];
info.pardef = [];
info.extdef = []; % extra information available in DICOM
info.imgdef = [];
info.dims = [];
info.dimnames = [];
info.table = [];
info.table_row_index_array = [];
info.n_dicom_imgs = [];
info.n_loaded_imgs = [];
info.n_data_imgs = [];
info.pixel_bits = [];
info.read_type = [];
info.img_pixels = [];
info.recon_x = [];
info.recon_y = [];
info.datasize = [];

%% Allow user to select a file if input FILENAME is not provided or is empty
if nargin<1 | length(filename)==0,
    [fn, pn] = uigetfile( ...
        {'*.DCM', 'DICOM files (*.DCM)', ...
         '*.*',   'All Files (*.*)'}, ...
         'Select a DICOM file');
    if fn~=0,
        filename = sprintf('%s%s',pn,fn);
    else
        disp('LOADDICOM cancelled');
        return;
    end
end
info.filename = filename;

%% Load Philips DICOM entries
philips = philipsDICOMentries;
pardef_names = fieldnames(philips.pardef);
imgdef_names = fieldnames(philips.imgdef);

%% parse load options
p = inputParser;
p.StructExpand = true;
p.CaseSensitive = true;
p.KeepUnmatched = true; % keep unmatched for now
p.addRequired('filename', @ischar);
p.addParamValue('version', [], @isnumeric);
p.addParamValue('info', [], @isstruct);
p.addParamValue('x', [], @isnumeric);
p.addParamValue('y', [], @isnumeric);
p.addParamValue('scale', 'FP', @ischar);
p.addParamValue('verbose', false, @islogical);
p.addParamValue('savememory', false, @islogical);
p.addParamValue('reducesingletons', true, @islogical);
p.addParamValue('waitbar', false, @islogical);
p.parse(filename, varargin{:});

if ~isempty(p.Results.info),
    info = p.Results.info; % use provided info
    
    % use info.dimnames to complete allowed parameter entries
    for k=1:length(info.dimnames),
        p.addParamValue(info.dimnames{k}, [], @isnumeric);
    end
    p.KeepUnmatched = false; % throw an error for unmatched inputs
    p.parse(filename, varargin{:}); % parse again
    
    tmp = rmfield(p.Results,'info'); % remove info from loadopts
    info.loadopts = rmfield(tmp,'filename'); % force use of new loadopts
else

% if version not specified, set it to the max of the par_min_version's
info.version = 0; 
if isempty(p.Results.version),
    for k=1:length(pardef_names),
        if ( (philips.pardef.(pardef_names{k}).par_min_version < Inf) & (philips.pardef.(pardef_names{k}).par_min_version > info.version) ),
            info.version = philips.pardef.(pardef_names{k}).par_min_version;
        end
    end
else
    info.version = p.Results.version; 
end

if ~ischar(info.version),
    tmp = info.version;
    if ceil(tmp - floor(tmp))==1,
        info.version = sprintf('%.1f',tmp);
    else
        info.version = sprintf('%.0f',tmp);
    end
end
par_version = str2num(info.version);

% with known PARREC version, determine info.dimnames
info.dimnames = {};
for k=1:length(imgdef_names),
    if isfield(philips.imgdef.(imgdef_names{k}),'image_key'),
        if( (philips.imgdef.(imgdef_names{k}).par_min_version <= par_version) & (philips.imgdef.(imgdef_names{k}).par_max_version >= par_version) ) 
        info.dimnames{end+1} = philips.imgdef.(imgdef_names{k}).image_key;
        end
    end
end

% use info.dimnames to complete allowed parameter entries
for k=1:length(info.dimnames),
    p.addParamValue(info.dimnames{k}, [], @isnumeric);
end
p.KeepUnmatched = false; % throw an error for unmatched inputs
p.parse(filename, varargin{:}); % parse again

%% Return loadopts structure inside INFO structure
% remove filename field - it is passed as the first required argument
info.loadopts = rmfield(p.Results,'filename');

%% Load DICOM header using custom DICOMINFOFAST
dicomheader = dicominfofast(filename,par_version);

%% Only enhanced MR DICOM is supported
if ~strcmp('1.2.840.10008.5.1.4.1.1.4.1',dicomheader.series.MediaStorageSOPClassUID),
    error('loadDICOM - Only enhanced MR DICOM is supported');
end

%% Convert DICOMHEADER structure to PARDEF portion of INFO structure
for k=1:length(pardef_names),
        pardef_name = pardef_names{k};
        group    = philips.pardef.(pardef_name).group;
        element  = philips.pardef.(pardef_name).element;
        dicom_sq = philips.pardef.(pardef_name).dicom_sq;

        tag_id   = dicomheader.tags.(dicom_sq).tag_ids(group+1,element+1);

        if ( (tag_id>0) & (par_version >= philips.pardef.(pardef_name).par_min_version) & (par_version <= philips.pardef.(pardef_name).par_max_version) ),
            tag_col  = dicomheader.tags.(dicom_sq).tag_cols(group+1,element+1);
            tag_name = dicomheader.tags.(dicom_sq).tag_names{tag_id};

            value = dicomheader.(dicom_sq).(tag_name);

            if isempty(value),
                if isfield(philips.pardef.(pardef_name),'default'),
                    value = philips.pardef.(pardef_name).default;
                end
            elseif isfield(philips.pardef.(pardef_name),'format_func'),
                format_func = philips.pardef.(pardef_name).format_func;
                eval( sprintf('%s;', format_func) );
                %disp( sprintf('%s;', format_func) );
            else
                % a single string store in a 1x1 cell
                value = value{1};
            end
            par_print = philips.pardef.(pardef_name).par_print;
        
            if isfield(philips.pardef.(pardef_name),'pardef_fieldname'),
                pardef_fieldname = philips.pardef.(pardef_name).pardef_fieldname;
                info.pardef.(pardef_fieldname) = sprintf(par_print,value);
            else % extra definitions
                extdef_fieldname = pardef_name;
                info.extdef.(extdef_fieldname) = sprintf(par_print,value);
            end
        
        end
        
end

%% Convert DICOMHEADER structure to IMGDEF portion of INFO structure
info.ndims = length(info.dimnames);
info.n_dicom_imgs = str2num(info.extdef.NumberOfFrames);

% determine number of columns in the table
n_table_cols = 0;
count_imgdef_fieldnames = 0;
imgdef_philips_names = {};
imgdef_fieldnames = {};
for k=1:length(imgdef_names),
    imgdef_name = imgdef_names{k};
    if ( (par_version >= philips.imgdef.(imgdef_name).par_min_version) & (par_version <= philips.imgdef.(imgdef_name).par_max_version) ),
        if isfield(philips.imgdef.(imgdef_name),'imgdef_size'),
            n_table_cols = n_table_cols + philips.imgdef.(imgdef_name).imgdef_size;
            count_imgdef_fieldnames = count_imgdef_fieldnames + 1;
            imgdef_philips_names{count_imgdef_fieldnames} = imgdef_name;
            imgdef_fieldnames{count_imgdef_fieldnames} = philips.imgdef.(imgdef_name).imgdef_fieldname;
        end
    end
end
info.table = NaN(info.n_dicom_imgs,n_table_cols);

% fill in table
start_col = 0;
stop_col = 0;
for k=1:count_imgdef_fieldnames,
    
    imgdef_philips_name = imgdef_philips_names{k};
    imgdef_fieldname = imgdef_fieldnames{k};
    
    start_col = stop_col + 1;
    stop_col  = stop_col + philips.imgdef.(imgdef_philips_name).imgdef_size;           
    
    info.imgdef.(imgdef_fieldname).size = philips.imgdef.(imgdef_philips_name).imgdef_size;

    group    = philips.imgdef.(imgdef_philips_name).group;
    element  = philips.imgdef.(imgdef_philips_name).element;
    dicom_sq = philips.imgdef.(imgdef_philips_name).dicom_sq;

    tag_id   = dicomheader.tags.(dicom_sq).tag_ids(group+1,element+1);
    tag_col  = dicomheader.tags.(dicom_sq).tag_cols(group+1,element+1);
    tag_name = dicomheader.tags.(dicom_sq).tag_names{tag_id};

    vals = NaN(info.n_dicom_imgs, info.imgdef.(imgdef_fieldname).size);
    
    for v=1:info.n_dicom_imgs,
        
        frame_id = v;
        stack_id = str2num( dicomheader.frame(v).StackID{1} );
        series_id = 1;
        
        switch dicom_sq,
            case 'series',
                dicom_sq_id = series_id;
            case 'stack',
                dicom_sq_id = stack_id;
            case 'frame'
                dicom_sq_id = frame_id;
        end
        
        if ~isempty( dicomheader.(dicom_sq)(dicom_sq_id).(tag_name) ),
            
            value = [dicomheader.(dicom_sq)(dicom_sq_id).(tag_name){:}];

            if iscell(value),

                cell_value = value;
                n_cells = length(cell_value);
                num_value = NaN(1,n_cells);

                for c=1:n_cells,
                    value = cell_value{c};
                    if isfield(philips.imgdef.(imgdef_philips_name),'enum'),
                        value = enum_value(value,philips.imgdef.(imgdef_philips_name).enum);
                        if isnan(value),
                            if isfield(philips.imgdef.(imgdef_philips_name),'default'),
                                value = philips.imgdef.(imgdef_philips_name).default;
                                if (v==1), disp( sprintf('defaulting %s (unknown enum value)',imgdef_philips_name)); end
                            end
                        end
                    elseif isfield(philips.imgdef.(imgdef_philips_name),'format_func'),
                        format_func = philips.imgdef.(imgdef_philips_name).format_func;
                        eval( sprintf('%s;', format_func) );
                        %disp( sprintf('%s;', format_func) );
                    elseif ischar(value),
                        value = str2num(value);
                    end
                    num_value(c) = value;
                end
                vals(v,:) = num_value;

            else

                if isfield(philips.imgdef.(imgdef_philips_name),'enum'),
                    value = enum_value(value,philips.imgdef.(imgdef_philips_name).enum);
                    if isnan(value),
                        if isfield(philips.imgdef.(imgdef_philips_name),'default'),
                            value = philips.imgdef.(imgdef_philips_name).default;
                            if (v==1), disp( sprintf('defaulting %s (unknown enum value)',imgdef_philips_name)); end
                        end
                    end
                elseif isfield(philips.imgdef.(imgdef_philips_name),'format_func'),
                    format_func = philips.imgdef.(imgdef_philips_name).format_func;
                    eval( sprintf('%s;', format_func) );
                    %disp( sprintf('%s;', format_func) );
                elseif ischar(value),
                    value = str2num(value);
                end
                vals(v,:) = value;

            end
        else
            value = NaN;
            if (v==1), disp( sprintf('defaulting %s (empty)',imgdef_philips_name)); end
            if isfield(philips.imgdef.(imgdef_philips_name),'default'),
                value = philips.imgdef.(imgdef_philips_name).default;
            end
            vals(v,:) = value;
        end       
    end

    %% set NaN to zero
    idx = find(isnan(vals(:)));
    vals(idx) = 0;    
    
    info.table(:,start_col:stop_col) = vals;
    info.imgdef.(imgdef_fieldname).vals = vals;
    info.imgdef.(imgdef_fieldname).uniq = unique(vals,'rows');
    info.imgdef.(imgdef_fieldname).cols = [start_col:stop_col];
    
    % if size is one, store unique values as row vector for easier display at prompt
    if info.imgdef.(imgdef_fieldname).size==1,
        %info.imgdef.(imgdef_fieldname).vals = (info.imgdef.(imgdef_fieldname).vals(:)).';
        info.imgdef.(imgdef_fieldname).uniq = (info.imgdef.(imgdef_fieldname).uniq(:)).';
    end
    
end



%% Correct image offcenters

% This element is used in IAP, and probably should be exported later
% in DICOM. But at the moment Image Position and Image Orientation 
% are completely covered by Image Offcentres and Image Angulations 
% img off = img pos + (cols*rps*rori + rows*cps*cori)/2 where: 
% img off = Image Offcentres
% LPH img pos = Image Position LPH (0020, 0032)
% rows = Rows (0028, 0011)
% cols = Columns (0028, 0010)
% rps cps = Pixel Spacing in row col direction (0028, 0030) 
% rori cori = Image Orientation in row, col direction (0028,0037)
rows = ones(info.n_dicom_imgs,1);
cols = ones(info.n_dicom_imgs,1);
switch info.version,
    case '3',
        rows = info.pardef.Recon_resolution_x_y(1) * rows; 
        cols = info.pardef.Recon_resolution_x_y(2) * cols; 
    case {'4','4.1','4.2'},
        rows = info.imgdef.recon_resolution_x_y.vals(:,1);
        cols = info.imgdef.recon_resolution_x_y.vals(:,2);
end

rps = info.imgdef.pixel_spacing_x_y.vals(:,1);
cps = info.imgdef.pixel_spacing_x_y.vals(:,2);

img_pos = info.imgdef.image_offcentre_ap_fh_rl_in_mm.vals;

img_off = zeros(info.n_dicom_imgs,3);
for k=1:info.n_dicom_imgs,
    img_ori = str2num( strrep( dicomheader.frame(k).ImageOrientationPatient{1}, '\', ' ') );
    rori = img_ori(1:3);
    cori = img_ori(4:6);
    img_off(k,:) = img_pos(k,:) + (cols(k)*rps(k)*rori + rows(k)*cps(k)*cori)/2;
end
info.imgdef.image_offcentre_ap_fh_rl_in_mm.vals = img_off(:,[2 3 1]); % rearrange order
info.imgdef.image_offcentre_ap_fh_rl_in_mm.uniq = unique(img_off,'rows');

%% Return if there are no images
if info.n_dicom_imgs==0,
    return
end

%% pixel_data_offset_bytes
info.pixel_data_offset_bytes = dicomheader.pixel_data_offset_bytes;

end % end load INFO section

%% Set dimension names and important columns based on version number
switch info.version,
    case '3',
        info.dimnames = {'sl','ec','dyn','ph','ty','seq'};
        dimcols = [1 2 3 4 5 6];
        ri_col = 8;
        rs_col = 9;
        ss_col = 10;
        rec_index_col = 7;
    case '4',
        info.dimnames = {'sl','ec','dyn','ph','ty','seq'};
        dimcols = [1 2 3 4 5 6];
        ri_col = 12;
        rs_col = 13;
        ss_col = 14;
        rec_index_col = 7;
        pixel_bits_col = 8;
    case '4.1',
        info.dimnames = {'sl','ec','dyn','ph','ty','seq','b','grad'};
        dimcols = [1 2 3 4 5 6 42 43];
        ri_col = 12;
        rs_col = 13;
        ss_col = 14;
        rec_index_col = 7;
        pixel_bits_col = 8;
    case '4.2',
        info.dimnames = {'sl','ec','dyn','ph','ty','seq','b','grad','asl'};
        dimcols = [1 2 3 4 5 6 42 43 49];
        ri_col = 12;
        rs_col = 13;
        ss_col = 14;        
        rec_index_col = 7;
        pixel_bits_col = 8;
    otherwise,
        disp( sprintf('Unknown version : %s', info.version) );
end

%% Bits per pixel information and file read type
if isfield(info.pardef,'Image_pixel_size'),
    info.pixel_bits = str2num(info.pardef.Image_pixel_size);
else
    info.pixel_bits = info.table(1,pixel_bits_col);
end

% read type 
switch (info.pixel_bits)
    case { 8 }, info.read_type = 'int8';
    case { 16 }, info.read_type = 'int16';
    otherwise, info.read_type = 'uchar';
end

%% Set dimension information

% assumes (x,y) recon size the same for all images
if isfield(info.pardef,'Recon_resolution_x_y'),
    Recon_resolution = str2num(info.pardef.Recon_resolution_x_y);
    info.img_pixels = prod(Recon_resolution);
    info.recon_x = Recon_resolution(1);
    info.recon_y = Recon_resolution(2);
    info.dims.x = [1:Recon_resolution(1)];
    info.dims.y = [1:Recon_resolution(2)];
else
    info.img_pixels = prod(info.imgdef.recon_resolution_x_y.uniq);
    info.recon_x = info.imgdef.recon_resolution_x_y.uniq(1);
    info.recon_y = info.imgdef.recon_resolution_x_y.uniq(2);
    info.dims.x = [1:info.imgdef.recon_resolution_x_y.uniq(1)]; 
    info.dims.y = [1:info.imgdef.recon_resolution_x_y.uniq(2)];
end

%% Find the unique set of values for each dimension name
for k=1:length(info.dimnames),
    info.dims.(info.dimnames{k}) = unique(info.table(:,dimcols(k))).';
end

%% Find intersection of available dimensions with LOADOPTS dimensions
if ~isempty(info.loadopts.x),
    info.dims.x = intersect_a_with_b(info.loadopts.x,info.dims.x);
end
if ~isempty(info.loadopts.y),
    info.dims.y = intersect_a_with_b(info.loadopts.y,info.dims.y);
end
for k=1:length(info.dimnames),
    if ~isempty(info.loadopts.(info.dimnames{k})),
        info.dims.(info.dimnames{k}) = intersect_a_with_b(info.loadopts.(info.dimnames{k}),info.dims.(info.dimnames{k}));
    end
end

%% Calculate data size
datasize = [length(info.dims.x) length(info.dims.y)]; 
for k=1:length(info.dimnames),
    datasize = [datasize length(info.dims.(info.dimnames{k}))];
end
info.datasize = datasize;

% throw error if any dimension size is zero
if any(info.datasize==0),
    all_info.dimnames = {'x', 'y', info.dimnames{:} };
    zero_length_str = sprintf(' ''%s'' ', all_info.dimnames{find(info.datasize==0)});
    error('size of selected data to load has zero length along dimension(s): %s', zero_length_str);
end

%% Skip data loading if only one output argument is provided, return INFO
if nargout==1,
    data=info;
    return;
end

%% Create array to hold image definition table rows numbers for loaded data
% skip the (x,y) dimensions
info.table_row_index_array = zeros(datasize(3:end));

%% Pre-allocate DATA array
if info.loadopts.savememory==true,
    data = zeros(info.datasize,'single');
else
    data = zeros(info.datasize);
end

%% Read REC data for selected dimension ranges
fid = fopen(info.filename,'r','l');
if fid<0,
    error(sprintf('cannot open DICOM file: %s', info.filename));
end
info.n_loaded_imgs=0;
for n=1:info.n_dicom_imgs,
    
    load_flag=1;
    dim_assign_indices_full_array = [];
    rec_index = info.table(n,rec_index_col);
    
    for k=1:length(info.dimnames),
        
        dimval = info.table(n,dimcols(k));
        
        % it is allowed that the dimval appears more than once 
        % in the requested dimension ranges to be loaded
        dim_assign_indices = find(dimval==info.dims.(info.dimnames{k}));
        
        if isempty(dim_assign_indices),
            load_flag=0;
            break;
        else
           
            if k>1,
                
                dim_assign_indices_full_array_new = zeros( size(dim_assign_indices_full_array,1)*length(dim_assign_indices), size(dim_assign_indices_full_array,2)+1);
                
                mod_base_a = size(dim_assign_indices_full_array,1);
                mod_base_b = length(dim_assign_indices);
                
                for d=1:size(dim_assign_indices_full_array_new,1),
                    dim_assign_indices_full_array_new(d,:) = [dim_assign_indices_full_array(mod(d,mod_base_a)+1,:) dim_assign_indices(mod(d,mod_base_b)+1)];
                end
                
            else
                dim_assign_indices_full_array_new = dim_assign_indices(:);
            end
            
            dim_assign_indices_full_array = dim_assign_indices_full_array_new;
            
        end
    end
    
    if load_flag,
        
        info.n_loaded_imgs = info.n_loaded_imgs+1;
        
        byte_offset = rec_index*info.img_pixels*(info.pixel_bits/8) + info.pixel_data_offset_bytes;
        status = fseek(fid, byte_offset, 'bof');
        data_1d = fread(fid, info.img_pixels, info.read_type);
        tmpimg = reshape(data_1d,[info.recon_x info.recon_y]);
        
        % transpose image
        tmpimg = tmpimg.';
        
        % select choosen x
        tmpimg = tmpimg(info.dims.x,:);
        
        % select choosen y
        tmpimg = tmpimg(:,info.dims.y);
        
        % insert image into proper locations of the data array
        for d=1:size(dim_assign_indices_full_array,1),
            
            dim_assign_str = sprintf(',%d', dim_assign_indices_full_array(d,:) );
            
            % delete initial comma
            dim_assign_str(1) = [];
            
            % assign index to table_index table
            eval( sprintf('info.table_row_index_array(%s)=%d;', dim_assign_str, n) );
        
            % assign read image to correct location in data array
            eval( sprintf('data(:,:,%s)=tmpimg;', dim_assign_str) );
        
        end
    
    end
    
end
fclose(fid);

%% Apply image scaling by using info.imgdef.table_index & info.imgdef.table
size_data = size(data);
max_img_dims = size_data(3:end);
info.n_data_imgs = prod(max_img_dims);

% temporarily reshape data to a continuous stack of images
data = reshape(data,[size_data(1) size_data(2) info.n_data_imgs]);

% loop through all image dimensions
for k=1:info.n_data_imgs,

    % find the table_row_index that is associated with this image
    table_row_index = info.table_row_index_array(k);
   
    if(table_row_index>0),
        
        % rescale intercept
        ri = info.table(table_row_index,ri_col);

        % rescale slope
        rs = info.table(table_row_index,rs_col);

        % scale slope
        ss = info.table(table_row_index,ss_col);

        switch info.loadopts.scale
            case 'FP',
                data(:,:,k) = (data(:,:,k) * rs + ri)/(rs * ss);
            case 'DV',
                data(:,:,k) = data(:,:,k) * rs + ri;
            case 'PV',
                % do nothing
                % values are already the pixel value stored in the REC file
            otherwise,
                if(k==1),
                    warning( sprintf('Unkown scale type option : ''%s''.  Will return floating point (''FP'') instead',info.loadopts.scale) );
                end
                data(:,:,k) = (data(:,:,k) * rs + ri)/(rs * ss);
        end
        
    end
    
end

%% Reshape data to original dimensions
data = reshape(data,size_data);

%% Check for singleton dimensions to reduce them to size 1
% may occur when a user specifies a range on a certain dimension and other
% dimensions are kept which do not have data, e.g. diffusion data, B0/B1
% mapping data, other image types, etc.
ndims = length(info.dimnames);
last_nonempty_idx = zeros(1,ndims);
if info.loadopts.reducesingletons==true,
    for k=1:ndims,
        
        % only check dimensions with length greater than 1
        if length(info.dims.(info.dimnames{k}))>1,
            nonempty_count=0;

            % template string for indexing the table_row_index_array
            dimstr = [ repmat(':,',1,k-1) '_,'  repmat(':,',1,ndims-k)];
            dimstr(end)=[];

            for n=1:length(info.dims.(info.dimnames{k})),
                dimstr_n = strrep(dimstr,'_',num2str(n));
                eval(sprintf('tmp = info.table_row_index_array(%s);', dimstr_n) );

                if max(tmp(:))>0,
                    nonempty_count=nonempty_count+1;
                    last_nonempty_idx(k) = n;
                end

                % if nonempty_count is greater than one already, 
                % it is not a singleton dimension
                if nonempty_count>1,
                    break;
                end
            end

            if nonempty_count==1 & info.loadopts.verbose==true,
                disp( sprintf('Found a singleton dimension to reduce along dimension - %s', info.dimnames{k}) );
            else
                % not a singleton, reset las_nonempty_idx(k) to default value
                last_nonempty_idx(k) = 0;
            end
            
        end
        
    end
    
    % eliminate singleton dimension(s)
    for k=1:length(last_nonempty_idx),
        if last_nonempty_idx(k)~=0,
            dimstr = [ repmat(':,',1,k-1) '_,'  repmat(':,',1,ndims-k)];
            dimstr(end)=[];
            dimstr_n = strrep(dimstr,'_',num2str(last_nonempty_idx(k)));
            eval(sprintf('info.table_row_index_array = info.table_row_index_array(%s);', dimstr_n) );
            eval(sprintf('data = data(:,:,%s);', dimstr_n) );
            info.datasize = size(data);
            dimold = info.dims.(info.dimnames{k});
            info.dims.(info.dimnames{k}) = dimold( last_nonempty_idx(k) );
            info.n_data_imgs = prod(info.datasize(3:end));
        end
    end
    
end

%% If VERBOSE, display execution information
if info.loadopts.verbose==true,
    disp( sprintf('DICOM loaded as a V%s PARREC file', info.version) );
    disp( sprintf('Loaded images are in ''%s'' scale', info.loadopts.scale) );
    disp( sprintf('Loaded %d of %d available images of original size [%d x %d]', info.n_loaded_imgs, info.n_dicom_imgs, info.recon_x, info.recon_y) );
    tmpstr = '';
    for k=1:length(info.dimnames),
        tmpstr = sprintf('%s, # %s: %d', tmpstr, info.dimnames{k}, length(info.dims.(info.dimnames{k})) );
    end
    disp( sprintf('Data contains %d images - %s', info.n_data_imgs, tmpstr(3:end)) );
    disp( sprintf('Total execution time = %.3f seconds', toc) );
end

%% Internal Functions
    function format_date_time,
        % 2005.01.12 / 10:32:51
        date_str = value{1};
        time_str = value{2};
        value = [date_str(1:4) '.' date_str(5:6) '.' date_str(7:8) ' / ' time_str(1:2) ':' time_str(3:4) ':' time_str(5:6)];
    end

    function format_series_type,
        value = value{1};
    end

    function format_patient_position,
        switch value{1},
            case 'HFS',
                value = 'Head First Supine';
            case 'FFS',
                value = 'Feet First Supine';
            case 'HFP',
                value = 'Head First Prone';
            case 'FFP',
                value = 'Feet First Prone';
            otherwise,
                value = value{1};
        end
    end

    function format_preparation_direction,
        switch value{1},
            case 'AP',
                value = 'Anterior-Posterior';
            case 'RL',
                value = 'Right-Left';
            case 'FH',
                value = 'Foot-Head';
            otherwise,
                value = value{1};
        end
    end

    function format_acquisition_matrix,
        value = value{1};
        value = value(2:3);
    end

    function format_str2num,
        tmp = value;
        value = [];
        for k=1:length(tmp),
            value(k) = str2num(tmp{k});
        end
    end

    function format_recon_resolution,
        value = [value{1} value{2}];
    end

    function format_repetition_time,
        value = value{1};
        if length(value==1),
            value = num2str(value);
        else % multiple TR's specified, e.g. B1 map
            tmpstr = '';
            for ii=1:length(value),
                tmpstr = sprintf('%s/%s',num2str(value(ii)) );
            end
            value = tmpstr(2:end);
        end
    end

    function format_cell2num,
        value = [value{:}];
    end

    function format_boolean,
        switch value{1},
            case {'N','NO','n','no','No'},
                value = 0;
            otherwise,
                value = 1;
        end
    end

    function format_index_in_REC_file,
        value = str2num(value) - 1;
    end

    function format_slashed_to_num,
        value = str2num(strrep(value,'\',' '));
    end

    function format_slice_gap,
        value = str2num(value); % this is the center-to-center distance
        slice_thickness = 0;
        switch info.version,
            case '3',
                slice_thickness = info.pardef.Slice_gap_mm;
            case {'4','4.1','4.2'},
                slice_thickness = info.table(v,start_col-1);
        end
        value = value - slice_thickness; % subtract slice thickness
    end

    function format_stack_view_axis_to_slice_orientation,
        % {'UNDEFINED','TRANSVERSAL','SAGITTAL','CORONAL'}
        switch value,
            case 'FH', % transversal
                value = 1;
            case 'RL', % sagittal
                value = 2;
            case 'AP', % coronal
                value = 3;
            otherwise, % unknown
                value = 0;
        end        
    end

    function format_str2str,
        value = sprintf('%s',value{1});
    end

    function format_resonant_frequency,
        value = value{1}*1e6; % MHz to Hz
    end

%% end of parent function
end

%% FUNCTION intersect_a_with_b : Find intersection of vector a with vector b without sorting 
function c = intersect_a_with_b(a,b)
    c = a;
    % work backwards in order to use [] assignment
    for k=length(a):-1:1,
        if length(find(a(k)==b))==0,
            c(k)=[]; 
        end
    end

    % force c to be a row vector for easier display
    c = c(:).';
end

%% FUNCTION enum_value : convert enumeration string values to integer
function n = enum_value(value_str,enum)
    n=NaN; % default to NaN
    for k=1:length(enum),
        if strcmp(deblank(value_str),enum{k}),
            n=k-1;
            break;
        end
    end
end

%% FUNCTION dicominfofast : parse DICOM header
function dicomheader = dicominfofast(filename,parrec_version)

%% Open the file.
fid = fopen(filename, 'r');
if (fid < 0)
  error( sprintf('Cannot open file "%s" for reading.', filename) );
end

%% Initialize DICOMHEADER structure
% Serves to fix the display order
dicomheader.parrec_version = [];
dicomheader.series = [];
dicomheader.stack = [];
dicomheader.frame = [];
dicomheader.stack_cnt = [];
dicomheader.frame_cnt = [];
dicomheader.tags = [];
dicomheader.pixel_data_offset_bytes = [];
dicomheader.pixel_data_length_bytes = [];

%% Initialize DICOM file metadata header entries
dicomheader.series.TransferSyntaxUID = [];
dicomheader.series.MediaStorageSOPClassUID = [];

%% Load PHILIPS DICOM details
philips = philipsDICOMentries;
pardef_fieldnames = fieldnames(philips.pardef);
imgdef_fieldnames = fieldnames(philips.imgdef);

%% set parrec_version
if nargin==1,
    dicomheader.parrec_version = 0;
    for k=1:length(pardef_fieldnames),
        if ( (philips.pardef.(pardef_fieldnames{k}).par_min_version < Inf) & (philips.pardef.(pardef_fieldnames{k}).par_min_version > dicomheader.parrec_version) ),
            dicomheader.parrec_version = philips.pardef.(pardef_fieldnames{k}).par_min_version;
        end
    end
else
    dicomheader.parrec_version = parrec_version;
end

%% Create series, stack and frame level structures
dicomheader.tags.series.tag_ids = sparse(65536,65536);
dicomheader.tags.stack.tag_ids  = sparse(65536,65536);
dicomheader.tags.frame.tag_ids  = sparse(65536,65536);

dicomheader.tags.series.tag_cols = sparse(65536,65536);
dicomheader.tags.stack.tag_cols  = sparse(65536,65536);
dicomheader.tags.frame.tag_cols  = sparse(65536,65536);

dicomheader.tags.series.tag_cnt = 0;
dicomheader.tags.stack.tag_cnt = 0;
dicomheader.tags.frame.tag_cnt = 0;

dicomheader.tags.series.tag_names = {};
dicomheader.tags.stack.tag_names = {};
dicomheader.tags.frame.tag_names = {};

%% parameter definitions
for k=1:length(pardef_fieldnames),

    if ( (philips.pardef.(pardef_fieldnames{k}).par_min_version <= dicomheader.parrec_version) & (philips.pardef.(pardef_fieldnames{k}).par_max_version >= dicomheader.parrec_version) ),
        
        group = philips.pardef.(pardef_fieldnames{k}).group;
        dicom_sq = philips.pardef.(pardef_fieldnames{k}).dicom_sq;
        for n = 1:length(philips.pardef.(pardef_fieldnames{k}).element),
            element = philips.pardef.(pardef_fieldnames{k}).element(n);
            dicomheader.(dicom_sq).(pardef_fieldnames{k}) = [];
            dicomheader.tags.(dicom_sq).tag_cnt = dicomheader.tags.(dicom_sq).tag_cnt + 1;
            dicomheader.tags.(dicom_sq).tag_ids(group+1,element+1) = dicomheader.tags.(dicom_sq).tag_cnt;
            dicomheader.tags.(dicom_sq).tag_cols(group+1,element+1) = n;
            dicomheader.tags.(dicom_sq).tag_names{ dicomheader.tags.(dicom_sq).tag_cnt } = pardef_fieldnames{k};
        end

    end

end

%% image definitions
for k=1:length(imgdef_fieldnames),
    
    if ( (philips.imgdef.(imgdef_fieldnames{k}).par_min_version <= dicomheader.parrec_version) & (philips.imgdef.(imgdef_fieldnames{k}).par_max_version >= dicomheader.parrec_version) ),
    
        group = philips.imgdef.(imgdef_fieldnames{k}).group;
        dicom_sq = philips.imgdef.(imgdef_fieldnames{k}).dicom_sq;
        for n = 1:length(philips.imgdef.(imgdef_fieldnames{k}).element),
            element = philips.imgdef.(imgdef_fieldnames{k}).element(n);
            dicomheader.(dicom_sq).(imgdef_fieldnames{k}) = [];
            dicomheader.tags.(dicom_sq).tag_cnt = dicomheader.tags.(dicom_sq).tag_cnt + 1;
            dicomheader.tags.(dicom_sq).tag_ids(group+1,element+1) = dicomheader.tags.(dicom_sq).tag_cnt;
            dicomheader.tags.(dicom_sq).tag_cols(group+1,element+1) = n;
            dicomheader.tags.(dicom_sq).tag_names{ dicomheader.tags.(dicom_sq).tag_cnt } = imgdef_fieldnames{k};
        end
    
    end
    
end

%% Get the possible DICOM header and inspect it for DICOM-like data.
header = fread(fid, 132, 'uint8');
if ~( ( numel(header)==132 ) && ( sum(header(1:128))==0 ) && isequal(char(header(129:132))','DICM') )
    % It's not a proper DICOM file.
    data_details = [];
    fclose(fid);
    return;
end

%% Read file meta data
file_endian = 'ieee-le';
group   = fread(fid, 1, 'uint16', file_endian);
element = fread(fid, 1, 'uint16', file_endian);
VR      = fread(fid, 2, 'uint8=>char', file_endian);
VL      = fread(fid, 1, 'uint16', file_endian);
GL0002  = fread(fid, 1, 'uint32', file_endian); 

%% Precalculate group and element values
g0002 = hex2dec('0002'); e0010 = hex2dec('0010'); % TransferSyntaxUID
g0002 = hex2dec('0002'); e0002 = hex2dec('0002'); % MediaStorageSOPClassUID
g7FE0 = hex2dec('7FE0'); e0010 = hex2dec('0010');
gFFFE = hex2dec('FFFE'); eE000 = hex2dec('E000');
gFFFE = hex2dec('FFFE'); eE00D = hex2dec('E00D');
gFFFE = hex2dec('FFFE'); eE0DD = hex2dec('E0DD');

% Stack SQ, begin stack section, section_current = section_stack
g2001 = hex2dec('2001'); e105F = hex2dec('105F'); 
% "item begin tag" at SQ_depth = 1 increments
% "end of SQ tag" at SQ_depth = 1 sets section_current = section_series

% PerFrameFunctionalGroupsSequence, begins frame section, section_current = section_frame
g5200 = hex2dec('5200'); e9230 = hex2dec('9230');
% "item begin tag" at SQ_depth = 1 increments
% "end of SQ tag" at SQ_depth = 1 sets section_current = section_series

%% VR names groups
VR_names_with_int32_VL = { ('OB')' ('OW')' ('SQ')' ('UN')' };
VR_names_char    = {('AE')' ('AS')' ('CS')' ('DA')' ('DS')' ('DT')' ('IS')' ('LO')' ('LT')' ('PN')' ('SH')' ('ST')' ('TM')' ('UI')' ('UT')' };
VR_names_uint8   = { ('OB')' };
VR_names_uint16  = { ('AT')' ('OW')' ('US')' };
VR_names_int16   = { ('SS')' };
VR_names_uint32  = { ('UL')' };            
VR_names_int32   = { ('SL')' };
VR_names_float32 = { ('FL')' ('OF')' };
VR_names_float64 = { ('FD')' };
VR_names_unknown = { ('UN')' ('SQ')' };

%% Read file meta data
read_count = 132 + 2 + 2 + 2 + 2 + 4;
while read_count < (GL0002 + 144),
    group   = fread(fid, 1, 'uint16', file_endian);
    element = fread(fid, 1, 'uint16', file_endian);
    VR      = fread(fid, 2, 'uint8=>char', file_endian);
    read_count = read_count + 6;
    
    switch VR,
        case VR_names_with_int32_VL,
            dummy = fread(fid, 2, 'uint8', file_endian);
            VL = fread(fid, 1, 'int32', file_endian);
            read_count = read_count + 6;    
        otherwise,
            VL = fread(fid, 1, 'int16', file_endian);
            read_count = read_count + 2;
    end
    value = fread(fid, VL, 'uint8', file_endian);
    read_count = read_count + VL;
    
    if group==g0002 && element==e0010,
        dicomheader.series.TransferSyntaxUID = char(value(1:(VL-1))');
    end
    
    if group==g0002 && element==e0002,
        dicomheader.series.MediaStorageSOPClassUID = char(value(1:(VL-1))');
    end
end

%% Set file endian
switch dicomheader.series.TransferSyntaxUID,
    case '1.2.840.10008.1.2.1',
        file_endian = 'ieee-le';
    case '1.2.840.10008.1.2.2',
        file_endian = 'ieee-be';
    otherwise,
        fclose(fid);
        error( sprintf('Unsupported transfer syntax : %s', transfer_syntax) );
end

%%  Section identifiers
section_series = 1;
section_stack  = 2;
section_frame  = 3;
section_current = section_series;

%% Section counters
dicomheader.stack_cnt = 0;
dicomheader.frame_cnt = 0;
SQ_depth = 0;

%if info.loadopts.waitbar,
    hwaitbar = waitbar(0,'Parsing DICOM header ...');
%end

%% Iterative read buffer
while true,
    
    [group_element, count] = fread(fid, 2, 'uint16', file_endian); 
    group   = group_element(1);
    element = group_element(2);
    VR      = fread(fid, 2, 'uint8=>char', file_endian);
    read_count = read_count + 6;

    if VR(1)=='S' && VR(2)=='Q',
        SQ_depth = SQ_depth + 1;
    end
    
    if count<2,
        
        fclose(fid);
        error('reached end of the file');
  
    elseif group==g7FE0 && element==e0010,
        
        dummy = fread(fid, 2, 'uint8', file_endian);
        VL = fread(fid, 1, 'int32', file_endian);
        read_count = read_count + 6;
        
        dicomheader.pixel_data_offset_bytes = read_count;        
        dicomheader.pixel_data_length_bytes = VL;
        break;
 
    elseif group==gFFFE,
        
        switch element,
            case eE000, % item begin
                VL = fread(fid, 1, 'int16', file_endian);
                read_count = read_count + 2;      

                if SQ_depth==1,
                    if section_current==section_frame,
                        dicomheader.frame_cnt = dicomheader.frame_cnt + 1;
                        % pre-allocate frames
                        if dicomheader.frame_cnt==2,
                            nframes = str2num(dicomheader.series.NumberOfFrames{1});
                            dicomheader.frame(2:nframes) = dicomheader.frame(1);
                        end
                        
                        if mod(dicomheader.frame_cnt,25)==0,
                            %if info.loadopts.waitbar,
                                waitbar(dicomheader.frame_cnt/nframes, hwaitbar, sprintf('Parsing DICOM header ... frames %5d of %5d', dicomheader.frame_cnt, nframes) );
                            %end
                        end
                        
                    elseif section_current==section_stack,
                        dicomheader.stack_cnt = dicomheader.stack_cnt + 1;
                    end
                end
                
            case eE00D, % item end
                VL = fread(fid, 1, 'int16', file_endian);
                read_count = read_count + 2;
                
            case eE0DD, % end of SQ              
                VL = fread(fid, 1, 'int16', file_endian);
                read_count = read_count + 2;
                
                SQ_depth = SQ_depth - 1;
                
                if SQ_depth==0,
                    section_current = section_series;
                end
        end
        
    else
    
        if group==g2001 && element==e105F, % Stack
            section_current = section_stack;
        end
                
        if group==g5200 && element==e9230, % PerFrameFunctionalGroupsSequence
            section_current = section_frame;
        end
        
        switch VR,
            case VR_names_with_int32_VL,
                dummy = fread(fid, 2, 'uint8', file_endian);
                VL = fread(fid, 1, 'int32', file_endian);
                read_count = read_count + 6;    
            otherwise,
                VL = fread(fid, 1, 'int16', file_endian);
                read_count = read_count + 2;
        end

        if VL>0,
            
            switch VR,
                case VR_names_char,
                    value = strtrim( fread(fid, VL, 'uint8=>char', file_endian)' );
                case VR_names_uint8,
                    value = fread(fid, VL, 'uint8', file_endian)';
                case VR_names_uint16,
                    value = fread(fid, VL/2, 'uint16', file_endian)';
                case VR_names_int16,
                    value = fread(fid, VL/2, 'int16', file_endian)';
                case VR_names_uint32,
                    value = fread(fid, VL/4, 'uint32', file_endian)';                   
                case VR_names_int32,
                    value = fread(fid, VL/4, 'int32', file_endian)';
                case VR_names_float32
                    value = fread(fid, VL/4, 'float32', file_endian)';
                case VR_names_float64
                    value = fread(fid, VL/8, 'float64', file_endian)';
                otherwise % VR_names_unknown
                    value = fread(fid, VL, 'uint8', file_endian)';                   
            end
            read_count = read_count + VL;
            
            switch section_current,
                case section_series,
                    tag_id  = dicomheader.tags.series.tag_ids(group+1,element+1);
                    tag_col = dicomheader.tags.series.tag_cols(group+1,element+1);
                    if tag_id>0,
                        tag_name = dicomheader.tags.series.tag_names{tag_id};
                        dicomheader.series.(tag_name){tag_col} = value;
                    end                  
                case section_stack,
                    tag_id  = dicomheader.tags.stack.tag_ids(group+1,element+1);
                    tag_col = dicomheader.tags.stack.tag_cols(group+1,element+1);
                    if tag_id>0,
                        tag_name = dicomheader.tags.stack.tag_names{tag_id};
                        dicomheader.stack(dicomheader.stack_cnt).(tag_name){tag_col} = value;
                    end
                case section_frame,
                    tag_id  = dicomheader.tags.frame.tag_ids(group+1,element+1);
                    tag_col = dicomheader.tags.frame.tag_cols(group+1,element+1);
                    if tag_id>0,
                        tag_name = dicomheader.tags.frame.tag_names{tag_id};
                        dicomheader.frame(dicomheader.frame_cnt).(tag_name){tag_col} = value;
                    end    
            end
                        
        end
        
    end
end
%if info.loadopts.waitbar,
    close(hwaitbar);
%end
fclose(fid);

end


%% PHILIPSDICOMENTRIES     Return a structure of information for Philips DICOM entries
%
% [PHILIPS] = PHILIPSDICOMENTRIES
%
%   PHILIPS is a structure containing definitions for the PARDEF and IMGDEF
%   portions of a Philips PAR header file including the information for the
%   associated DICOM entries in an enhanced MR DICOM.  Many of the
%   necessary entries are private.
%

%% Revision History
% * 2008.05.01    initial version - welcheb
% * 2008.05.16    cleaned up and commented - welcheb

%% Function definition
function philips = philipsDICOMentries

%% Philips PAR definition DICOM entries
% Order of declaration below reflects the order in the Philips PAR header file

% 01
philips.pardef.PatientID.par_definition  = '.    Patient name                       :   ';
philips.pardef.PatientID.par_print       = '%s';
philips.pardef.PatientID.par_min_version = 3;
philips.pardef.PatientID.par_max_version = Inf;
philips.pardef.PatientID.group           = hex2dec('0010');
philips.pardef.PatientID.element         = hex2dec('0020');
philips.pardef.PatientID.type            = 'STRING';
philips.pardef.PatientID.dicom_sq        = 'series'; 
philips.pardef.PatientID.default         = 'UNKNOWN';

% 02
philips.pardef.StudyDescription.par_definition  = '.    Examination name                   :   ';
philips.pardef.StudyDescription.par_print       = '%s';
philips.pardef.StudyDescription.par_min_version = 3;
philips.pardef.StudyDescription.par_max_version = Inf;
philips.pardef.StudyDescription.group           = hex2dec('0008');
philips.pardef.StudyDescription.element         = hex2dec('1030');
philips.pardef.StudyDescription.type            = 'STRING';
philips.pardef.StudyDescription.dicom_sq        = 'series'; 
philips.pardef.StudyDescription.default         = 'UNKNOWN';

% 03
philips.pardef.ProtocolName.par_definition  = '.    Protocol name                      :   ';
philips.pardef.ProtocolName.par_print       = '%s';
philips.pardef.ProtocolName.par_min_version = 3;
philips.pardef.ProtocolName.par_max_version = Inf;
philips.pardef.ProtocolName.group           = hex2dec('0018');
philips.pardef.ProtocolName.element         = hex2dec('1030');
philips.pardef.ProtocolName.type            = 'STRING';
philips.pardef.ProtocolName.dicom_sq        = 'series'; 
philips.pardef.ProtocolName.default         = 'UNKNOWN';

% 04
philips.pardef.ExaminationStartDateTime.par_definition  = '.    Examination date/time              :   ';
philips.pardef.ExaminationStartDateTime.par_print       = '%s';
philips.pardef.ExaminationStartDateTime.format_func     = 'format_date_time';
philips.pardef.ExaminationStartDateTime.par_min_version = 3;
philips.pardef.ExaminationStartDateTime.par_max_version = Inf;
philips.pardef.ExaminationStartDateTime.group           = hex2dec('0040');
philips.pardef.ExaminationStartDateTime.element         = hex2dec({'0244','0245'});
philips.pardef.ExaminationStartDateTime.type            = {'DATE','TIME'};
philips.pardef.ExaminationStartDateTime.dicom_sq        = 'series'; 
philips.pardef.ExaminationStartDateTime.default         = 'UNKNOWN';

% 05
philips.pardef.SeriesType.par_definition  = '.    Series Type                        :   ';
philips.pardef.SeriesType.par_print       = '%s';
philips.pardef.SeriesType.format_func     = 'format_series_type';
philips.pardef.SeriesType.par_min_version = 4;
philips.pardef.SeriesType.par_max_version = Inf;
philips.pardef.SeriesType.group           = hex2dec('2001');
philips.pardef.SeriesType.element         = hex2dec('106E');
philips.pardef.SeriesType.type            = 'ENUM';
philips.pardef.SeriesType.enum            = {'SERIES','MRSERIES','CRSERIES','SCSERIES','SLICESERIES','GENERALSERIES'};
philips.pardef.SeriesType.dicom_sq        = 'series'; 
philips.pardef.SeriesType.default         = 'Image   MRSERIES';

% 06
philips.pardef.MRSeriesAcquisitionNumber.par_definition  = '.    Acquisition nr                     :   ';
philips.pardef.MRSeriesAcquisitionNumber.par_print       = '%d';
philips.pardef.MRSeriesAcquisitionNumber.format_func     = 'format_str2num';
philips.pardef.MRSeriesAcquisitionNumber.par_min_version = 3;
philips.pardef.MRSeriesAcquisitionNumber.par_max_version = Inf;
philips.pardef.MRSeriesAcquisitionNumber.group           = hex2dec('2001');
philips.pardef.MRSeriesAcquisitionNumber.element         = hex2dec('107B');
philips.pardef.MRSeriesAcquisitionNumber.type            = 'INTEGER';
philips.pardef.MRSeriesAcquisitionNumber.dicom_sq        = 'series'; 
philips.pardef.MRSeriesAcquisitionNumber.default         = '1';

% 07
philips.pardef.MRSeriesReconstructionNumber.par_definition  = '.    Reconstruction nr                  :   ';
philips.pardef.MRSeriesReconstructionNumber.par_print       = '%d';
philips.pardef.MRSeriesReconstructionNumber.format_func     = 'format_str2num';
philips.pardef.MRSeriesReconstructionNumber.par_min_version = 3;
philips.pardef.MRSeriesReconstructionNumber.par_max_version = Inf;
philips.pardef.MRSeriesReconstructionNumber.group           = hex2dec('2001');
philips.pardef.MRSeriesReconstructionNumber.element         = hex2dec('101D');
philips.pardef.MRSeriesReconstructionNumber.type            = 'INTEGER';
philips.pardef.MRSeriesReconstructionNumber.dicom_sq        = 'series'; 
philips.pardef.MRSeriesReconstructionNumber.default         = '1';

% 08
philips.pardef.MRSeriesScanDuration.par_definition  = '.    Scan Duration [sec]                :   ';
philips.pardef.MRSeriesScanDuration.par_print       = '%.3f';
philips.pardef.MRSeriesScanDuration.par_min_version = 3;
philips.pardef.MRSeriesScanDuration.par_max_version = Inf;
philips.pardef.MRSeriesScanDuration.group           = hex2dec('2005');
philips.pardef.MRSeriesScanDuration.element         = hex2dec('1033');
philips.pardef.MRSeriesScanDuration.type            = 'FLOAT';
philips.pardef.MRSeriesScanDuration.dicom_sq        = 'series'; 
philips.pardef.MRSeriesScanDuration.default         = '0.0';

% 09
philips.pardef.MRSeriesNrOfPhases.par_definition  = '.    Max. number of cardiac phases      :   ';
philips.pardef.MRSeriesNrOfPhases.par_print       = '%d';
philips.pardef.MRSeriesNrOfPhases.par_min_version = 3;
philips.pardef.MRSeriesNrOfPhases.par_max_version = Inf;
philips.pardef.MRSeriesNrOfPhases.group           = hex2dec('2001');
philips.pardef.MRSeriesNrOfPhases.element         = hex2dec('1017');
philips.pardef.MRSeriesNrOfPhases.type            = 'INTEGER';
philips.pardef.MRSeriesNrOfPhases.dicom_sq        = 'series'; 
philips.pardef.MRSeriesNrOfPhases.default         = '1';

% 10
philips.pardef.MRSeriesNrOfEchoes.par_definition  = '.    Max. number of echoes              :   ';
philips.pardef.MRSeriesNrOfEchoes.par_print       = '%d';
philips.pardef.MRSeriesNrOfEchoes.par_min_version = 3;
philips.pardef.MRSeriesNrOfEchoes.par_max_version = Inf;
philips.pardef.MRSeriesNrOfEchoes.group           = hex2dec('2001');
philips.pardef.MRSeriesNrOfEchoes.element         = hex2dec('1014');
philips.pardef.MRSeriesNrOfEchoes.type            = 'INTEGER';
philips.pardef.MRSeriesNrOfEchoes.dicom_sq        = 'series'; 
philips.pardef.MRSeriesNrOfEchoes.default         = '1';

% 11
philips.pardef.MRSeriesNrOfSlices.par_definition  = '.    Max. number of slices/locations    :   ';
philips.pardef.MRSeriesNrOfSlices.par_print       = '%d';
philips.pardef.MRSeriesNrOfSlices.par_min_version = 3;
philips.pardef.MRSeriesNrOfSlices.par_max_version = Inf;
philips.pardef.MRSeriesNrOfSlices.group           = hex2dec('2001');
philips.pardef.MRSeriesNrOfSlices.element         = hex2dec('1018');
philips.pardef.MRSeriesNrOfSlices.type            = 'INTEGER';
philips.pardef.MRSeriesNrOfSlices.dicom_sq        = 'series'; 
philips.pardef.MRSeriesNrOfSlices.default         = '1';

% 12
philips.pardef.MRSeriesNrOfDynamicScans.par_definition  = '.    Max. number of dynamics            :   ';
philips.pardef.MRSeriesNrOfDynamicScans.par_print       = '%d';
philips.pardef.MRSeriesNrOfDynamicScans.format_func     = 'format_str2num';
philips.pardef.MRSeriesNrOfDynamicScans.par_min_version = 3;
philips.pardef.MRSeriesNrOfDynamicScans.par_max_version = Inf;
philips.pardef.MRSeriesNrOfDynamicScans.group           = hex2dec('2001');
philips.pardef.MRSeriesNrOfDynamicScans.element         = hex2dec('1081');
philips.pardef.MRSeriesNrOfDynamicScans.type            = 'INTEGER';
philips.pardef.MRSeriesNrOfDynamicScans.dicom_sq        = 'series'; 
philips.pardef.MRSeriesNrOfDynamicScans.default         = '1';

% 13
philips.pardef.MRNumberOfMixes.par_definition  = '.    Max. number of mixes               :   ';
philips.pardef.MRNumberOfMixes.par_print       = '%d';
philips.pardef.MRNumberOfMixes.par_min_version = 3;
philips.pardef.MRNumberOfMixes.par_max_version = Inf;
philips.pardef.MRNumberOfMixes.group           = hex2dec('2005');
philips.pardef.MRNumberOfMixes.element         = hex2dec('1021');
philips.pardef.MRNumberOfMixes.type            = 'SHORT';
philips.pardef.MRNumberOfMixes.dicom_sq        = 'series'; 
philips.pardef.MRNumberOfMixes.default         = '1';

% 14
philips.pardef.PatientPosition.par_definition  = '.    Patient position                   :   ';
philips.pardef.PatientPosition.par_print       = '%s';
philips.pardef.PatientPosition.format_func     = 'format_patient_position';
philips.pardef.PatientPosition.par_min_version = 4;
philips.pardef.PatientPosition.par_max_version = Inf;
philips.pardef.PatientPosition.group           = hex2dec('0018');
philips.pardef.PatientPosition.element         = hex2dec('5100');
philips.pardef.PatientPosition.type            = 'STRING';
philips.pardef.PatientPosition.dicom_sq        = 'series'; 
philips.pardef.PatientPosition.default         = 'UNKNOWN';

% 15
philips.pardef.MRStackPrepartationDirection.par_definition  = '.    Preparation direction              :   ';
philips.pardef.MRStackPrepartationDirection.par_print       = '%s';
philips.pardef.MRStackPrepartationDirection.format_func     = 'format_preparation_direction';
philips.pardef.MRStackPrepartationDirection.par_min_version = 4;
philips.pardef.MRStackPrepartationDirection.par_max_version = Inf;
philips.pardef.MRStackPrepartationDirection.group           = hex2dec('2005');
philips.pardef.MRStackPrepartationDirection.element         = hex2dec('107B');
philips.pardef.MRStackPrepartationDirection.type            = 'STRING';
philips.pardef.MRStackPrepartationDirection.dicom_sq        = 'stack'; 
philips.pardef.MRStackPrepartationDirection.default         = 'UNKNOWN';

% 16
philips.pardef.BitsAllocated.par_definition  = '.    Image pixel size [8 or 16 bits]    :   ';
philips.pardef.BitsAllocated.par_print       = '%d';
philips.pardef.BitsAllocated.par_min_version = 3;
philips.pardef.BitsAllocated.par_max_version = 3;
philips.pardef.BitsAllocated.group           = hex2dec('0028');
philips.pardef.BitsAllocated.element         = hex2dec('0100');
philips.pardef.BitsAllocated.type            = 'USHORT';
philips.pardef.BitsAllocated.dicom_sq        = 'series'; 
philips.pardef.BitsAllocated.default         = '16';

% 17
philips.pardef.MRSeriesScanningTechniqueDesc.par_definition  = '.    Technique                          :   ';
philips.pardef.MRSeriesScanningTechniqueDesc.par_print       = '%s';
philips.pardef.MRSeriesScanningTechniqueDesc.par_min_version = 3;
philips.pardef.MRSeriesScanningTechniqueDesc.par_max_version = Inf;
philips.pardef.MRSeriesScanningTechniqueDesc.group           = hex2dec('2001');
philips.pardef.MRSeriesScanningTechniqueDesc.element         = hex2dec('1020');
philips.pardef.MRSeriesScanningTechniqueDesc.type            = 'INTEGER';
philips.pardef.MRSeriesScanningTechniqueDesc.dicom_sq        = 'series'; 
philips.pardef.MRSeriesScanningTechniqueDesc.default         = 'UNKNOWN';

% 18
philips.pardef.MRSeriesAcquisitionTypePrivateV3.par_definition  = '.    Scan mode                          :   ';
philips.pardef.MRSeriesAcquisitionTypePrivateV3.par_print       = '%s';
philips.pardef.MRSeriesAcquisitionTypePrivateV3.par_min_version = 3;
philips.pardef.MRSeriesAcquisitionTypePrivateV3.par_max_version = 3;
philips.pardef.MRSeriesAcquisitionTypePrivateV3.group           = hex2dec('2005');
philips.pardef.MRSeriesAcquisitionTypePrivateV3.element         = hex2dec('106F');
philips.pardef.MRSeriesAcquisitionTypePrivateV3.type            = 'ENUM';
philips.pardef.MRSeriesAcquisitionTypePrivateV3.enum            = {'UNKNOWN'  '2D'  '3D'  'MS'};
philips.pardef.MRSeriesAcquisitionTypePrivateV3.dicom_sq        = 'series'; 
philips.pardef.MRSeriesAcquisitionTypePrivateV3.default         = 'UNKNOWN';

% 19
philips.pardef.AcquisitionMatrix.par_definition  = '.    Scan resolution  (x, y)            :   ';
philips.pardef.AcquisitionMatrix.par_print       = '%d  %d';
philips.pardef.AcquisitionMatrix.format_func     = 'format_acquisition_matrix';
philips.pardef.AcquisitionMatrix.par_min_version = 3;
philips.pardef.AcquisitionMatrix.par_max_version = Inf;
philips.pardef.AcquisitionMatrix.group           = hex2dec('0018');
philips.pardef.AcquisitionMatrix.element         = hex2dec('1310');
philips.pardef.AcquisitionMatrix.type            = 'INTEGER';
philips.pardef.AcquisitionMatrix.size            = 4;
philips.pardef.AcquisitionMatrix.dicom_sq        = 'frame';
philips.pardef.AcquisitionMatrix.default         = '0 0';

% 20
philips.pardef.MRSeriesAcquisitionTypePrivate.par_definition  = '.    Scan mode                          :   ';
philips.pardef.MRSeriesAcquisitionTypePrivate.par_print       = '%s';
philips.pardef.MRSeriesAcquisitionTypePrivate.par_min_version = 4;
philips.pardef.MRSeriesAcquisitionTypePrivate.par_max_version = Inf;
philips.pardef.MRSeriesAcquisitionTypePrivate.group           = hex2dec('2005');
philips.pardef.MRSeriesAcquisitionTypePrivate.element         = hex2dec('106F');
philips.pardef.MRSeriesAcquisitionTypePrivate.type            = 'ENUM';
philips.pardef.MRSeriesAcquisitionTypePrivate.enum            = {'UNKNOWN'  '2D'  '3D'  'MS'};
philips.pardef.MRSeriesAcquisitionTypePrivate.dicom_sq        = 'series'; 
philips.pardef.MRSeriesAcquisitionTypePrivate.default         = 'UNKNOWN';

% 21
philips.pardef.MRImagePercentSampling.par_definition  = '.    Scan percentage                    :   ';
philips.pardef.MRImagePercentSampling.par_print       = '%d';
philips.pardef.MRImagePercentSampling.format_func     = 'format_str2num';
philips.pardef.MRImagePercentSampling.par_min_version = 3;
philips.pardef.MRImagePercentSampling.par_max_version = 3;
philips.pardef.MRImagePercentSampling.group           = hex2dec('0018');
philips.pardef.MRImagePercentSampling.element         = hex2dec('0093');
philips.pardef.MRImagePercentSampling.type            = 'INTEGER';
philips.pardef.MRImagePercentSampling.dicom_sq        = 'frame'; 
philips.pardef.MRImagePercentSampling.default         = '100';

% 22
philips.pardef.ImageRowsColumns.par_definition  = '.    Recon resolution (x, y)            :   ';
philips.pardef.ImageRowsColumns.par_print       = '%d  %d';
philips.pardef.ImageRowsColumns.format_func     = 'format_recon_resolution';
philips.pardef.ImageRowsColumns.par_min_version = 3;
philips.pardef.ImageRowsColumns.par_max_version = 3;
philips.pardef.ImageRowsColumns.group           = hex2dec('0028');
philips.pardef.ImageRowsColumns.element         = hex2dec({'0010','0011'});
philips.pardef.ImageRowsColumns.type            = {'INTEGER','INTEGER'};
philips.pardef.ImageRowsColumns.dicom_sq        = 'series'; 
philips.pardef.ImageRowsColumns.default         = '0 0';

% 23
philips.pardef.MRSeriesNumberOfAverages.par_definition  = '.    Number of averages                 :   ';
philips.pardef.MRSeriesNumberOfAverages.par_print       = '%.0f';
philips.pardef.MRSeriesNumberOfAverages.format_func     = 'format_str2num';
philips.pardef.MRSeriesNumberOfAverages.par_min_version = 3;
philips.pardef.MRSeriesNumberOfAverages.par_max_version = 3;
philips.pardef.MRSeriesNumberOfAverages.group           = hex2dec('2001');
philips.pardef.MRSeriesNumberOfAverages.element         = hex2dec('1088');
philips.pardef.MRSeriesNumberOfAverages.type            = 'DOUBLE';
philips.pardef.MRSeriesNumberOfAverages.dicom_sq        = 'series'; 
philips.pardef.MRSeriesNumberOfAverages.default         = '1';

% 24
philips.pardef.MRSeriesRepetitionTimeV3.par_definition  = '.    Repetition time [msec]             :   ';
philips.pardef.MRSeriesRepetitionTimeV3.par_print       = '%s';
philips.pardef.MRSeriesRepetitionTimeV3.format_func     = 'format_repetition_time';
philips.pardef.MRSeriesRepetitionTimeV3.par_min_version = 3;
philips.pardef.MRSeriesRepetitionTimeV3.par_max_version = 3;
philips.pardef.MRSeriesRepetitionTimeV3.group           = hex2dec('2005');
philips.pardef.MRSeriesRepetitionTimeV3.element         = hex2dec('1030');
philips.pardef.MRSeriesRepetitionTimeV3.type            = 'FLOAT';
philips.pardef.MRSeriesRepetitionTimeV3.dicom_sq        = 'series'; 
philips.pardef.MRSeriesRepetitionTimeV3.default         = '0';

% 25
philips.pardef.MRSeriesRepetitionTime.par_definition  = '.    Repetition time [ms]               :   ';
philips.pardef.MRSeriesRepetitionTime.par_print       = '%s';
philips.pardef.MRSeriesRepetitionTime.format_func     = 'format_repetition_time';
philips.pardef.MRSeriesRepetitionTime.par_min_version = 4;
philips.pardef.MRSeriesRepetitionTime.par_max_version = Inf;
philips.pardef.MRSeriesRepetitionTime.group           = hex2dec('2005');
philips.pardef.MRSeriesRepetitionTime.element         = hex2dec('1030');
philips.pardef.MRSeriesRepetitionTime.type            = 'FLOAT';
philips.pardef.MRSeriesRepetitionTime.dicom_sq        = 'series'; 
philips.pardef.MRSeriesRepetitionTime.default         = '0';

% 26
philips.pardef.MRStackFovV3toV4.par_definition  = '.    FOV (ap,fh,rl) [mm]                :   ';
philips.pardef.MRStackFovV3toV4.par_print       = '%.2f  %.2f  %.2f';
philips.pardef.MRStackFovV3toV4.format_func     = 'format_cell2num';
philips.pardef.MRStackFovV3toV4.par_min_version = 3;
philips.pardef.MRStackFovV3toV4.par_max_version = 4;
philips.pardef.MRStackFovV3toV4.group           = hex2dec('2005');
philips.pardef.MRStackFovV3toV4.element         = hex2dec({'1074','1075','1076'});
philips.pardef.MRStackFovV3toV4.type            = 'FLOAT';
philips.pardef.MRStackFovV3toV4.dicom_sq        = 'stack'; 
philips.pardef.MRStackFovV3toV4.default         = '0 0 0';

% 26
philips.pardef.MRStackFov.par_definition  = '.    FOV (ap,fh,rl) [mm]                :   ';
philips.pardef.MRStackFov.par_print       = '%.3f  %.3f  %.3f';
philips.pardef.MRStackFov.format_func     = 'format_cell2num';
philips.pardef.MRStackFov.par_min_version = 4.1;
philips.pardef.MRStackFov.par_max_version = Inf;
philips.pardef.MRStackFov.group           = hex2dec('2005');
philips.pardef.MRStackFov.element         = hex2dec({'1074','1075','1076'});
philips.pardef.MRStackFov.type            = 'FLOAT';
philips.pardef.MRStackFov.dicom_sq        = 'stack'; 
philips.pardef.MRStackFov.default         = '0 0 0';

% 27
philips.pardef.ImagePlaneSliceThickness.par_definition  = '.    Slice thickness [mm]               :   ';
philips.pardef.ImagePlaneSliceThickness.par_print       = '%.2f';
philips.pardef.ImagePlaneSliceThickness.format_func     = 'format_str2num';
philips.pardef.ImagePlaneSliceThickness.par_min_version = 3;
philips.pardef.ImagePlaneSliceThickness.par_max_version = 3;
philips.pardef.ImagePlaneSliceThickness.group           = hex2dec('0018');
philips.pardef.ImagePlaneSliceThickness.element         = hex2dec('0050');
philips.pardef.ImagePlaneSliceThickness.type            = 'FLOAT';
philips.pardef.ImagePlaneSliceThickness.dicom_sq        = 'frame'; 
philips.pardef.ImagePlaneSliceThickness.default         = '0';

% 28
philips.pardef.MRImageSpacingBetweenSlices.par_definition  = '.    Slice gap [mm]                     :   ';
philips.pardef.MRImageSpacingBetweenSlices.par_print       = '%.2f';
philips.pardef.MRImageSpacingBetweenSlices.format_func     = 'format_slice_gap';
philips.pardef.MRImageSpacingBetweenSlices.par_min_version = 3;
philips.pardef.MRImageSpacingBetweenSlices.par_max_version = 3;
philips.pardef.MRImageSpacingBetweenSlices.group           = hex2dec('0018');
philips.pardef.MRImageSpacingBetweenSlices.element         = hex2dec('0088');
philips.pardef.MRImageSpacingBetweenSlices.type            = 'FLOAT';
philips.pardef.MRImageSpacingBetweenSlices.dicom_sq        = 'series'; 
philips.pardef.MRImageSpacingBetweenSlices.default         = '0';

% 29
philips.pardef.MRSeriesWaterFatShiftV3toV4.par_definition  = '.    Water Fat shift [pixels]           :   ';
philips.pardef.MRSeriesWaterFatShiftV3toV4.par_print       = '%.2f';
philips.pardef.MRSeriesWaterFatShiftV3toV4.par_min_version = 3;
philips.pardef.MRSeriesWaterFatShiftV3toV4.par_max_version = 4;
philips.pardef.MRSeriesWaterFatShiftV3toV4.group           = hex2dec('2001');
philips.pardef.MRSeriesWaterFatShiftV3toV4.element         = hex2dec('1022');
philips.pardef.MRSeriesWaterFatShiftV3toV4.type            = 'FLOAT';
philips.pardef.MRSeriesWaterFatShiftV3toV4.dicom_sq        = 'series'; 
philips.pardef.MRSeriesWaterFatShiftV3toV4.default         = '0';

% 29
philips.pardef.MRSeriesWaterFatShift.par_definition  = '.    Water Fat shift [pixels]           :   ';
philips.pardef.MRSeriesWaterFatShift.par_print       = '%.3f';
philips.pardef.MRSeriesWaterFatShift.par_min_version = 4.1;
philips.pardef.MRSeriesWaterFatShift.par_max_version = Inf;
philips.pardef.MRSeriesWaterFatShift.group           = hex2dec('2001');
philips.pardef.MRSeriesWaterFatShift.element         = hex2dec('1022');
philips.pardef.MRSeriesWaterFatShift.type            = 'FLOAT';
philips.pardef.MRSeriesWaterFatShift.dicom_sq        = 'series'; 
philips.pardef.MRSeriesWaterFatShift.default         = '0';

% 30
philips.pardef.MRStackAngulationV3toV4.par_definition  = '.    Angulation midslice(ap,fh,rl)[degr]:   ';
philips.pardef.MRStackAngulationV3toV4.par_print       = '%.2f  %.2f  %.2f';
philips.pardef.MRStackAngulationV3toV4.format_func     = 'format_cell2num';
philips.pardef.MRStackAngulationV3toV4.par_min_version = 3;
philips.pardef.MRStackAngulationV3toV4.par_max_version = 4;
philips.pardef.MRStackAngulationV3toV4.group           = hex2dec('2005');
philips.pardef.MRStackAngulationV3toV4.element         = hex2dec({'1071','1072','1073'});
philips.pardef.MRStackAngulationV3toV4.type            = 'FLOAT';
philips.pardef.MRStackAngulationV3toV4.dicom_sq        = 'stack'; 
philips.pardef.MRStackAngulationV3toV4.default         = '0 0 0';

% 30
philips.pardef.MRStackAngulation.par_definition  = '.    Angulation midslice(ap,fh,rl)[degr]:   ';
philips.pardef.MRStackAngulation.par_print       = '%.3f  %.3f  %.3f';
philips.pardef.MRStackAngulation.format_func     = 'format_cell2num';
philips.pardef.MRStackAngulation.par_min_version = 4.1;
philips.pardef.MRStackAngulation.par_max_version = Inf;
philips.pardef.MRStackAngulation.group           = hex2dec('2005');
philips.pardef.MRStackAngulation.element         = hex2dec({'1071','1072','1073'});
philips.pardef.MRStackAngulation.type            = 'FLOAT';
philips.pardef.MRStackAngulation.dicom_sq        = 'stack'; 
philips.pardef.MRStackAngulation.default         = '0 0 0';

% 31
philips.pardef.MRStackOffcentreV3toV4.par_definition  = '.    Off Centre midslice(ap,fh,rl) [mm] :   ';
philips.pardef.MRStackOffcentreV3toV4.par_print       = '%.2f  %.2f  %.2f';
philips.pardef.MRStackOffcentreV3toV4.format_func     = 'format_cell2num';
philips.pardef.MRStackOffcentreV3toV4.par_min_version = 3;
philips.pardef.MRStackOffcentreV3toV4.par_max_version = 4;
philips.pardef.MRStackOffcentreV3toV4.group           = hex2dec('2005');
philips.pardef.MRStackOffcentreV3toV4.element         = hex2dec({'1078','1079','107A'});
philips.pardef.MRStackOffcentreV3toV4.type            = 'FLOAT';
philips.pardef.MRStackOffcentreV3toV4.dicom_sq        = 'stack'; 
philips.pardef.MRStackOffcentreV3toV4.default         = '0 0 0';

% 31
philips.pardef.MRStackOffcentre.par_definition  = '.    Off Centre midslice(ap,fh,rl) [mm] :   ';
philips.pardef.MRStackOffcentre.par_print       = '%.3f  %.3f  %.3f';
philips.pardef.MRStackOffcentre.format_func     = 'format_cell2num';
philips.pardef.MRStackOffcentre.par_min_version = 4.1;
philips.pardef.MRStackOffcentre.par_max_version = Inf;
philips.pardef.MRStackOffcentre.group           = hex2dec('2005');
philips.pardef.MRStackOffcentre.element         = hex2dec({'1078','1079','107A'});
philips.pardef.MRStackOffcentre.type            = 'FLOAT';
philips.pardef.MRStackOffcentre.dicom_sq        = 'stack'; 
philips.pardef.MRStackOffcentre.default         = '0 0 0';

% 32
philips.pardef.MRFlowCompensation.par_definition  = '.    Flow compensation <0=no 1=yes> ?   :   ';
philips.pardef.MRFlowCompensation.par_print       = '%d';
philips.pardef.MRFlowCompensation.format_func     = 'format_boolean';
philips.pardef.MRFlowCompensation.par_min_version = 3;
philips.pardef.MRFlowCompensation.par_max_version = Inf;
philips.pardef.MRFlowCompensation.group           = hex2dec('2005');
philips.pardef.MRFlowCompensation.element         = hex2dec('1016');
philips.pardef.MRFlowCompensation.type            = 'BOOLEAN';
philips.pardef.MRFlowCompensation.dicom_sq        = 'series'; 
philips.pardef.MRFlowCompensation.default         = '0';

% 33
philips.pardef.MRSpatialPresaturation.par_definition  = '.    Presaturation     <0=no 1=yes> ?   :   ';
philips.pardef.MRSpatialPresaturation.par_print       = '%d';
philips.pardef.MRSpatialPresaturation.format_func     = 'format_boolean';
philips.pardef.MRSpatialPresaturation.par_min_version = 3;
philips.pardef.MRSpatialPresaturation.par_max_version = Inf;
philips.pardef.MRSpatialPresaturation.group           = hex2dec('2005');
philips.pardef.MRSpatialPresaturation.element         = hex2dec('102F');
philips.pardef.MRSpatialPresaturation.type            = 'BOOLEAN';
philips.pardef.MRSpatialPresaturation.dicom_sq        = 'series'; 
philips.pardef.MRSpatialPresaturation.default         = '0';

% 34
philips.pardef.MRImageHeartRate.par_definition  = '.    Cardiac frequency                  :   ';
philips.pardef.MRImageHeartRate.par_print       = '%d';
philips.pardef.MRImageHeartRate.format_func     = 'format_str2num';
philips.pardef.MRImageHeartRate.par_min_version = 3;
philips.pardef.MRImageHeartRate.par_max_version = 3;
philips.pardef.MRImageHeartRate.group           = hex2dec('0018');
philips.pardef.MRImageHeartRate.element         = hex2dec('1088');
philips.pardef.MRImageHeartRate.type            = 'INTEGER';
philips.pardef.MRImageHeartRate.dicom_sq        = 'frame'; 
philips.pardef.MRImageHeartRate.default         = '0';

% 35
philips.pardef.MRImageLowRRValue.par_definition  = '.    Min. RR interval                   :   ';
philips.pardef.MRImageLowRRValue.par_print       = '%d';
philips.pardef.MRImageLowRRValue.format_func     = 'format_str2num';
philips.pardef.MRImageLowRRValue.par_min_version = 3;
philips.pardef.MRImageLowRRValue.par_max_version = 3;
philips.pardef.MRImageLowRRValue.group           = hex2dec('0018');
philips.pardef.MRImageLowRRValue.element         = hex2dec('1081');
philips.pardef.MRImageLowRRValue.type            = 'INTEGER';
philips.pardef.MRImageLowRRValue.dicom_sq        = 'frame'; 
philips.pardef.MRImageLowRRValue.default         = '0';

% 36
philips.pardef.MRImageHighRRValue.par_definition  = '.    Max. RR interval                   :   ';
philips.pardef.MRImageHighRRValue.par_print       = '%d';
philips.pardef.MRImageHighRRValue.format_func     = 'format_str2num';
philips.pardef.MRImageHighRRValue.par_min_version = 3;
philips.pardef.MRImageHighRRValue.par_max_version = 3;
philips.pardef.MRImageHighRRValue.group           = hex2dec('0018');
philips.pardef.MRImageHighRRValue.element         = hex2dec('1082');
philips.pardef.MRImageHighRRValue.type            = 'INTEGER';
philips.pardef.MRImageHighRRValue.dicom_sq        = 'frame'; 
philips.pardef.MRImageHighRRValue.default         = '0';

% 37
philips.pardef.MRSeriesPCVelocityV3toV4.par_definition  = '.    Phase encoding velocity [cm/sec]   :   ';
philips.pardef.MRSeriesPCVelocityV3toV4.par_print       = '%.2f %.2f %.2f';
philips.pardef.MRSeriesPCVelocityV3toV4.par_min_version = 3;
philips.pardef.MRSeriesPCVelocityV3toV4.par_max_version = 4;
philips.pardef.MRSeriesPCVelocityV3toV4.group           = hex2dec('2001');
philips.pardef.MRSeriesPCVelocityV3toV4.element         = hex2dec('101A');
philips.pardef.MRSeriesPCVelocityV3toV4.type            = 'FLOAT';
philips.pardef.MRSeriesPCVelocityV3toV4.size            = 3;
philips.pardef.MRSeriesPCVelocityV3toV4.dicom_sq        = 'series'; 
philips.pardef.MRSeriesPCVelocityV3toV4.default         = '0 0 0';

% 37
philips.pardef.MRSeriesPCVelocity.par_definition  = '.    Phase encoding velocity [cm/sec]   :   ';
philips.pardef.MRSeriesPCVelocity.par_print       = '%.6f  %.6f  %.6f';
philips.pardef.MRSeriesPCVelocity.par_min_version = 4.1;
philips.pardef.MRSeriesPCVelocity.par_max_version = Inf;
philips.pardef.MRSeriesPCVelocity.group           = hex2dec('2001');
philips.pardef.MRSeriesPCVelocity.element         = hex2dec('101A');
philips.pardef.MRSeriesPCVelocity.type            = 'FLOAT';
philips.pardef.MRSeriesPCVelocity.size            = 3;
philips.pardef.MRSeriesPCVelocity.dicom_sq        = 'series'; 
philips.pardef.MRSeriesPCVelocity.default         = '0 0 0';

% 38
philips.pardef.MRMagnetTransferConst.par_definition  = '.    MTC               <0=no 1=yes> ?   :   ';
philips.pardef.MRMagnetTransferConst.par_print       = '%d';
philips.pardef.MRMagnetTransferConst.format_func     = 'format_boolean';
philips.pardef.MRMagnetTransferConst.par_min_version = 3;
philips.pardef.MRMagnetTransferConst.par_max_version = Inf;
philips.pardef.MRMagnetTransferConst.group           = hex2dec('2005');
philips.pardef.MRMagnetTransferConst.element         = hex2dec('101C');
philips.pardef.MRMagnetTransferConst.type            = 'BOOLEAN';
philips.pardef.MRMagnetTransferConst.dicom_sq        = 'series'; 
philips.pardef.MRMagnetTransferConst.default         = '0';

% 39
philips.pardef.MRFatSaturation.par_definition  = '.    SPIR              <0=no 1=yes> ?   :   ';
philips.pardef.MRFatSaturation.par_print       = '%d';
philips.pardef.MRFatSaturation.format_func     = 'format_boolean';
philips.pardef.MRFatSaturation.par_min_version = 3;
philips.pardef.MRFatSaturation.par_max_version = Inf;
philips.pardef.MRFatSaturation.group           = hex2dec('2005');
philips.pardef.MRFatSaturation.element         = hex2dec('1015');
philips.pardef.MRFatSaturation.type            = 'BOOLEAN';
philips.pardef.MRFatSaturation.dicom_sq        = 'series'; 
philips.pardef.MRFatSaturation.default         = '0';

% 40
philips.pardef.MRSeriesEPIFactor.par_definition  = '.    EPI factor        <0,1=no EPI>     :   ';
philips.pardef.MRSeriesEPIFactor.par_print       = '%d';
philips.pardef.MRSeriesEPIFactor.par_min_version = 3;
philips.pardef.MRSeriesEPIFactor.par_max_version = Inf;
philips.pardef.MRSeriesEPIFactor.group           = hex2dec('2001');
philips.pardef.MRSeriesEPIFactor.element         = hex2dec('1013');
philips.pardef.MRSeriesEPIFactor.type            = 'INTEGER';
philips.pardef.MRSeriesEPIFactor.dicom_sq        = 'series'; 
philips.pardef.MRSeriesEPIFactor.default         = '1';

% 41
philips.pardef.MRSeriesEchoTrainLength.par_definition  = '.    TURBO factor      <0=no turbo>     :   ';
philips.pardef.MRSeriesEchoTrainLength.par_print       = '%d';
philips.pardef.MRSeriesEchoTrainLength.format_func     = 'format_str2num';
philips.pardef.MRSeriesEchoTrainLength.par_min_version = 3;
philips.pardef.MRSeriesEchoTrainLength.par_max_version = 3;
philips.pardef.MRSeriesEchoTrainLength.group           = hex2dec('2001');
philips.pardef.MRSeriesEchoTrainLength.element         = hex2dec('1082');
philips.pardef.MRSeriesEchoTrainLength.type            = 'INTEGER';
philips.pardef.MRSeriesEchoTrainLength.dicom_sq        = 'series'; 
philips.pardef.MRSeriesEchoTrainLength.default         = '0';

% 42
philips.pardef.MRSeriesDynamicSeries.par_definition  = '.    Dynamic scan      <0=no 1=yes> ?   :   ';
philips.pardef.MRSeriesDynamicSeries.par_print       = '%d';
philips.pardef.MRSeriesDynamicSeries.format_func     = 'format_boolean';
philips.pardef.MRSeriesDynamicSeries.par_min_version = 3;
philips.pardef.MRSeriesDynamicSeries.par_max_version = Inf;
philips.pardef.MRSeriesDynamicSeries.group           = hex2dec('2001');
philips.pardef.MRSeriesDynamicSeries.element         = hex2dec('1012');
philips.pardef.MRSeriesDynamicSeries.type            = 'BOOLEAN';
philips.pardef.MRSeriesDynamicSeries.dicom_sq        = 'series'; 
philips.pardef.MRSeriesDynamicSeries.default         = '0';

% 43
philips.pardef.MRSeriesDiffusion.par_definition  = '.    Diffusion         <0=no 1=yes> ?   :   ';
philips.pardef.MRSeriesDiffusion.par_print       = '%d';
philips.pardef.MRSeriesDiffusion.format_func     = 'format_boolean';
philips.pardef.MRSeriesDiffusion.par_min_version = 3;
philips.pardef.MRSeriesDiffusion.par_max_version = Inf;
philips.pardef.MRSeriesDiffusion.group           = hex2dec('2005');
philips.pardef.MRSeriesDiffusion.element         = hex2dec('1014');
philips.pardef.MRSeriesDiffusion.type            = 'BOOLEAN';
philips.pardef.MRSeriesDiffusion.dicom_sq        = 'series'; 
philips.pardef.MRSeriesDiffusion.default         = '0';

% 44
philips.pardef.MRSeriesDiffusionEchoTimeV3V4.par_definition  = '.    Diffusion echo time [msec]         :   ';
philips.pardef.MRSeriesDiffusionEchoTimeV3V4.par_print       = '%.2f';
philips.pardef.MRSeriesDiffusionEchoTimeV3V4.par_min_version = 3;
philips.pardef.MRSeriesDiffusionEchoTimeV3V4.par_max_version = 3;
philips.pardef.MRSeriesDiffusionEchoTimeV3V4.group           = hex2dec('2001');
philips.pardef.MRSeriesDiffusionEchoTimeV3V4.element         = hex2dec('1011');
philips.pardef.MRSeriesDiffusionEchoTimeV3V4.type            = 'FLOAT';
philips.pardef.MRSeriesDiffusionEchoTimeV3V4.dicom_sq        = 'series'; 
philips.pardef.MRSeriesDiffusionEchoTimeV3V4.default         = '0';

% 45
philips.pardef.MRSeriesDiffusionEchoTime.par_definition  = '.    Diffusion echo time [ms]           :   ';
philips.pardef.MRSeriesDiffusionEchoTime.par_print       = '%.4f';
philips.pardef.MRSeriesDiffusionEchoTime.par_min_version = 4;
philips.pardef.MRSeriesDiffusionEchoTime.par_max_version = Inf;
philips.pardef.MRSeriesDiffusionEchoTime.group           = hex2dec('2001');
philips.pardef.MRSeriesDiffusionEchoTime.element         = hex2dec('1011');
philips.pardef.MRSeriesDiffusionEchoTime.type            = 'FLOAT';
philips.pardef.MRSeriesDiffusionEchoTime.dicom_sq        = 'series'; 
philips.pardef.MRSeriesDiffusionEchoTime.default         = '0';

% 46
philips.pardef.MRImagePrepulseDelay.par_definition  = '.    Inversion delay [msec]             :   ';
philips.pardef.MRImagePrepulseDelay.par_print       = '%.2f';
philips.pardef.MRImagePrepulseDelay.par_min_version = 3;
philips.pardef.MRImagePrepulseDelay.par_max_version = 3;
philips.pardef.MRImagePrepulseDelay.group           = hex2dec('2001');
philips.pardef.MRImagePrepulseDelay.element         = hex2dec('1009');
philips.pardef.MRImagePrepulseDelay.type            = 'FLOAT';
philips.pardef.MRImagePrepulseDelay.dicom_sq        = 'frame'; 
philips.pardef.MRImagePrepulseDelay.default         = '0';

% 47
philips.pardef.MRSeriesNrOfDiffBValues.par_definition  = '.    Max. number of diffusion values    :   ';
philips.pardef.MRSeriesNrOfDiffBValues.par_print       = '%d';
philips.pardef.MRSeriesNrOfDiffBValues.par_min_version = 4.1;
philips.pardef.MRSeriesNrOfDiffBValues.par_max_version = Inf;
philips.pardef.MRSeriesNrOfDiffBValues.group           = hex2dec('2005');
philips.pardef.MRSeriesNrOfDiffBValues.element         = hex2dec('1414');
philips.pardef.MRSeriesNrOfDiffBValues.type            = 'INTEGER';
philips.pardef.MRSeriesNrOfDiffBValues.dicom_sq        = 'series'; 
philips.pardef.MRSeriesNrOfDiffBValues.default         = '1';

% 48
philips.pardef.MRSeriesNrOfDiffGradOrients.par_definition  = '.    Max. number of gradient orients    :   ';
philips.pardef.MRSeriesNrOfDiffGradOrients.par_print       = '%d';
philips.pardef.MRSeriesNrOfDiffGradOrients.par_min_version = 4.1;
philips.pardef.MRSeriesNrOfDiffGradOrients.par_max_version = Inf;
philips.pardef.MRSeriesNrOfDiffGradOrients.group           = hex2dec('2005');
philips.pardef.MRSeriesNrOfDiffGradOrients.element         = hex2dec('1415');
philips.pardef.MRSeriesNrOfDiffGradOrients.type            = 'INTEGER';
philips.pardef.MRSeriesNrOfDiffGradOrients.dicom_sq        = 'series'; 
philips.pardef.MRSeriesNrOfDiffGradOrients.default         = '1';

% 49
philips.pardef.MRSeriesNrOfLabelTypes.par_definition  = '.    Number of label types   <0=no ASL> :   ';
philips.pardef.MRSeriesNrOfLabelTypes.par_print       = '%d';
philips.pardef.MRSeriesNrOfLabelTypes.par_min_version = 4.2;
philips.pardef.MRSeriesNrOfLabelTypes.par_max_version = Inf;
philips.pardef.MRSeriesNrOfLabelTypes.group           = hex2dec('2005');
philips.pardef.MRSeriesNrOfLabelTypes.element         = hex2dec('1428');
philips.pardef.MRSeriesNrOfLabelTypes.type            = 'INTEGER';
philips.pardef.MRSeriesNrOfLabelTypes.dicom_sq        = 'series'; 
philips.pardef.MRSeriesNrOfLabelTypes.default         = '0';

%% Philips extra needed parameters available in DICOM

% Extra Needed 01
philips.pardef.NumberOfFrames.par_definition  = '';
philips.pardef.NumberOfFrames.par_print       = '%d';
philips.pardef.NumberOfFrames.format_func     = 'format_str2num';
philips.pardef.NumberOfFrames.par_min_version = 0;
philips.pardef.NumberOfFrames.par_max_version = Inf;
philips.pardef.NumberOfFrames.group           = hex2dec('0028');
philips.pardef.NumberOfFrames.element         = hex2dec('0008');
philips.pardef.NumberOfFrames.type            = 'STRING';
philips.pardef.NumberOfFrames.dicom_sq        = 'series'; 
philips.pardef.NumberOfFrames.default         = '1';

% Extra Needed 02
philips.pardef.MRSeriesNrOfStacks.par_definition  = '';
philips.pardef.MRSeriesNrOfStacks.par_print       = '%d';
philips.pardef.MRSeriesNrOfStacks.par_min_version = 0;
philips.pardef.MRSeriesNrOfStacks.par_max_version = Inf;
philips.pardef.MRSeriesNrOfStacks.group           = hex2dec('2001');
philips.pardef.MRSeriesNrOfStacks.element         = hex2dec('1060');
philips.pardef.MRSeriesNrOfStacks.type            = 'INTEGER';
philips.pardef.MRSeriesNrOfStacks.dicom_sq        = 'series'; 
philips.pardef.MRSeriesNrOfStacks.default         = '1';

%% Philips extra useful parameters available in DICOM

% Extra Useful 01
philips.pardef.PixelBandwidth.par_definition  = '';
philips.pardef.PixelBandwidth.par_print       = '%d';
philips.pardef.PixelBandwidth.format_func     = 'format_str2num';
philips.pardef.PixelBandwidth.par_min_version = 0;
philips.pardef.PixelBandwidth.par_max_version = Inf;
philips.pardef.PixelBandwidth.group           = hex2dec('0018');
philips.pardef.PixelBandwidth.element         = hex2dec('0095');
philips.pardef.PixelBandwidth.type            = 'DOUBLE';
philips.pardef.PixelBandwidth.dicom_sq        = 'series'; 

% Extra Useful 02
philips.pardef.ParallelAcqTechnique.par_definition  = '';
philips.pardef.ParallelAcqTechnique.par_print       = '%s';
philips.pardef.ParallelAcqTechnique.format_func     = 'format_str2str';
philips.pardef.ParallelAcqTechnique.par_min_version = 0;
philips.pardef.ParallelAcqTechnique.par_max_version = Inf;
philips.pardef.ParallelAcqTechnique.group           = hex2dec('0018');
philips.pardef.ParallelAcqTechnique.element         = hex2dec('9078');
philips.pardef.ParallelAcqTechnique.type            = 'ENUM';
philips.pardef.ParallelAcquisition.enum            = {'PILS','SENSE','SMASH','OTHER'};
philips.pardef.ParallelAcqTechnique.dicom_sq        = 'series'; 

% Extra Useful 03
philips.pardef.ParallelAcquisition.par_definition  = '';
philips.pardef.ParallelAcquisition.par_print       = '%s';
philips.pardef.ParallelAcquisition.format_func     = 'format_str2str';
philips.pardef.ParallelAcquisition.par_min_version = 0;
philips.pardef.ParallelAcquisition.par_max_version = Inf;
philips.pardef.ParallelAcquisition.group           = hex2dec('0018');
philips.pardef.ParallelAcquisition.element         = hex2dec('9077');
philips.pardef.ParallelAcquisition.type            = 'ENUM';
philips.pardef.ParallelAcquisition.enum            = {'YES','NO'};
philips.pardef.ParallelAcquisition.dicom_sq        = 'series'; 

% Extra Useful 04
philips.pardef.ParallelRedFactorInPlane.par_definition  = '';
philips.pardef.ParallelRedFactorInPlane.par_print       = '%.3f';
philips.pardef.ParallelRedFactorInPlane.par_min_version = 0;
philips.pardef.ParallelRedFactorInPlane.par_max_version = Inf;
philips.pardef.ParallelRedFactorInPlane.group           = hex2dec('0018');
philips.pardef.ParallelRedFactorInPlane.element         = hex2dec('9069');
philips.pardef.ParallelRedFactorInPlane.type            = 'DOUBLE';
philips.pardef.ParallelRedFactorInPlane.dicom_sq        = 'series'; 

% Extra Useful 05
philips.pardef.TransmitterFrequency.par_definition  = '';
philips.pardef.TransmitterFrequency.par_print       = '%.0f';
philips.pardef.TransmitterFrequency.format_func     = 'format_resonant_frequency';
philips.pardef.TransmitterFrequency.par_min_version = 0;
philips.pardef.TransmitterFrequency.par_max_version = Inf;
philips.pardef.TransmitterFrequency.group           = hex2dec('0018');
philips.pardef.TransmitterFrequency.element         = hex2dec('9098');
philips.pardef.TransmitterFrequency.type            = 'DOUBLE';
philips.pardef.TransmitterFrequency.dicom_sq        = 'series'; 

% Extra Useful 06
philips.pardef.MRImageReceivingCoil.par_definition  = '';
philips.pardef.MRImageReceivingCoil.par_print       = '%s';
philips.pardef.MRImageReceivingCoil.format_func     = 'format_str2str';
philips.pardef.MRImageReceivingCoil.par_min_version = 0;
philips.pardef.MRImageReceivingCoil.par_max_version = Inf;
philips.pardef.MRImageReceivingCoil.group           = hex2dec('0018');
philips.pardef.MRImageReceivingCoil.element         = hex2dec('1250');
philips.pardef.MRImageReceivingCoil.type            = 'STRING';
philips.pardef.MRImageReceivingCoil.dicom_sq        = 'frame'; 
philips.pardef.MRImageReceivingCoil.default         = 'UNKNOWN_COIL'; 

% Extra Useful 07
philips.pardef.SoftwareVersion.par_definition  = '';
philips.pardef.SoftwareVersion.par_print       = '%s';
philips.pardef.SoftwareVersion.format_func     = 'format_str2str';
philips.pardef.SoftwareVersion.par_min_version = 0;
philips.pardef.SoftwareVersion.par_max_version = Inf;
philips.pardef.SoftwareVersion.group           = hex2dec('0018');
philips.pardef.SoftwareVersion.element         = hex2dec('1020');
philips.pardef.SoftwareVersion.type            = 'STRING';
philips.pardef.SoftwareVersion.dicom_sq        = 'series'; 
philips.pardef.SoftwareVersion.default         = 'UNKNOWN_SOFTWARE_VERSION';

% Extra Useful 08
philips.pardef.PartialFourier.par_definition  = '';
philips.pardef.PartialFourier.par_print       = '%s';
philips.pardef.PartialFourier.format_func     = 'format_str2str';
philips.pardef.PartialFourier.par_min_version = 0;
philips.pardef.PartialFourier.par_max_version = Inf;
philips.pardef.PartialFourier.group           = hex2dec('0018');
philips.pardef.PartialFourier.element         = hex2dec('9081');
philips.pardef.PartialFourier.type            = 'STRING';
philips.pardef.PartialFourier.dicom_sq        = 'series';

% Extra Useful 09
philips.pardef.MRSeriesDevelopmentMode.par_definition  = '';
philips.pardef.MRSeriesDevelopmentMode.par_print       = '%s';
philips.pardef.MRSeriesDevelopmentMode.format_func     = 'format_str2str';
philips.pardef.MRSeriesDevelopmentMode.par_min_version = 0;
philips.pardef.MRSeriesDevelopmentMode.par_max_version = Inf;
philips.pardef.MRSeriesDevelopmentMode.group           = hex2dec('2005');
philips.pardef.MRSeriesDevelopmentMode.element         = hex2dec('1013');
philips.pardef.MRSeriesDevelopmentMode.type            = 'STRING';
philips.pardef.MRSeriesDevelopmentMode.dicom_sq        = 'series';
philips.pardef.MRSeriesDevelopmentMode.default         = 'UNKNOWN_DEVELOPMENT_MODE';

% Extra Useful 10
philips.pardef.MagneticFieldStrength.par_definition  = '';
philips.pardef.MagneticFieldStrength.par_print       = '%.1f';
philips.pardef.MagneticFieldStrength.format_func     = 'format_str2num';
philips.pardef.MagneticFieldStrength.par_min_version = 0;
philips.pardef.MagneticFieldStrength.par_max_version = Inf;
philips.pardef.MagneticFieldStrength.group           = hex2dec('0018');
philips.pardef.MagneticFieldStrength.element         = hex2dec('0087');
philips.pardef.MagneticFieldStrength.type            = 'DOUBLE';
philips.pardef.MagneticFieldStrength.dicom_sq        = 'series';
philips.pardef.MagneticFieldStrength.default         = 'UNKNOWN_MAGNETIC_FIELD_STRENGTH';

% Extra Useful 11
philips.pardef.DeviceSerialNumber.par_definition  = '';
philips.pardef.DeviceSerialNumber.par_print       = '%s';
philips.pardef.DeviceSerialNumber.format_func     = 'format_str2str';
philips.pardef.DeviceSerialNumber.par_min_version = 0;
philips.pardef.DeviceSerialNumber.par_max_version = Inf;
philips.pardef.DeviceSerialNumber.group           = hex2dec('0018');
philips.pardef.DeviceSerialNumber.element         = hex2dec('1000');
philips.pardef.DeviceSerialNumber.type            = 'STRING';
philips.pardef.DeviceSerialNumber.dicom_sq        = 'series';
philips.pardef.DeviceSerialNumber.default         = 'UNKNOWN_DEVICE_SERIAL_NUMBER';

% Extra Useful 12
philips.pardef.InstitutionName.par_definition  = '';
philips.pardef.InstitutionName.par_print       = '%s';
philips.pardef.InstitutionName.format_func     = 'format_str2str';
philips.pardef.InstitutionName.par_min_version = 0;
philips.pardef.InstitutionName.par_max_version = Inf;
philips.pardef.InstitutionName.group           = hex2dec('0008');
philips.pardef.InstitutionName.element         = hex2dec('0080');
philips.pardef.InstitutionName.type            = 'STRING';
philips.pardef.InstitutionName.dicom_sq        = 'series';
philips.pardef.InstitutionName.default         = 'UNKNOWN_INSTITUTION_NAME';

% Extra Useful 13
philips.pardef.ExaminationStationAETitle.par_definition  = '';
philips.pardef.ExaminationStationAETitle.par_print       = '%s';
philips.pardef.ExaminationStationAETitle.format_func     = 'format_str2str';
philips.pardef.ExaminationStationAETitle.par_min_version = 0;
philips.pardef.ExaminationStationAETitle.par_max_version = Inf;
philips.pardef.ExaminationStationAETitle.group           = hex2dec('0040');
philips.pardef.ExaminationStationAETitle.element         = hex2dec('0241');
philips.pardef.ExaminationStationAETitle.type            = 'STRING';
philips.pardef.ExaminationStationAETitle.dicom_sq        = 'series';
philips.pardef.ExaminationStationAETitle.default         = 'UNKNOWN_AE_TITLE';

% Extra Useful 14
philips.pardef.ExaminationStationName.par_definition  = '';
philips.pardef.ExaminationStationName.par_print       = '%s';
philips.pardef.ExaminationStationName.format_func     = 'format_str2str';
philips.pardef.ExaminationStationName.par_min_version = 0;
philips.pardef.ExaminationStationName.par_max_version = Inf;
philips.pardef.ExaminationStationName.group           = hex2dec('0040');
philips.pardef.ExaminationStationName.element         = hex2dec('0242');
philips.pardef.ExaminationStationName.type            = 'STRING';
philips.pardef.ExaminationStationName.dicom_sq        = 'series';
philips.pardef.ExaminationStationName.default         = 'UNKNOWN_STATION_NAME';

% Extra Useful 15
philips.pardef.SeriesDateTime.par_definition  = '';
philips.pardef.SeriesDateTime.par_print       = '%s';
philips.pardef.SeriesDateTime.format_func     = 'format_date_time';
philips.pardef.SeriesDateTime.par_min_version = 3;
philips.pardef.SeriesDateTime.par_max_version = Inf;
philips.pardef.SeriesDateTime.group           = hex2dec('0008');
philips.pardef.SeriesDateTime.element         = hex2dec({'0021','0031'});
philips.pardef.SeriesDateTime.type            = {'DATE','TIME'};
philips.pardef.SeriesDateTime.dicom_sq        = 'series'; 
philips.pardef.SeriesDateTime.default         = 'UNKNOWN_SERIES_DATE_TIME';

%% Philips image definition DICOM entries
% Order of declaration below reflects the order in the Philips PAR header file

% 01a
philips.imgdef.ImagePlaneNumberV3toV4.image_key       = 'sl';
philips.imgdef.ImagePlaneNumberV3toV4.par_definition  = '#  slice number                             (integer)';
philips.imgdef.ImagePlaneNumberV3toV4.par_print       = '%2d';
philips.imgdef.ImagePlaneNumberV3toV4.par_min_version = 3;
philips.imgdef.ImagePlaneNumberV3toV4.par_max_version = 4;
philips.imgdef.ImagePlaneNumberV3toV4.group           = hex2dec('2001');
philips.imgdef.ImagePlaneNumberV3toV4.element         = hex2dec('100A');
philips.imgdef.ImagePlaneNumberV3toV4.type            = 'INTEGER';
philips.imgdef.ImagePlaneNumberV3toV4.dicom_sq        = 'frame'; 

% 01b
philips.imgdef.ImagePlaneNumber.image_key       = 'sl';
philips.imgdef.ImagePlaneNumber.par_definition  = '#  slice number                             (integer)';
philips.imgdef.ImagePlaneNumber.par_print       = ' %2d';
philips.imgdef.ImagePlaneNumber.par_min_version = 4.1;
philips.imgdef.ImagePlaneNumber.par_max_version = Inf;
philips.imgdef.ImagePlaneNumber.group           = hex2dec('2001');
philips.imgdef.ImagePlaneNumber.element         = hex2dec('100A');
philips.imgdef.ImagePlaneNumber.type            = 'INTEGER';
philips.imgdef.ImagePlaneNumber.dicom_sq        = 'frame'; 

% 02a
philips.imgdef.MRImageEchoNumberV3toV4.image_key       = 'ec';
philips.imgdef.MRImageEchoNumberV3toV4.par_definition  = '#  echo number                              (integer)';
philips.imgdef.MRImageEchoNumberV3toV4.par_print       = ' %2d';
philips.imgdef.MRImageEchoNumberV3toV4.par_min_version = 3;
philips.imgdef.MRImageEchoNumberV3toV4.par_max_version = 4;
philips.imgdef.MRImageEchoNumberV3toV4.group           = hex2dec('0018');
philips.imgdef.MRImageEchoNumberV3toV4.element         = hex2dec('0086');
philips.imgdef.MRImageEchoNumberV3toV4.type            = 'INTEGER';
philips.imgdef.MRImageEchoNumberV3toV4.dicom_sq        = 'frame'; 

% 02b
philips.imgdef.MRImageEchoNumber.image_key       = 'ec';
philips.imgdef.MRImageEchoNumber.par_definition  = '#  echo number                              (integer)';
philips.imgdef.MRImageEchoNumber.par_print       = ' %3d';
philips.imgdef.MRImageEchoNumber.par_min_version = 4.1;
philips.imgdef.MRImageEchoNumber.par_max_version = Inf;
philips.imgdef.MRImageEchoNumber.group           = hex2dec('0018');
philips.imgdef.MRImageEchoNumber.element         = hex2dec('0086');
philips.imgdef.MRImageEchoNumber.type            = 'INTEGER';
philips.imgdef.MRImageEchoNumber.dicom_sq        = 'frame'; 

% 03a
philips.imgdef.MRImageTempPositionIdentifierV3toV4.image_key       = 'dyn';
philips.imgdef.MRImageTempPositionIdentifierV3toV4.par_definition  = '#  dynamic scan number                      (integer)';
philips.imgdef.MRImageTempPositionIdentifierV3toV4.par_print       = ' %3d';
philips.imgdef.MRImageTempPositionIdentifierV3toV4.par_min_version = 3;
philips.imgdef.MRImageTempPositionIdentifierV3toV4.par_max_version = 4;
philips.imgdef.MRImageTempPositionIdentifierV3toV4.group           = hex2dec('0020');
philips.imgdef.MRImageTempPositionIdentifierV3toV4.element         = hex2dec('0100');
philips.imgdef.MRImageTempPositionIdentifierV3toV4.type            = 'INTEGER';
philips.imgdef.MRImageTempPositionIdentifierV3toV4.dicom_sq        = 'frame'; 

% 03b
philips.imgdef.MRImageTempPositionIdentifier.image_key       = 'dyn';
philips.imgdef.MRImageTempPositionIdentifier.par_definition  = '#  dynamic scan number                      (integer)';
philips.imgdef.MRImageTempPositionIdentifier.par_print       = ' %4d';
philips.imgdef.MRImageTempPositionIdentifier.par_min_version = 4.1;
philips.imgdef.MRImageTempPositionIdentifier.par_max_version = Inf;
philips.imgdef.MRImageTempPositionIdentifier.group           = hex2dec('0020');
philips.imgdef.MRImageTempPositionIdentifier.element         = hex2dec('0100');
philips.imgdef.MRImageTempPositionIdentifier.type            = 'INTEGER';
philips.imgdef.MRImageTempPositionIdentifier.dicom_sq        = 'frame'; 

% 04
philips.imgdef.MRImagePhaseNumber.image_key       = 'ph';
philips.imgdef.MRImagePhaseNumber.par_definition  = '#  cardiac phase number                     (integer)';
philips.imgdef.MRImagePhaseNumber.par_print       = ' %2d';
philips.imgdef.MRImagePhaseNumber.par_min_version = 3;
philips.imgdef.MRImagePhaseNumber.par_max_version = Inf;
philips.imgdef.MRImagePhaseNumber.group           = hex2dec('2001');
philips.imgdef.MRImagePhaseNumber.element         = hex2dec('1008');
philips.imgdef.MRImagePhaseNumber.type            = 'INTEGER';
philips.imgdef.MRImagePhaseNumber.dicom_sq        = 'frame'; 

% 05
philips.imgdef.MRImageTypeMR.image_key       = 'ty';
philips.imgdef.MRImageTypeMR.par_definition  = '#  image_type_mr                            (integer)';
philips.imgdef.MRImageTypeMR.par_print       = ' %d';
philips.imgdef.MRImageTypeMR.par_min_version = 3;
philips.imgdef.MRImageTypeMR.par_max_version = Inf;
philips.imgdef.MRImageTypeMR.group           = hex2dec('2005');
philips.imgdef.MRImageTypeMR.element         = hex2dec('1011');
philips.imgdef.MRImageTypeMR.type            = 'ENUM';
philips.imgdef.MRImageTypeMR.enum            = { ...
    'M','R','I','P','CR','T0','T1','T2', 'RHO','SPECTRO','DERIVED', ...
    'ADC','RCBV','RCBF','MTT','TTP','FA','EADC','B0','DELAY','MAXRELENH',...
    'RELENH','MAXENH','WASHIN','WASHOUT','BREVENH','AREACURV','ANATOMIC'};
philips.imgdef.MRImageTypeMR.dicom_sq        = 'frame'; 

% 06
philips.imgdef.MRImageScanningSequencePrivate.image_key       = 'seq';
philips.imgdef.MRImageScanningSequencePrivate.par_definition  = '#  scanning sequence                        (integer)';
philips.imgdef.MRImageScanningSequencePrivate.par_print       = ' %d';
philips.imgdef.MRImageScanningSequencePrivate.par_min_version = 3;
philips.imgdef.MRImageScanningSequencePrivate.par_max_version = Inf;
philips.imgdef.MRImageScanningSequencePrivate.group           = hex2dec('2005');
philips.imgdef.MRImageScanningSequencePrivate.element         = hex2dec('106E');
philips.imgdef.MRImageScanningSequencePrivate.type            = 'ENUM';
philips.imgdef.MRImageScanningSequencePrivate.enum            = {'IR','SE','FFE','DERIVED','PCA','UNSPECIFIED','SPECTRO','SI'};
philips.imgdef.MRImageScanningSequencePrivate.dicom_sq        = 'frame'; 

% 07a - special, altered by selective data loading
philips.imgdef.InstanceNumberV3toV4.par_definition  = '#  index in REC file (in images)            (integer)';
philips.imgdef.InstanceNumberV3toV4.par_print       = ' %3d';
philips.imgdef.InstanceNumberV3toV4.par_min_version = 3;
philips.imgdef.InstanceNumberV3toV4.par_max_version = 4;
philips.imgdef.InstanceNumberV3toV4.group           = hex2dec('0020');
philips.imgdef.InstanceNumberV3toV4.element         = hex2dec('0013');
philips.imgdef.InstanceNumberV3toV4.type            = 'INTEGER';
philips.imgdef.InstanceNumberV3toV4.dicom_sq        = 'frame'; 

% 07b - special, altered by selective data loading
philips.imgdef.InstanceNumber.par_definition  = '#  index in REC file (in images)            (integer)';
philips.imgdef.InstanceNumber.par_print       = ' %5d';
philips.imgdef.InstanceNumber.format_func     = 'format_index_in_REC_file';
philips.imgdef.InstanceNumber.par_min_version = 4.1;
philips.imgdef.InstanceNumber.par_max_version = Inf;
philips.imgdef.InstanceNumber.group           = hex2dec('0020');
philips.imgdef.InstanceNumber.element         = hex2dec('0013');
philips.imgdef.InstanceNumber.type            = 'INTEGER';
philips.imgdef.InstanceNumber.dicom_sq        = 'frame'; 

% 08a
philips.imgdef.BitsAllocatedV4.par_definition  = '#  image pixel size (in bits)               (integer)';
philips.imgdef.BitsAllocatedV4.par_print       = ' %2d';
philips.imgdef.BitsAllocatedV4.par_min_version = 4;
philips.imgdef.BitsAllocatedV4.par_max_version = 4;
philips.imgdef.BitsAllocatedV4.group           = hex2dec('0028');
philips.imgdef.BitsAllocatedV4.element         = hex2dec('0100');
philips.imgdef.BitsAllocatedV4.type            = 'USHORT';
philips.imgdef.BitsAllocatedV4.dicom_sq        = 'series'; 

% 08b
philips.imgdef.BitsAllocated.par_definition  = '#  image pixel size (in bits)               (integer)';
philips.imgdef.BitsAllocated.par_print       = ' %3d';
philips.imgdef.BitsAllocated.par_min_version = 4.1;
philips.imgdef.BitsAllocated.par_max_version = Inf;
philips.imgdef.BitsAllocated.group           = hex2dec('0028');
philips.imgdef.BitsAllocated.element         = hex2dec('0100');
philips.imgdef.BitsAllocated.type            = 'USHORT';
philips.imgdef.BitsAllocated.dicom_sq        = 'series'; 

% 09a
philips.imgdef.MRImagePercentSamplingV4.par_definition  = '#  scan percentage                          (integer)';
philips.imgdef.MRImagePercentSamplingV4.par_print       = ' %.0f';
philips.imgdef.MRImagePercentSamplingV4.par_min_version = 4;
philips.imgdef.MRImagePercentSamplingV4.par_max_version = 4;
philips.imgdef.MRImagePercentSamplingV4.group           = hex2dec('0018');
philips.imgdef.MRImagePercentSamplingV4.element         = hex2dec('0093');
philips.imgdef.MRImagePercentSamplingV4.type            = 'DOUBLE';
philips.imgdef.MRImagePercentSamplingV4.dicom_sq        = 'frame'; 

% 09b
philips.imgdef.MRImagePercentSampling.par_definition  = '#  scan percentage                          (integer)';
philips.imgdef.MRImagePercentSampling.par_print       = ' %5.0f';
philips.imgdef.MRImagePercentSampling.par_min_version = 4.1;
philips.imgdef.MRImagePercentSampling.par_max_version = Inf;
philips.imgdef.MRImagePercentSampling.group           = hex2dec('0018');
philips.imgdef.MRImagePercentSampling.element         = hex2dec('0093');
philips.imgdef.MRImagePercentSampling.type            = 'DOUBLE';
philips.imgdef.MRImagePercentSampling.dicom_sq        = 'frame'; 

% 10,11 a
philips.imgdef.ImageRowsColumnsV4.par_definition  = '#  recon resolution (x y)                   (2*integer)';
philips.imgdef.ImageRowsColumnsV4.par_print       = '  %d %d';
philips.imgdef.ImageRowsColumnsV4.par_min_version = 4;
philips.imgdef.ImageRowsColumnsV4.par_max_version = 4;
philips.imgdef.ImageRowsColumnsV4.group           = hex2dec('0028');
philips.imgdef.ImageRowsColumnsV4.element         = hex2dec({'0010','0011'});
philips.imgdef.ImageRowsColumnsV4.type            = {'USHORT','USHORT'};
philips.imgdef.ImageRowsColumnsV4.dicom_sq        = 'series'; 
philips.imgdef.ImageRowsColumnsV4.default         = [0 0]; 

% 10,11 b
philips.imgdef.ImageRowsColumns.par_definition  = '#  recon resolution (x y)                   (2*integer)';
philips.imgdef.ImageRowsColumns.par_print       = ' %4d %4d';
philips.imgdef.ImageRowsColumns.par_min_version = 4.1;
philips.imgdef.ImageRowsColumns.par_max_version = Inf;
philips.imgdef.ImageRowsColumns.group           = hex2dec('0028');
philips.imgdef.ImageRowsColumns.element         = hex2dec({'0010','0011'});
philips.imgdef.ImageRowsColumns.type            = {'USHORT','USHORT'};
philips.imgdef.ImageRowsColumns.dicom_sq        = 'series'; 
philips.imgdef.ImageRowsColumns.default         = [0 0]; 

% 12a
philips.imgdef.RescaleInterceptV3.par_definition  = '#  rescale intercept                        (float)';
philips.imgdef.RescaleInterceptV3.par_print       = ' %4.1f';
philips.imgdef.RescaleInterceptV3.par_min_version = 3;
philips.imgdef.RescaleInterceptV3.par_max_version = 3;
philips.imgdef.RescaleInterceptV3.group           = hex2dec('0028');
philips.imgdef.RescaleInterceptV3.element         = hex2dec('1052');
philips.imgdef.RescaleInterceptV3.type            = 'DOUBLE';
philips.imgdef.RescaleInterceptV3.dicom_sq        = 'frame'; 

% 12b
philips.imgdef.RescaleInterceptV4.par_definition  = '#  rescale intercept                        (float)';
philips.imgdef.RescaleInterceptV4.par_print       = ' %6.1f';
philips.imgdef.RescaleInterceptV4.par_min_version = 4;
philips.imgdef.RescaleInterceptV4.par_max_version = 4;
philips.imgdef.RescaleInterceptV4.group           = hex2dec('0028');
philips.imgdef.RescaleInterceptV4.element         = hex2dec('1052');
philips.imgdef.RescaleInterceptV4.type            = 'DOUBLE';
philips.imgdef.RescaleInterceptV4.dicom_sq        = 'frame'; 

% 12c
philips.imgdef.RescaleInterceptV41.par_definition  = '#  rescale intercept                        (float)';
philips.imgdef.RescaleInterceptV41.par_print       = ' %9.5f';
philips.imgdef.RescaleInterceptV41.par_min_version = 4.1;
philips.imgdef.RescaleInterceptV41.par_max_version = 4.1;
philips.imgdef.RescaleInterceptV41.group           = hex2dec('0028');
philips.imgdef.RescaleInterceptV41.element         = hex2dec('1052');
philips.imgdef.RescaleInterceptV41.type            = 'DOUBLE';
philips.imgdef.RescaleInterceptV41.dicom_sq        = 'frame'; 

% 12d
philips.imgdef.RescaleIntercept.par_definition  = '#  rescale intercept                        (float)';
philips.imgdef.RescaleIntercept.par_print       = ' %11.5f';
philips.imgdef.RescaleIntercept.par_min_version = 4.2;
philips.imgdef.RescaleIntercept.par_max_version = Inf;
philips.imgdef.RescaleIntercept.group           = hex2dec('0028');
philips.imgdef.RescaleIntercept.element         = hex2dec('1052');
philips.imgdef.RescaleIntercept.type            = 'DOUBLE';
philips.imgdef.RescaleIntercept.dicom_sq        = 'frame'; 

% 13a
philips.imgdef.RescaleSlopeV3.par_definition  = '#  rescale slope                            (float)';
philips.imgdef.RescaleSlopeV3.par_print       = ' %5.3f';
philips.imgdef.RescaleSlopeV3.par_min_version = 3;
philips.imgdef.RescaleSlopeV3.par_max_version = 3;
philips.imgdef.RescaleSlopeV3.group           = hex2dec('0028');
philips.imgdef.RescaleSlopeV3.element         = hex2dec('1053');
philips.imgdef.RescaleSlopeV3.type            = 'DOUBLE';
philips.imgdef.RescaleSlopeV3.dicom_sq        = 'frame'; 

% 13b
philips.imgdef.RescaleSlopeV4.par_definition  = '#  rescale slope                            (float)';
philips.imgdef.RescaleSlopeV4.par_print       = ' %6.3f';
philips.imgdef.RescaleSlopeV4.par_min_version = 4;
philips.imgdef.RescaleSlopeV4.par_max_version = 4;
philips.imgdef.RescaleSlopeV4.group           = hex2dec('0028');
philips.imgdef.RescaleSlopeV4.element         = hex2dec('1053');
philips.imgdef.RescaleSlopeV4.type            = 'DOUBLE';
philips.imgdef.RescaleSlopeV4.dicom_sq        = 'frame'; 

% 13b
philips.imgdef.RescaleSlope.par_definition  = '#  rescale slope                            (float)';
philips.imgdef.RescaleSlope.par_print       = ' %9.5f';
philips.imgdef.RescaleSlope.par_min_version = 4.1;
philips.imgdef.RescaleSlope.par_max_version = Inf;
philips.imgdef.RescaleSlope.group           = hex2dec('0028');
philips.imgdef.RescaleSlope.element         = hex2dec('1053');
philips.imgdef.RescaleSlope.type            = 'DOUBLE';
philips.imgdef.RescaleSlope.dicom_sq        = 'frame'; 

% 14a
philips.imgdef.MRScaleSlopeV3toV4.par_definition  = '#  scale slope                              (float)';
philips.imgdef.MRScaleSlopeV3toV4.par_print       = ' %10.3e';
philips.imgdef.MRScaleSlopeV3toV4.par_min_version = 3;
philips.imgdef.MRScaleSlopeV3toV4.par_max_version = 4;
philips.imgdef.MRScaleSlopeV3toV4.group           = hex2dec('2005');
philips.imgdef.MRScaleSlopeV3toV4.element         = hex2dec('100E');
philips.imgdef.MRScaleSlopeV3toV4.type            = 'FLOAT';
philips.imgdef.MRScaleSlopeV3toV4.dicom_sq        = 'frame'; 

% 14b
philips.imgdef.MRScaleSlope.par_definition  = '#  scale slope                              (float)';
philips.imgdef.MRScaleSlope.par_print       = ' %12.5e';
philips.imgdef.MRScaleSlope.par_min_version = 4.1;
philips.imgdef.MRScaleSlope.par_max_version = Inf;
philips.imgdef.MRScaleSlope.group           = hex2dec('2005');
philips.imgdef.MRScaleSlope.element         = hex2dec('100E');
philips.imgdef.MRScaleSlope.type            = 'FLOAT';
philips.imgdef.MRScaleSlope.dicom_sq        = 'frame'; 

% 15a
philips.imgdef.WindowCenterV3.par_definition  = '#  window center                            (integer)';
philips.imgdef.WindowCenterV3.par_print       = ' %4.0f';
philips.imgdef.WindowCenterV3.par_min_version = 3;
philips.imgdef.WindowCenterV3.par_max_version = 3;
philips.imgdef.WindowCenterV3.group           = hex2dec('0028');
philips.imgdef.WindowCenterV3.element         = hex2dec('1050');
philips.imgdef.WindowCenterV3.type            = 'DOUBLE';
philips.imgdef.WindowCenterV3.dicom_sq        = 'frame'; 

% 15b
philips.imgdef.WindowCenter.par_definition  = '#  window center                            (integer)';
philips.imgdef.WindowCenter.par_print       = ' %5.0f';
philips.imgdef.WindowCenter.par_min_version = 4;
philips.imgdef.WindowCenter.par_max_version = Inf;
philips.imgdef.WindowCenter.group           = hex2dec('0028');
philips.imgdef.WindowCenter.element         = hex2dec('1050');
philips.imgdef.WindowCenter.type            = 'DOUBLE';
philips.imgdef.WindowCenter.dicom_sq        = 'frame'; 

% 16
philips.imgdef.WindowWidth.par_definition  = '#  window width                             (integer)';
philips.imgdef.WindowWidth.par_print       = ' %5.0f';
philips.imgdef.WindowWidth.par_min_version = 3;
philips.imgdef.WindowWidth.par_max_version = Inf;
philips.imgdef.WindowWidth.group           = hex2dec('0028');
philips.imgdef.WindowWidth.element         = hex2dec('1051');
philips.imgdef.WindowWidth.type            = 'DOUBLE';
philips.imgdef.WindowWidth.dicom_sq        = 'frame'; 

% 17,18,19 a
philips.imgdef.MRStackAngulationV3toV4.par_definition  = '#  image angulation (ap,fh,rl in degrees )  (3*float)';
philips.imgdef.MRStackAngulationV3toV4.par_print       = ' %5.1f %5.1f %5.1f';
philips.imgdef.MRStackAngulationV3toV4.par_min_version = 3;
philips.imgdef.MRStackAngulationV3toV4.par_max_version = 4;
philips.imgdef.MRStackAngulationV3toV4.group           = hex2dec('2005');
philips.imgdef.MRStackAngulationV3toV4.element         = hex2dec({'1071','1072','1073'});
philips.imgdef.MRStackAngulationV3toV4.type            = 'DOUBLE';
philips.imgdef.MRStackAngulationV3toV4.dicom_sq        = 'stack'; 
philips.imgdef.MRStackAngulationV3toV4.default         = [0 0 0];

% 17,18,19 b
philips.imgdef.MRStackAngulation.par_definition  = '#  image angulation (ap,fh,rl in degrees )  (3*float)';
philips.imgdef.MRStackAngulation.par_print       = ' %6.2f %6.2f %6.2f';
philips.imgdef.MRStackAngulation.par_min_version = 4.1;
philips.imgdef.MRStackAngulation.par_max_version = Inf;
philips.imgdef.MRStackAngulation.group           = hex2dec('2005');
philips.imgdef.MRStackAngulation.element         = hex2dec({'1071','1072','1073'});
philips.imgdef.MRStackAngulation.type            = 'DOUBLE';
philips.imgdef.MRStackAngulation.dicom_sq        = 'stack'; 
philips.imgdef.MRStackAngulation.default         = [0 0 0];

% 20,21,22 a
philips.imgdef.ImagePlanePositionPatientV3toV4.par_definition  = '#  image offcentre (ap,fh,rl in mm )        (3*float)';
philips.imgdef.ImagePlanePositionPatientV3toV4.par_print       = ' %6.1f %6.1f %6.1f';
philips.imgdef.ImagePlanePositionPatientV3toV4.format_func     = 'format_slashed_to_num';
philips.imgdef.ImagePlanePositionPatientV3toV4.par_min_version = 3;
philips.imgdef.ImagePlanePositionPatientV3toV4.par_max_version = 4;
philips.imgdef.ImagePlanePositionPatientV3toV4.group           = hex2dec('0020');
philips.imgdef.ImagePlanePositionPatientV3toV4.element         = hex2dec('0032');
philips.imgdef.ImagePlanePositionPatientV3toV4.type            = 'DOUBLE';
philips.imgdef.ImagePlanePositionPatientV3toV4.size            = 3;
philips.imgdef.ImagePlanePositionPatientV3toV4.dicom_sq        = 'frame'; 
philips.imgdef.ImagePlanePositionPatientV3toV4.default         = [0 0 0]; 

% 20,21,22 b
philips.imgdef.ImagePlanePositionPatient.par_definition  = '#  image offcentre (ap,fh,rl in mm )        (3*float)';
philips.imgdef.ImagePlanePositionPatient.par_print       = ' %7.2f %7.2f %7.2f';
philips.imgdef.ImagePlanePositionPatient.format_func     = 'format_slashed_to_num';
philips.imgdef.ImagePlanePositionPatient.par_min_version = 4.1;
philips.imgdef.ImagePlanePositionPatient.par_max_version = Inf;
philips.imgdef.ImagePlanePositionPatient.group           = hex2dec('0020');
philips.imgdef.ImagePlanePositionPatient.element         = hex2dec('0032');
philips.imgdef.ImagePlanePositionPatient.type            = 'DOUBLE';
philips.imgdef.ImagePlanePositionPatient.size            = 3;
philips.imgdef.ImagePlanePositionPatient.dicom_sq        = 'frame'; 
philips.imgdef.ImagePlanePositionPatient.default         = [0 0 0]; 

% 23a
philips.imgdef.ImagePlaneSliceThicknessV4.par_definition  = '#  slice thickness (in mm )                 (float)';
philips.imgdef.ImagePlaneSliceThicknessV4.par_print       = ' %4.1f';
philips.imgdef.ImagePlaneSliceThicknessV4.par_min_version = 4;
philips.imgdef.ImagePlaneSliceThicknessV4.par_max_version = 4;
philips.imgdef.ImagePlaneSliceThicknessV4.group           = hex2dec('0018');
philips.imgdef.ImagePlaneSliceThicknessV4.element         = hex2dec('0050');
philips.imgdef.ImagePlaneSliceThicknessV4.type            = 'DOUBLE';
philips.imgdef.ImagePlaneSliceThicknessV4.dicom_sq        = 'frame'; 

% 23b
philips.imgdef.ImagePlaneSliceThickness.par_definition  = '#  slice thickness (in mm )                 (float)';
philips.imgdef.ImagePlaneSliceThickness.par_print       = ' %6.3f';
philips.imgdef.ImagePlaneSliceThickness.par_min_version = 4.1;
philips.imgdef.ImagePlaneSliceThickness.par_max_version = Inf;
philips.imgdef.ImagePlaneSliceThickness.group           = hex2dec('0018');
philips.imgdef.ImagePlaneSliceThickness.element         = hex2dec('0050');
philips.imgdef.ImagePlaneSliceThickness.type            = 'DOUBLE';
philips.imgdef.ImagePlaneSliceThickness.dicom_sq        = 'frame'; 

% 24a
philips.imgdef.MRImageSpacingBetweenSlicesV4.par_definition  = '#  slice gap (in mm )                       (float)';
philips.imgdef.MRImageSpacingBetweenSlicesV4.par_print       = ' %.1f ';
philips.imgdef.MRImageSpacingBetweenSlicesV4.format_func     = 'format_slice_gap';
philips.imgdef.MRImageSpacingBetweenSlicesV4.par_min_version = 4;
philips.imgdef.MRImageSpacingBetweenSlicesV4.par_max_version = 4;
philips.imgdef.MRImageSpacingBetweenSlicesV4.group           = hex2dec('0018');
philips.imgdef.MRImageSpacingBetweenSlicesV4.element         = hex2dec('0088');
philips.imgdef.MRImageSpacingBetweenSlicesV4.type            = 'DOUBLE';
philips.imgdef.MRImageSpacingBetweenSlicesV4.dicom_sq        = 'frame'; 

% 24b
philips.imgdef.MRImageSpacingBetweenSlices.par_definition  = '#  slice gap (in mm )                       (float)';
philips.imgdef.MRImageSpacingBetweenSlices.par_print       = ' %6.3f';
philips.imgdef.MRImageSpacingBetweenSlices.format_func     = 'format_slice_gap';
philips.imgdef.MRImageSpacingBetweenSlices.par_min_version = 4.1;
philips.imgdef.MRImageSpacingBetweenSlices.par_max_version = Inf;
philips.imgdef.MRImageSpacingBetweenSlices.group           = hex2dec('0018');
philips.imgdef.MRImageSpacingBetweenSlices.element         = hex2dec('0088');
philips.imgdef.MRImageSpacingBetweenSlices.type            = 'DOUBLE';
philips.imgdef.MRImageSpacingBetweenSlices.dicom_sq        = 'frame'; 

% 25
philips.imgdef.MRImageDisplayOrientation.par_definition  = '#  image_display_orientation                (integer)';
philips.imgdef.MRImageDisplayOrientation.par_print       = ' %d';
philips.imgdef.MRImageDisplayOrientation.par_min_version = 3;
philips.imgdef.MRImageDisplayOrientation.par_max_version = Inf;
philips.imgdef.MRImageDisplayOrientation.group           = hex2dec('2005');
philips.imgdef.MRImageDisplayOrientation.element         = hex2dec('1004');
philips.imgdef.MRImageDisplayOrientation.type            = 'ENUM';
philips.imgdef.MRImageDisplayOrientation.enum            = {'NONE','RIGHT90','RIGHT180','LEFT90','VM','RIGHT90VM','RIGHT180VM','LEFT90VM'};
philips.imgdef.MRImageDisplayOrientation.dicom_sq        = 'frame'; 

% 26
%
% would like to use
% (2001,100B)	CS	ImagePlaneOrientation	1 
% {'UNDEFINED','TRANSVERSAL','SAGITTAL','CORONAL'}
% but it is empty
%
philips.imgdef.MRStackViewAxis.par_definition  = '#  slice orientation ( TRA/SAG/COR )        (integer)';
philips.imgdef.MRStackViewAxis.par_print       = ' %d';
philips.imgdef.MRStackViewAxis.format_func     = 'format_stack_view_axis_to_slice_orientation';
philips.imgdef.MRStackViewAxis.par_min_version = 3;
philips.imgdef.MRStackViewAxis.par_max_version = Inf;
philips.imgdef.MRStackViewAxis.group           = hex2dec('2005');
philips.imgdef.MRStackViewAxis.element         = hex2dec('1081');
philips.imgdef.MRStackViewAxis.type            = 'STRING';
philips.imgdef.MRStackViewAxis.dicom_sq        = 'stack'; 
philips.imgdef.MRStackViewAxis.default         = 0;

% 27
philips.imgdef.MRfMRIStatusIndication.par_definition  = '#  fmri_status_indication                   (integer)';
philips.imgdef.MRfMRIStatusIndication.par_print       = ' %d';
philips.imgdef.MRfMRIStatusIndication.par_min_version = 3;
philips.imgdef.MRfMRIStatusIndication.par_max_version = Inf;
philips.imgdef.MRfMRIStatusIndication.group           = hex2dec('2005');
philips.imgdef.MRfMRIStatusIndication.element         = hex2dec('1063');
philips.imgdef.MRfMRIStatusIndication.type            = 'SHORT';
philips.imgdef.MRfMRIStatusIndication.dicom_sq        = 'frame'; 

% 28
philips.imgdef.MRImageTypeEDES.par_definition  = '#  image_type_ed_es  (end diast/end syst)   (integer)';
philips.imgdef.MRImageTypeEDES.par_print       = ' %d';
philips.imgdef.MRImageTypeEDES.par_min_version = 3;
philips.imgdef.MRImageTypeEDES.par_max_version = Inf;
philips.imgdef.MRImageTypeEDES.group           = hex2dec('2001');
philips.imgdef.MRImageTypeEDES.element         = hex2dec('1007');
philips.imgdef.MRImageTypeEDES.type            = 'ENUM';
philips.imgdef.MRImageTypeEDES.enum            = {'ED','ES','U'};
philips.imgdef.MRImageTypeEDES.dicom_sq        = 'frame'; 
philips.imgdef.MRImageTypeEDES.default         = 2;

% 29,30 a
philips.imgdef.ImagePlanePixelSpacingV3.par_definition  = '#  pixel spacing (x,y) (in mm)              (2*float)';
philips.imgdef.ImagePlanePixelSpacingV3.par_print       = ' %4.1f %4.1f';
philips.imgdef.ImagePlanePixelSpacingV3.format_func     = 'format_slashed_to_num';
philips.imgdef.ImagePlanePixelSpacingV3.par_min_version = 3;
philips.imgdef.ImagePlanePixelSpacingV3.par_max_version = 3;
philips.imgdef.ImagePlanePixelSpacingV3.group           = hex2dec('0028');
philips.imgdef.ImagePlanePixelSpacingV3.element         = hex2dec('0030');
philips.imgdef.ImagePlanePixelSpacingV3.type            = 'DOUBLE';
philips.imgdef.ImagePlanePixelSpacingV3.size            = 2;
philips.imgdef.ImagePlanePixelSpacingV3.dicom_sq        = 'frame'; 
philips.imgdef.ImagePlanePixelSpacingV3.default         = [0 0]; 

% 29,30 b
philips.imgdef.ImagePlanePixelSpacingV4.par_definition  = '#  pixel spacing (x,y) (in mm)              (2*float)';
philips.imgdef.ImagePlanePixelSpacingV4.par_print       = '  %5.3f %5.3f';
philips.imgdef.ImagePlanePixelSpacingV4.format_func     = 'format_slashed_to_num';
philips.imgdef.ImagePlanePixelSpacingV4.par_min_version = 4;
philips.imgdef.ImagePlanePixelSpacingV4.par_max_version = 4;
philips.imgdef.ImagePlanePixelSpacingV4.group           = hex2dec('0028');
philips.imgdef.ImagePlanePixelSpacingV4.element         = hex2dec('0030');
philips.imgdef.ImagePlanePixelSpacingV4.type            = 'DOUBLE';
philips.imgdef.ImagePlanePixelSpacingV4.size            = 2;
philips.imgdef.ImagePlanePixelSpacingV4.dicom_sq        = 'frame'; 
philips.imgdef.ImagePlanePixelSpacingV4.default         = [0 0]; 

% 29,30 c
philips.imgdef.ImagePlanePixelSpacing.par_definition  = '#  pixel spacing (x,y) (in mm)              (2*float)';
philips.imgdef.ImagePlanePixelSpacing.par_print       = ' %6.3f %6.3f';
philips.imgdef.ImagePlanePixelSpacing.format_func     = 'format_slashed_to_num';
philips.imgdef.ImagePlanePixelSpacing.par_min_version = 4.1;
philips.imgdef.ImagePlanePixelSpacing.par_max_version = Inf;
philips.imgdef.ImagePlanePixelSpacing.group           = hex2dec('0028');
philips.imgdef.ImagePlanePixelSpacing.element         = hex2dec('0030');
philips.imgdef.ImagePlanePixelSpacing.type            = 'DOUBLE';
philips.imgdef.ImagePlanePixelSpacing.size            = 2;
philips.imgdef.ImagePlanePixelSpacing.dicom_sq        = 'frame'; 
philips.imgdef.ImagePlanePixelSpacing.default         = [0 0]; 

% 31a
philips.imgdef.MRImageEchoTimeV3toV4.par_definition  = '#  echo_time                                (float)';
philips.imgdef.MRImageEchoTimeV3toV4.par_print       = ' %5.1f';
philips.imgdef.MRImageEchoTimeV3toV4.par_min_version = 3;
philips.imgdef.MRImageEchoTimeV3toV4.par_max_version = 4;
philips.imgdef.MRImageEchoTimeV3toV4.group           = hex2dec('0018');
philips.imgdef.MRImageEchoTimeV3toV4.element         = hex2dec('0081');
philips.imgdef.MRImageEchoTimeV3toV4.type            = 'DOUBLE';
philips.imgdef.MRImageEchoTimeV3toV4.dicom_sq        = 'frame'; 

% 31b
philips.imgdef.MRImageEchoTimeV41.par_definition  = '#  echo_time                                (float)';
philips.imgdef.MRImageEchoTimeV41.par_print       = ' %5.2f';
philips.imgdef.MRImageEchoTimeV41.par_min_version = 4.1;
philips.imgdef.MRImageEchoTimeV41.par_max_version = 4.1;
philips.imgdef.MRImageEchoTimeV41.group           = hex2dec('0018');
philips.imgdef.MRImageEchoTimeV41.element         = hex2dec('0081');
philips.imgdef.MRImageEchoTimeV41.type            = 'DOUBLE';
philips.imgdef.MRImageEchoTimeV41.dicom_sq        = 'frame'; 

% 31c
philips.imgdef.MRImageEchoTime.par_definition  = '#  echo_time                                (float)';
philips.imgdef.MRImageEchoTime.par_print       = ' %6.2f';
philips.imgdef.MRImageEchoTime.par_min_version = 4.2;
philips.imgdef.MRImageEchoTime.par_max_version = Inf;
philips.imgdef.MRImageEchoTime.group           = hex2dec('0018');
philips.imgdef.MRImageEchoTime.element         = hex2dec('0081');
philips.imgdef.MRImageEchoTime.type            = 'DOUBLE';
philips.imgdef.MRImageEchoTime.dicom_sq        = 'frame'; 

% 32a
philips.imgdef.MRImageDynamicScanBeginTimeV3toV4.par_definition  = '#  dyn_scan_begin_time                      (float)';
philips.imgdef.MRImageDynamicScanBeginTimeV3toV4.par_print       = ' %5.1f';
philips.imgdef.MRImageDynamicScanBeginTimeV3toV4.par_min_version = 3;
philips.imgdef.MRImageDynamicScanBeginTimeV3toV4.par_max_version = 4;
philips.imgdef.MRImageDynamicScanBeginTimeV3toV4.group           = hex2dec('2005');
philips.imgdef.MRImageDynamicScanBeginTimeV3toV4.element         = hex2dec('10A0');
philips.imgdef.MRImageDynamicScanBeginTimeV3toV4.type            = 'FLOAT';
philips.imgdef.MRImageDynamicScanBeginTimeV3toV4.dicom_sq        = 'frame'; 

% 32b
philips.imgdef.MRImageDynamicScanBeginTime.par_definition  = '#  dyn_scan_begin_time                      (float)';
philips.imgdef.MRImageDynamicScanBeginTime.par_print       = ' %7.2f';
philips.imgdef.MRImageDynamicScanBeginTime.par_min_version = 4.1;
philips.imgdef.MRImageDynamicScanBeginTime.par_max_version = Inf;
philips.imgdef.MRImageDynamicScanBeginTime.group           = hex2dec('2005');
philips.imgdef.MRImageDynamicScanBeginTime.element         = hex2dec('10A0');
philips.imgdef.MRImageDynamicScanBeginTime.type            = 'FLOAT';
philips.imgdef.MRImageDynamicScanBeginTime.dicom_sq        = 'frame'; 

% 33a
philips.imgdef.MRImageTriggerTimeV3.par_definition  = '#  trigger_time                             (float)';
philips.imgdef.MRImageTriggerTimeV3.par_print       = ' %5.0f';
philips.imgdef.MRImageTriggerTimeV3.par_min_version = 3;
philips.imgdef.MRImageTriggerTimeV3.par_max_version = 3;
philips.imgdef.MRImageTriggerTimeV3.group           = hex2dec('0018');
philips.imgdef.MRImageTriggerTimeV3.element         = hex2dec('1060');
philips.imgdef.MRImageTriggerTimeV3.type            = 'DOUBLE';
philips.imgdef.MRImageTriggerTimeV3.dicom_sq        = 'frame'; 

% 33b
philips.imgdef.MRImageTriggerTimeV4.par_definition  = '#  trigger_time                             (float)';
philips.imgdef.MRImageTriggerTimeV4.par_print       = ' %5.1f';
philips.imgdef.MRImageTriggerTimeV4.par_min_version = 4;
philips.imgdef.MRImageTriggerTimeV4.par_max_version = 4;
philips.imgdef.MRImageTriggerTimeV4.group           = hex2dec('0018');
philips.imgdef.MRImageTriggerTimeV4.element         = hex2dec('1060');
philips.imgdef.MRImageTriggerTimeV4.type            = 'DOUBLE';
philips.imgdef.MRImageTriggerTimeV4.dicom_sq        = 'frame'; 

% 33c
philips.imgdef.MRImageTriggerTimeV41.par_definition  = '#  trigger_time                             (float)';
philips.imgdef.MRImageTriggerTimeV41.par_print       = ' %7.2f';
philips.imgdef.MRImageTriggerTimeV41.par_min_version = 4.1;
philips.imgdef.MRImageTriggerTimeV41.par_max_version = 4.1;
philips.imgdef.MRImageTriggerTimeV41.group           = hex2dec('0018');
philips.imgdef.MRImageTriggerTimeV41.element         = hex2dec('1060');
philips.imgdef.MRImageTriggerTimeV41.type            = 'DOUBLE';
philips.imgdef.MRImageTriggerTimeV41.dicom_sq        = 'frame'; 

% 33c
philips.imgdef.MRImageTriggerTime.par_definition  = '#  trigger_time                             (float)';
philips.imgdef.MRImageTriggerTime.par_print       = ' %8.2f';
philips.imgdef.MRImageTriggerTime.par_min_version = 4.2;
philips.imgdef.MRImageTriggerTime.par_max_version = Inf;
philips.imgdef.MRImageTriggerTime.group           = hex2dec('0018');
philips.imgdef.MRImageTriggerTime.element         = hex2dec('1060');
philips.imgdef.MRImageTriggerTime.type            = 'DOUBLE';
philips.imgdef.MRImageTriggerTime.dicom_sq        = 'frame'; 

% 34a
philips.imgdef.MRImageDiffusionBFactorV3.par_definition  = '#  diffusion_b_factor                       (float)';
philips.imgdef.MRImageDiffusionBFactorV3.par_print       = ' %5.0f';
philips.imgdef.MRImageDiffusionBFactorV3.par_min_version = 3;
philips.imgdef.MRImageDiffusionBFactorV3.par_max_version = 3;
philips.imgdef.MRImageDiffusionBFactorV3.group           = hex2dec('2001');
philips.imgdef.MRImageDiffusionBFactorV3.element         = hex2dec('1003');
philips.imgdef.MRImageDiffusionBFactorV3.type            = 'FLOAT';
philips.imgdef.MRImageDiffusionBFactorV3.dicom_sq        = 'frame'; 

% 34b
philips.imgdef.MRImageDiffusionBFactorV4.par_definition  = '#  diffusion_b_factor                       (float)';
philips.imgdef.MRImageDiffusionBFactorV4.par_print       = ' %6.3f ';
philips.imgdef.MRImageDiffusionBFactorV4.par_min_version = 4;
philips.imgdef.MRImageDiffusionBFactorV4.par_max_version = 4;
philips.imgdef.MRImageDiffusionBFactorV4.group           = hex2dec('2001');
philips.imgdef.MRImageDiffusionBFactorV4.element         = hex2dec('1003');
philips.imgdef.MRImageDiffusionBFactorV4.type            = 'FLOAT';
philips.imgdef.MRImageDiffusionBFactorV4.dicom_sq        = 'frame'; 

% 34c
philips.imgdef.MRImageDiffusionBFactor.par_definition  = '#  diffusion_b_factor                       (float)';
philips.imgdef.MRImageDiffusionBFactor.par_print       = ' %7.2f';
philips.imgdef.MRImageDiffusionBFactor.par_min_version = 4.1;
philips.imgdef.MRImageDiffusionBFactor.par_max_version = Inf;
philips.imgdef.MRImageDiffusionBFactor.group           = hex2dec('2001');
philips.imgdef.MRImageDiffusionBFactor.element         = hex2dec('1003');
philips.imgdef.MRImageDiffusionBFactor.type            = 'FLOAT';
philips.imgdef.MRImageDiffusionBFactor.dicom_sq        = 'frame'; 

% 35a
philips.imgdef.MRImageNumberOfAveragesV4.par_definition  = '#  number of averages                       (integer)';
philips.imgdef.MRImageNumberOfAveragesV4.par_print       = ' %d';
philips.imgdef.MRImageNumberOfAveragesV4.par_min_version = 4;
philips.imgdef.MRImageNumberOfAveragesV4.par_max_version = 4;
philips.imgdef.MRImageNumberOfAveragesV4.group           = hex2dec('0018');
philips.imgdef.MRImageNumberOfAveragesV4.element         = hex2dec('0083');
philips.imgdef.MRImageNumberOfAveragesV4.type            = 'DOUBLE';
philips.imgdef.MRImageNumberOfAveragesV4.dicom_sq        = 'frame'; 

% 35b
philips.imgdef.MRImageNumberOfAverages.par_definition  = '#  number of averages                       (integer)';
philips.imgdef.MRImageNumberOfAverages.par_print       = ' %3d';
philips.imgdef.MRImageNumberOfAverages.par_min_version = 4.1;
philips.imgdef.MRImageNumberOfAverages.par_max_version = Inf;
philips.imgdef.MRImageNumberOfAverages.group           = hex2dec('0018');
philips.imgdef.MRImageNumberOfAverages.element         = hex2dec('0083');
philips.imgdef.MRImageNumberOfAverages.type            = 'DOUBLE';
philips.imgdef.MRImageNumberOfAverages.dicom_sq        = 'frame'; 

% 36a
philips.imgdef.MRImageFlipAngleV3toV4.par_definition  = '#  image_flip_angle (in degrees)            (float)';
philips.imgdef.MRImageFlipAngleV3toV4.par_print       = ' %5.1f';
philips.imgdef.MRImageFlipAngleV3toV4.par_min_version = 3;
philips.imgdef.MRImageFlipAngleV3toV4.par_max_version = 4;
philips.imgdef.MRImageFlipAngleV3toV4.group           = hex2dec('0018');
philips.imgdef.MRImageFlipAngleV3toV4.element         = hex2dec('1314');
philips.imgdef.MRImageFlipAngleV3toV4.type            = 'DOUBLE';
philips.imgdef.MRImageFlipAngleV3toV4.dicom_sq        = 'frame'; 

% 36b
philips.imgdef.MRImageFlipAngle.par_definition  = '#  image_flip_angle (in degrees)            (float)';
philips.imgdef.MRImageFlipAngle.par_print       = ' %7.2f';
philips.imgdef.MRImageFlipAngle.par_min_version = 4.1;
philips.imgdef.MRImageFlipAngle.par_max_version = Inf;
philips.imgdef.MRImageFlipAngle.group           = hex2dec('0018');
philips.imgdef.MRImageFlipAngle.element         = hex2dec('1314');
philips.imgdef.MRImageFlipAngle.type            = 'DOUBLE';
philips.imgdef.MRImageFlipAngle.dicom_sq        = 'frame'; 

% 37a
philips.imgdef.MRImageHeartRateV4.par_definition  = '#  cardiac frequency   (bpm)                (integer)';
philips.imgdef.MRImageHeartRateV4.par_print       = ' %3d';
philips.imgdef.MRImageHeartRateV4.par_min_version = 4;
philips.imgdef.MRImageHeartRateV4.par_max_version = 4;
philips.imgdef.MRImageHeartRateV4.group           = hex2dec('0018');
philips.imgdef.MRImageHeartRateV4.element         = hex2dec('1088');
philips.imgdef.MRImageHeartRateV4.type            = 'INTEGER';
philips.imgdef.MRImageHeartRateV4.dicom_sq        = 'frame'; 

% 37b
philips.imgdef.MRImageHeartRate.par_definition  = '#  cardiac frequency   (bpm)                (integer)';
philips.imgdef.MRImageHeartRate.par_print       = ' %5d';
philips.imgdef.MRImageHeartRate.par_min_version = 4.1;
philips.imgdef.MRImageHeartRate.par_max_version = Inf;
philips.imgdef.MRImageHeartRate.group           = hex2dec('0018');
philips.imgdef.MRImageHeartRate.element         = hex2dec('1088');
philips.imgdef.MRImageHeartRate.type            = 'INTEGER';
philips.imgdef.MRImageHeartRate.dicom_sq        = 'frame'; 

% 38
philips.imgdef.MRImageLowRRValue.par_definition  = '#  minimum RR-interval (in ms)              (integer)';
philips.imgdef.MRImageLowRRValue.par_print       = ' %4d';
philips.imgdef.MRImageLowRRValue.par_min_version = 4;
philips.imgdef.MRImageLowRRValue.par_max_version = Inf;
philips.imgdef.MRImageLowRRValue.group           = hex2dec('0018');
philips.imgdef.MRImageLowRRValue.element         = hex2dec('1081');
philips.imgdef.MRImageLowRRValue.type            = 'INTEGER';
philips.imgdef.MRImageLowRRValue.dicom_sq        = 'frame'; 

% 39a
philips.imgdef.MRImageHighRRValueV4.par_definition  = '#  maximum RR-interval (in ms)              (integer)';
philips.imgdef.MRImageHighRRValueV4.par_print       = ' %d';
philips.imgdef.MRImageHighRRValueV4.par_min_version = 4;
philips.imgdef.MRImageHighRRValueV4.par_max_version = 4;
philips.imgdef.MRImageHighRRValueV4.group           = hex2dec('0018');
philips.imgdef.MRImageHighRRValueV4.element         = hex2dec('1082');
philips.imgdef.MRImageHighRRValueV4.type            = 'INTEGER';
philips.imgdef.MRImageHighRRValueV4.dicom_sq        = 'frame'; 

% 39b
philips.imgdef.MRImageHighRRValue.par_definition  = '#  maximum RR-interval (in ms)              (integer)';
philips.imgdef.MRImageHighRRValue.par_print       = ' %4d';
philips.imgdef.MRImageHighRRValue.par_min_version = 4.1;
philips.imgdef.MRImageHighRRValue.par_max_version = Inf;
philips.imgdef.MRImageHighRRValue.group           = hex2dec('0018');
philips.imgdef.MRImageHighRRValue.element         = hex2dec('1082');
philips.imgdef.MRImageHighRRValue.type            = 'INTEGER';
philips.imgdef.MRImageHighRRValue.dicom_sq        = 'frame'; 

% 40a
philips.imgdef.MRImageEchoTrainLengthV4.par_definition  = '#  TURBO factor  <0=no turbo>               (integer)';
philips.imgdef.MRImageEchoTrainLengthV4.par_print       = ' %2d';
philips.imgdef.MRImageEchoTrainLengthV4.par_min_version = 4;
philips.imgdef.MRImageEchoTrainLengthV4.par_max_version = 4;
philips.imgdef.MRImageEchoTrainLengthV4.group           = hex2dec('0018');
philips.imgdef.MRImageEchoTrainLengthV4.element         = hex2dec('0091');
philips.imgdef.MRImageEchoTrainLengthV4.type            = 'INTEGER';
philips.imgdef.MRImageEchoTrainLengthV4.dicom_sq        = 'frame'; 

% 40b
philips.imgdef.MRImageEchoTrainLength.par_definition  = '#  TURBO factor  <0=no turbo>               (integer)';
philips.imgdef.MRImageEchoTrainLength.par_print       = ' %5d';
philips.imgdef.MRImageEchoTrainLength.par_min_version = 4.1;
philips.imgdef.MRImageEchoTrainLength.par_max_version = Inf;
philips.imgdef.MRImageEchoTrainLength.group           = hex2dec('0018');
philips.imgdef.MRImageEchoTrainLength.element         = hex2dec('0091');
philips.imgdef.MRImageEchoTrainLength.type            = 'INTEGER';
philips.imgdef.MRImageEchoTrainLength.dicom_sq        = 'frame'; 

% 41
philips.imgdef.MRPrivateInversionTime.par_definition  = '#  Inversion delay (in ms)                  (float)';
philips.imgdef.MRPrivateInversionTime.par_print       = ' %5.1f';
philips.imgdef.MRPrivateInversionTime.par_min_version = 4;
philips.imgdef.MRPrivateInversionTime.par_max_version = Inf;
philips.imgdef.MRPrivateInversionTime.group           = hex2dec('2005');
philips.imgdef.MRPrivateInversionTime.element         = hex2dec('10A8');
philips.imgdef.MRPrivateInversionTime.type            = 'DOUBLE';
philips.imgdef.MRPrivateInversionTime.dicom_sq        = 'frame'; 

% 42a
philips.imgdef.MRImageDiffBValueNumberV41.image_key       = 'b';
philips.imgdef.MRImageDiffBValueNumberV41.par_definition  = '#  diffusion b value number    (imagekey!)  (integer)';
philips.imgdef.MRImageDiffBValueNumberV41.par_print       = ' %d';
philips.imgdef.MRImageDiffBValueNumberV41.par_min_version = 4.1;
philips.imgdef.MRImageDiffBValueNumberV41.par_max_version = 4.1;
philips.imgdef.MRImageDiffBValueNumberV41.group           = hex2dec('2005');
philips.imgdef.MRImageDiffBValueNumberV41.element         = hex2dec('1412');
philips.imgdef.MRImageDiffBValueNumberV41.type            = 'INTEGER';
philips.imgdef.MRImageDiffBValueNumberV41.dicom_sq        = 'frame'; 
philips.imgdef.MRImageDiffBValueNumberV41.default         = 1; 

% 42b
philips.imgdef.MRImageDiffBValueNumber.image_key       = 'b';
philips.imgdef.MRImageDiffBValueNumber.par_definition  = '#  diffusion b value number    (imagekey!)  (integer)';
philips.imgdef.MRImageDiffBValueNumber.par_print       = ' %2d';
philips.imgdef.MRImageDiffBValueNumber.par_min_version = 4.2;
philips.imgdef.MRImageDiffBValueNumber.par_max_version = Inf;
philips.imgdef.MRImageDiffBValueNumber.group           = hex2dec('2005');
philips.imgdef.MRImageDiffBValueNumber.element         = hex2dec('1412');
philips.imgdef.MRImageDiffBValueNumber.type            = 'INTEGER';
philips.imgdef.MRImageDiffBValueNumber.dicom_sq        = 'frame'; 
philips.imgdef.MRImageDiffBValueNumber.default         = 1; 

% 43a
philips.imgdef.MRImageGradientOrientationNumberV41.image_key       = 'grad';
philips.imgdef.MRImageGradientOrientationNumberV41.par_definition  = '#  gradient orientation number (imagekey!)  (integer)';
philips.imgdef.MRImageGradientOrientationNumberV41.par_print       = ' %4d';
philips.imgdef.MRImageGradientOrientationNumberV41.par_min_version = 4.1;
philips.imgdef.MRImageGradientOrientationNumberV41.par_max_version = 4.1;
philips.imgdef.MRImageGradientOrientationNumberV41.group           = hex2dec('2005');
philips.imgdef.MRImageGradientOrientationNumberV41.element         = hex2dec('1413');
philips.imgdef.MRImageGradientOrientationNumberV41.type            = 'INTEGER';
philips.imgdef.MRImageGradientOrientationNumberV41.dicom_sq        = 'frame'; 
philips.imgdef.MRImageGradientOrientationNumberV41.default         = 1; 

% 43b
philips.imgdef.MRImageGradientOrientationNumber.image_key       = 'grad';
philips.imgdef.MRImageGradientOrientationNumber.par_definition  = '#  gradient orientation number (imagekey!)  (integer)';
philips.imgdef.MRImageGradientOrientationNumber.par_print       = ' %3d';
philips.imgdef.MRImageGradientOrientationNumber.par_min_version = 4.2;
philips.imgdef.MRImageGradientOrientationNumber.par_max_version = Inf;
philips.imgdef.MRImageGradientOrientationNumber.group           = hex2dec('2005');
philips.imgdef.MRImageGradientOrientationNumber.element         = hex2dec('1413');
philips.imgdef.MRImageGradientOrientationNumber.type            = 'INTEGER';
philips.imgdef.MRImageGradientOrientationNumber.dicom_sq        = 'frame'; 
philips.imgdef.MRImageGradientOrientationNumber.default         = 1; 

% 44
philips.imgdef.AcquisitionContrast.par_definition  = '#  contrast type                            (string)';
philips.imgdef.AcquisitionContrast.par_print       = ' %4d';
philips.imgdef.AcquisitionContrast.par_min_version = 4.1;
philips.imgdef.AcquisitionContrast.par_max_version = Inf;
philips.imgdef.AcquisitionContrast.group           = hex2dec('0008');
philips.imgdef.AcquisitionContrast.element         = hex2dec('9209');
philips.imgdef.AcquisitionContrast.type            = 'STRING16';
philips.imgdef.AcquisitionContrast.enum         = { ...
    'DIFFUSION','FLOW_ENCODED','FLUID_ATTENUATED','PERFUSION','PROTON_DENSITY','STIR','TAGGING','T1','T2','T2_STAR','TOF','UNKNOWN','MIXED'};
philips.imgdef.AcquisitionContrast.dicom_sq        = 'frame'; 
philips.imgdef.AcquisitionContrast.default        = 11;

% 45
philips.imgdef.DiffusionAnisotropyType.par_definition  = '#  diffusion anisotropy type                (string)';
philips.imgdef.DiffusionAnisotropyType.par_print       = ' %4d';
philips.imgdef.DiffusionAnisotropyType.par_min_version = 4.1;
philips.imgdef.DiffusionAnisotropyType.par_max_version = Inf;
philips.imgdef.DiffusionAnisotropyType.group           = hex2dec('0018');
philips.imgdef.DiffusionAnisotropyType.element         = hex2dec('9147');
philips.imgdef.DiffusionAnisotropyType.type            = 'STRING16';
philips.imgdef.DiffusionAnisotropyType.dicom_sq        = 'frame'; 
philips.imgdef.DiffusionAnisotropyType.default         = 0; 

% 46,47,48 a
philips.imgdef.MRImageDiffusion_AP_FH_RLV41.par_definition  = '#  diffusion (ap, fh, rl)                   (3*float)';
philips.imgdef.MRImageDiffusion_AP_FH_RLV41.par_print       = ' %8.3f  %8.3f  %8.3f ';
philips.imgdef.MRImageDiffusion_AP_FH_RLV41.par_min_version = 4.1;
philips.imgdef.MRImageDiffusion_AP_FH_RLV41.par_max_version = 4.1;
philips.imgdef.MRImageDiffusion_AP_FH_RLV41.group           = hex2dec('2005');
philips.imgdef.MRImageDiffusion_AP_FH_RLV41.element         = hex2dec({'10B1','10B2','10B0'});
philips.imgdef.MRImageDiffusion_AP_FH_RLV41.type            = {'FLOAT','FLOAT','FLOAT'};
philips.imgdef.MRImageDiffusion_AP_FH_RLV41.dicom_sq        = 'frame'; 
philips.imgdef.MRImageDiffusion_AP_FH_RLV41.default         = [0 0 0]; 

% 46,47,48 b
philips.imgdef.MRImageDiffusion_AP_FH_RL.par_definition  = '#  diffusion (ap, fh, rl)                   (3*float)';
philips.imgdef.MRImageDiffusion_AP_FH_RL.par_print       = ' %7.3f  %7.3f  %7.3f';
philips.imgdef.MRImageDiffusion_AP_FH_RL.par_min_version = 4.2;
philips.imgdef.MRImageDiffusion_AP_FH_RL.par_max_version = Inf;
philips.imgdef.MRImageDiffusion_AP_FH_RL.group           = hex2dec('2005');
philips.imgdef.MRImageDiffusion_AP_FH_RL.element         = hex2dec({'10B1','10B2','10B0'});
philips.imgdef.MRImageDiffusion_AP_FH_RL.type            = {'FLOAT','FLOAT','FLOAT'};
philips.imgdef.MRImageDiffusion_AP_FH_RL.dicom_sq        = 'frame'; 
philips.imgdef.MRImageDiffusion_AP_FH_RL.default         = [0 0 0]; 

% 49
philips.imgdef.MRImageLabelType.image_key       = 'asl';
philips.imgdef.MRImageLabelType.par_definition  = '#  label type (ASL)            (imagekey!)  (integer)';
philips.imgdef.MRImageLabelType.par_print       = ' %2d';
philips.imgdef.MRImageLabelType.par_min_version = 4.2;
philips.imgdef.MRImageLabelType.par_max_version = Inf;
philips.imgdef.MRImageLabelType.group           = hex2dec('2005');
philips.imgdef.MRImageLabelType.element         = hex2dec('1429');
philips.imgdef.MRImageLabelType.type            = 'ENUM';
philips.imgdef.MRImageLabelType.enum            = {'CONTROL','LABEL'};
philips.imgdef.MRImageLabelType.dicom_sq        = 'frame'; 
philips.imgdef.MRImageLabelType.default         = 0; 

%% Philips extra needed/useful parameters available in DICOM
% Extra 01
philips.imgdef.StackID.par_definition  = '';
philips.imgdef.StackID.par_print       = '';
philips.imgdef.StackID.par_min_version = 0;
philips.imgdef.StackID.par_max_version = Inf;
philips.imgdef.StackID.group           = hex2dec('0020');
philips.imgdef.StackID.element         = hex2dec('9056');
philips.imgdef.StackID.type            = 'STRING';
philips.imgdef.StackID.dicom_sq        = 'frame'; 

% Extra 02
philips.imgdef.ImageOrientationPatient.par_definition  = '';
philips.imgdef.ImageOrientationPatient.par_print       = '';
philips.imgdef.ImageOrientationPatient.par_min_version = 0;
philips.imgdef.ImageOrientationPatient.par_max_version = Inf;
philips.imgdef.ImageOrientationPatient.group           = hex2dec('0020');
philips.imgdef.ImageOrientationPatient.element         = hex2dec('0037');
philips.imgdef.ImageOrientationPatient.type            = 'STRING';
philips.imgdef.ImageOrientationPatient.dicom_sq        = 'frame'; 

% Extra 03
% philips.imgdef.MRStackViewAxis.par_definition  = '';
% philips.imgdef.MRStackViewAxis.par_print       = '';
% philips.imgdef.MRStackViewAxis.par_min_version = 0;
% philips.imgdef.MRStackViewAxis.par_max_version = Inf;
% philips.imgdef.MRStackViewAxis.group           = hex2dec('2005');
% philips.imgdef.MRStackViewAxis.element         = hex2dec('1081');
% philips.imgdef.MRStackViewAxis.type            = 'STRING';
% philips.imgdef.MRStackViewAxis.dicom_sq        = 'stack'; 

% Extra 04
% philips.imgdef.MRStackPreparationDirection.par_definition  = '';
% philips.imgdef.MRStackPreparationDirection.par_print       = '';
% philips.imgdef.MRStackPreparationDirection.par_min_version = 0;
% philips.imgdef.MRStackPreparationDirection.par_max_version = Inf;
% philips.imgdef.MRStackPreparationDirection.group           = hex2dec('2005');
% philips.imgdef.MRStackPreparationDirection.element         = hex2dec('107B');
% philips.imgdef.MRStackPreparationDirection.type            = 'STRING';
% philips.imgdef.MRStackPreparationDirection.dicom_sq        = 'stack'; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Define characters to replace in fieldnames
chars_to_replace = {' ','.','(',')',',','-','/','\','[',']'};
replacement_char = '_';

%% Parse PAR defintion strings into pardef_fieldname
pardef_philips_names = fieldnames(philips.pardef);
count_pardef_fieldnames = 0;
for k=1:length(pardef_philips_names),
    pardef_philips_name = pardef_philips_names{k};
    par_definition = philips.pardef.(pardef_philips_name).par_definition;
    toks = regexp(par_definition,'^\.\s+([\w\s\.\(\)\,\-\\\/\[]+\w).*:\s+(.+)$','tokens');
    
    if ~isempty(toks), 
        % fieldname
        pardef_fieldname = char(toks{1}{1});
        
        for n=1:length(chars_to_replace),
            pardef_fieldname = strrep(pardef_fieldname, ...
                chars_to_replace{n},replacement_char);
        end
        pardef_fieldname = regexprep(pardef_fieldname,sprintf('%c+',replacement_char),'_');
        if pardef_fieldname(end)==replacement_char,
            pardef_fieldname = pardef_fieldname(1:end-1);
        end
        
        philips.pardef.(pardef_philips_name).pardef_fieldname = pardef_fieldname;

        count_pardef_fieldnames = count_pardef_fieldnames + 1;
        philips.pardef_fieldnames{count_pardef_fieldnames} = pardef_fieldname;      
    end
    
end

%% Parse image defintion strings into imgdef_fieldname, imgdef_size and imgdef_type
imgdef_philips_names = fieldnames(philips.imgdef);
count_imgdef_fieldnames = 0;
for k=1:length(imgdef_philips_names),
    imgdef_philips_name = imgdef_philips_names{k};
    par_definition = philips.imgdef.(imgdef_philips_name).par_definition;
    toks = regexp(par_definition,'^#\s+([\w\s\.\(\,\-\\\/]+\w).+\((\d)?\*?(integer|float|string)\)$','tokens');
    
    if ~isempty(toks), 
        
        % fieldname
        imgdef_fieldname = char(toks{1}{1});
        
        for n=1:length(chars_to_replace),
            imgdef_fieldname = strrep(imgdef_fieldname, ...
                chars_to_replace{n},replacement_char);
        end
        imgdef_fieldname = regexprep(imgdef_fieldname,sprintf('%c+',replacement_char),'_');
        
        philips.imgdef.(imgdef_philips_name).imgdef_fieldname = imgdef_fieldname;
        
        count_imgdef_fieldnames = count_imgdef_fieldnames + 1;
        philips.imgdef_fieldnames{count_imgdef_fieldnames} = imgdef_fieldname;
        
        % size
        if ~isempty(toks{1}{2}),
            philips.imgdef.(imgdef_philips_name).imgdef_size = str2num(char(toks{1}{2}));
        else
            philips.imgdef.(imgdef_philips_name).imgdef_size = 1;
        end
        
        % type
        philips.imgdef.(imgdef_philips_name).imgdef_type = char(toks{1}{3});
    end
    
    %% detect dimensions
    if isfield( philips.imgdef.(imgdef_philips_name), 'image_key'),
        philips.dims.(imgdef_philips_name) = philips.imgdef.(imgdef_philips_name);
    end
    
end

%% PAR file layout description

%% PAR file headerA
philips.parformat.headerA.lines{1}        = '# === DATA DESCRIPTION FILE ======================================================';
philips.parformat.headerA.lines{2}        = '#';
philips.parformat.headerA.lines{3}        = '# CAUTION - Investigational device.';
philips.parformat.headerA.lines{4}        = '# Limited by Federal Law to investigational use.';
philips.parformat.headerA.lines{5}        = '#';
philips.parformat.headerA.par_min_version = 3;
philips.parformat.headerA.par_max_version = Inf;

%% PAR file dataset name
philips.parformat.dataset_name.func_call       = 'print_dataset_name';
philips.parformat.dataset_name.par_min_version = 3;
philips.parformat.dataset_name.par_max_version = Inf;

%% PAR file version
philips.parformat.version_V3.lines{1}        = '# CLINICAL TRYOUT             Research image export tool     V3';
philips.parformat.version_V3.par_min_version = 3;
philips.parformat.version_V3.par_max_version = 3;

philips.parformat.version_V4.lines{1}        = '# CLINICAL TRYOUT             Research image export tool     V4';
philips.parformat.version_V4.par_min_version = 4;
philips.parformat.version_V4.par_max_version = 4;

philips.parformat.version_V41.lines{1}        = '# CLINICAL TRYOUT             Research image export tool     V4.1';
philips.parformat.version_V41.par_min_version = 4.1;
philips.parformat.version_V41.par_max_version = 4.1;

philips.parformat.version_V42.lines{1}        = '# CLINICAL TRYOUT             Research image export tool     V4.2';
philips.parformat.version_V42.par_min_version = 4.2;
philips.parformat.version_V42.par_max_version = 4.2;

%% PAR general information heading
philips.parformat.general.lines{1}        = '#';
philips.parformat.general.lines{2}        = '# === GENERAL INFORMATION ========================================================';
philips.parformat.general.lines{3}        = '#';
philips.parformat.general.par_min_version = 3;
philips.parformat.general.par_max_version = Inf;

%% PAR file dataset information
philips.parformat.pardef.func_call       = 'print_pardef';
philips.parformat.pardef.par_min_version = 3;
philips.parformat.pardef.par_max_version = Inf;

%% PAR file scaling instructions
philips.parformat.scaling_instructions.lines{1}        = '#';
philips.parformat.scaling_instructions.lines{2}        = '# === PIXEL VALUES =============================================================';
philips.parformat.scaling_instructions.lines{3}        = '#  PV = pixel value in REC file, FP = floating point value, DV = displayed value on console';
philips.parformat.scaling_instructions.lines{4}        = '#  RS = rescale slope,           RI = rescale intercept,    SS = scale slope';
philips.parformat.scaling_instructions.lines{5}        = '#  DV = PV * RS + RI             FP = DV / (RS * SS)';
philips.parformat.scaling_instructions.lines{6}        = '#';
philips.parformat.scaling_instructions.lines{7}        = '# === IMAGE INFORMATION DEFINITION =============================================';
philips.parformat.scaling_instructions.lines{8}        = '#  The rest of this file contains ONE line per image, this line contains the following information:';
philips.parformat.scaling_instructions.lines{9}        = '#';
philips.parformat.scaling_instructions.par_min_version = 3;
philips.parformat.scaling_instructions.par_max_version = Inf;

%% PAR file image definitions
philips.parformat.imgdef.func_call       = 'print_imgdef';
philips.parformat.imgdef.par_min_version = 3;
philips.parformat.imgdef.par_max_version = Inf;

%% PAR file column headings preamble
philips.parformat.column_headings_preamble.lines{1}        = '#';
philips.parformat.column_headings_preamble.lines{2}        = '# === IMAGE INFORMATION ==========================================================';
philips.parformat.column_headings_preamble.par_min_version = 3;
philips.parformat.column_headings_preamble.par_max_version = Inf;

%% PAR file column headings
philips.parformat.column_headingsB_V3.lines{1} ='#sl ec dyn ph ty  idx (re)scale             window       angulation        offcentre         info     spacing   echo  dtime ttime diff  flip';
philips.parformat.column_headingsB_V3.par_min_version = 3;
philips.parformat.column_headingsB_V3.par_max_version = 3;

philips.parformat.column_headingsB_V4.lines{1} ='#sl ec dyn ph ty  idx pix scan% rec size (re)scale             window       angulation        offcentre           thick gap  info      spacing   echo dtime ttime diff  avg flip freq RR-int turbo delay';
philips.parformat.column_headingsB_V4.par_min_version = 4;
philips.parformat.column_headingsB_V4.par_max_version = 4;

philips.parformat.column_headingsB_V41.lines{1} ='# sl ec  dyn ph ty    idx pix scan%  rec size (re)scale                        window      angulation           offcentre               thick  gap    info    spacing       echo  dtime   ttime   diff    avg flip    freq  RR-int    turbo delay b grad cont anis diffusion';
philips.parformat.column_headingsB_V41.par_min_version = 4.1;
philips.parformat.column_headingsB_V41.par_max_version = 4.1;

philips.parformat.column_headingsB_V42.lines{1} = '#  sl ec  dyn ph ty    idx pix scan% rec size                (re)scale              window        angulation              offcentre        thick   gap   info      spacing     echo     dtime   ttime    diff  avg  flip    freq   RR-int  turbo delay b grad cont anis         diffusion       L.ty';
philips.parformat.column_headingsB_V42.par_min_version = 4.2;
philips.parformat.column_headingsB_V42.par_max_version = Inf;

%% PAR file column headings postamble
philips.parformat.column_headings_postamble.lines{1} = '';
philips.parformat.column_headings_postamble.par_min_version = 3;
philips.parformat.column_headings_postamble.par_max_version = Inf;

%% PAR file image table
philips.parformat.imgdef_table.func_call       = 'print_imgdef_table';
philips.parformat.imgdef_table.par_min_version = 3;
philips.parformat.imgdef_table.par_max_version = Inf;

%% PAR file footer
philips.parformat.footer.lines{1}        = '';
philips.parformat.footer.lines{2}        = '# === END OF DATA DESCRIPTION FILE ===============================================';
philips.parformat.footer.par_min_version = 3;
philips.parformat.footer.par_max_version = Inf;

end