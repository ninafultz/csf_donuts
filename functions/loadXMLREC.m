%% LOADXMLREC     Load a Philips XMLREC image file pair
%
% [DATA,INFO] = LOADXMLREC(FILENAME)
%
%   FILENAME is a string containing a file prefix or name of the XML header
%   file or REC data file, e.g. SURVEY_1 or SURVEY_1.XML or SURVEY_1.REC

%   DATA is an N-dimensional array holding the image data.
%
%   INFO is a structure containing details from the XML header file
%
% [DATA,INFO] = LOADXMLREC([])
%
%   When the passed FILENAME is not provided or is an empty array or empty 
%   string.  The user chooses a file using UIGETFILE.
%
% [DATA,INFO] = LOADXMLREC(FILENAME,'OptionName1',OptionValue1,...)
%
%   Options can be passed to LOADXMLREC to control the range/pattern of
%   loaded data, the scale of the returned data, verbose output, etc.  The 
%   list below shows the avialable options.  Names are case-sensitive
%
%       OptionName          OptionValue     Description     
%       ----------          -----------     -----------     
%       'x'                 numeric         image rows      
%       'y'                 numeric         image columns   
%       'sl'                numeric         slices          
%       'ec'                numeric         echoes          
%       'dyn'               numeric         dynamics        
%       'ph'                numeric         cardiac phases  
%       'ty'                numeric         image types     
%       'seq'               numeric         scan sequences  
%       'b'                 numeric         diff b values   
%       'grad'              numeric         diff grad dirs  
%       'asl'               numeric         label types     
%       'scale'             string          [ {'FP'} | 'DV' | 'PV' ]
%       'verbose'           logical         [ true |{false}]
%       'savememory'        logical         [ true |{false}]
%       'reducesingletons'  logical         [{true}| false ]
%       'waitbar'           logical         [ true |{false}]
%       'par_version'       numeric         PAR header version compatibility     
%       'info'              struct          previously loaded info struct
%
%       When 'savememory' is true, SINGLE precision is used instead of DOUBLE
%
%       When 'reducesingletons' is true, the loaded DATA array is checked 
%       for any dimension that has only one single value with loaded images.  
%       If such a dimension is found, only the single dimension is preserved
%       and the other empty values are eliminated.
%
%   Example:
%       myfile = 'SURVEY_1.XML';
%       [data,info] = loadXMLREC(myfile,'sl',[1 5],'scale','DV','verbose',true);
%
% [DATA,INFO] = LOADXMLREC(FILENAME,LOADOPTS)
%
%   LOADOPTS is a structure with fieldnames equal to any of the possible
%   OptionNames.
%
%   Example:
%       loadopts.sl = [1 5];
%       loadopts.scale = 'DV';
%       loadopts.verbose = true;
%       [data,info] = loadXMLREC(myfile,loadopts);
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
%       [data,info] = loadXMLREC(myfile,loadopts);
%
% INFO = LOADXMLREC(FILENAME)
%
%   If only one return argument is provided, the INFO structure will be
%   returned.  DATA will not be loaded.
%
% INFO structure contents
%
%   The INFO structure contains all the information from the XML header in
%   addition to other useful information to describe and to work with the
%   loaded DATA array.  Most top level fieldnames in the INFO structure
%   correspond closely with the text description within the XML file. The 
%   table below describes some of the additional fields found within INFO
%
%   FieldName           Description
%   ---------           -----------
%   FILENAME            filename of the loaded data
%   XMLREC_STRUCT       structure loaded by the function XMLRECparsexml
%   VERSION             version number of the PARREC created from the XMLREC header
%   LOADOPTS            structure containing the load options (see above)
%   IMGDEF              structure containing the image defintion columns
%   N_XMLREC_IMGS       number of total images avialable in the XMLREC file
%   PIXEL_BITS          bits per pixel for the stored REC data
%   READ_TYPE           REC data file read data type, e.g. 'int16'
%   IMG_PIXELS          number of pixels in one original stored image
%   RECON_X             recontructed image size in the x (row) direction
%   RECON_Y             recontructed image size in the y (column) direction
%   DIMS                structure containing the DATA dimension names and values
%   DATASIZE            array showing the size of the returned DATA array
%   N_LOADED_IMGS       number of images loaded from the XMLREC file
%   N_DATA_IMGS         number of total images in the DATA array
%
%   The INFO.IMGDEF structure contains fields for every column decsribed by
%   the image table inside the XMLREC file.  It also stores the entire table
%   in INFO.IMGDEF.TABLE.  Finally, the INFO.IMGDEF.TABLE_ROW_INDEX_ARRAY
%   is a special array that is the same size as the DATA array (minus the
%   first two dimensions used to store a single image).  A given index for
%   a given image in the DATA array will return the row number describing
%   the details of that image in the INFO.IMGDEF.TABLE array when that same
%   index is used with the INFO.IMGDEF.TABLE_ROW_INDEX_ARRAY.  This provides
%   a quick way to recall the image defintion details of any individual
%   image contained within DATA.  If the INFO.IMGDEF.TABLE_ROW_INDEX_ARRAY
%   holds a ZERO for a given index, there was no image in the XMLREC data 
%   that matched the dimension location in DATA.  This often occurs with
%   diffusion data and B1 mapping data.  Such empty locations will be all
%   ZEROES in the DATA array.
%
%  See also: WRITEXMLREC, LOADPARREC, LOADDICOM, LOADLABRAW
%
%  Dependencies: XMLRECPARSEXML, DICTPARREC
%

%% Revision History
% 2009.03.20    initial version - brianwelch

%% Function definition
function [data,info] = loadXMLREC(filename,varargin)

%% Start execution time clock and initialize DATA and INFO to empty arrays
tic;
data=[];
info=[];

%% Initialize INFO structure
% Serves to fix the display order
info.filename = [];
info.par_version = [];
info.xmlrec_struct = [];
info.loadopts = [];
info.pardef = [];
info.extdef = []; % extra information available in XML header
info.imgdef = [];
info.dims = [];
info.dimnames = [];
info.table = [];
info.table_row_index_array = [];
info.n_xmlrec_imgs = [];
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
        {'*.XML', 'XML files (*.XML)'; ...
         '*.REC', 'REC files (*.REC)'; ...
         '*.*',   'All Files (*.*)'}, ...
         'Select XMLREC file');
    if fn~=0,
        filename = sprintf('%s%s',pn,fn);
    else
        disp('LOADXMLREC cancelled');
        return;
    end
end


%% Parse the filename.
% It may be the PAR filename, REC filename or just the filename prefix
% Instead of REGEXP, use REGEXPI which igores case
toks = regexpi(filename,'^(.*?)(\.XML|\.REC)?$','tokens');
prefix = toks{1}{1};
xmlname = sprintf('%s.XML',prefix);
recname = sprintf('%s.REC',prefix);

info.filename = filename;

%% Load Philips XMLREC entries
philips = dictPARREC;
pardef_names = fieldnames(philips.pardef);
imgdef_names = fieldnames(philips.imgdef);

%% parse load options
p = inputParser;
p.StructExpand = true;
p.CaseSensitive = true;
p.KeepUnmatched = true; % keep unmatched for now
p.addRequired('filename', @ischar);
p.addParamValue('x', [], @isnumeric);
p.addParamValue('y', [], @isnumeric);
p.addParamValue('scale', 'FP', @ischar);
p.addParamValue('verbose', false, @islogical);
p.addParamValue('savememory', false, @islogical);
p.addParamValue('reducesingletons', true, @islogical);
p.addParamValue('waitbar', false, @islogical);
p.addParamValue('par_version', [], @isnumeric);
p.addParamValue('info', [], @isstruct);
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

% if PAR_VERSION is not specified, set it to the max of the par_min_version's
info.par_version = 0; 
if isempty(p.Results.par_version),
    for k=1:length(pardef_names),
        if ( (philips.pardef.(pardef_names{k}).par_min_version < Inf) & (philips.pardef.(pardef_names{k}).par_min_version > info.par_version) ),
            info.par_version = philips.pardef.(pardef_names{k}).par_min_version;
        end
    end
else
    info.par_version = p.Results.par_version; 
end

if ~ischar(info.par_version),
    tmp = info.par_version;
    if ceil(tmp - floor(tmp))==1,
        info.par_version = sprintf('%.1f',tmp);
    else
        info.par_version = sprintf('%.0f',tmp);
    end
end
par_version = str2num(info.par_version);

% with known PARREC version, determine info.dimnames
info.dimnames = {};
for k=1:length(imgdef_names),
    if isfield(philips.imgdef.(imgdef_names{k}),'image_key'),
        if ~strcmp(philips.imgdef.(imgdef_names{k}).image_key,'idx')
            if( (philips.imgdef.(imgdef_names{k}).par_min_version <= par_version) & (philips.imgdef.(imgdef_names{k}).par_max_version >= par_version) ) 
                info.dimnames{end+1} = philips.imgdef.(imgdef_names{k}).image_key;
            end
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

%% Load XMLREC header using custom XMLRECINFOFAST
info.xmlrec_struct = XMLRECparsexml(xmlname,'waitbar',info.loadopts.waitbar);

%% Create tag structure from info.xmlrec_struct.Series_Info
Series_Info_tag_struct = [];
Series_Info_unused_fieldnames = [];
Series_Info_notag_fieldnames = [];
Series_Info_fieldnames = fieldnames(info.xmlrec_struct.Series_Info);
for f=1:length(Series_Info_fieldnames),
    if isfield(info.xmlrec_struct.Series_Info.(Series_Info_fieldnames{f}),'Tag'),
        % tag values have the format 0xGGGGEEEE
        Series_Info_tag_string = info.xmlrec_struct.Series_Info.(Series_Info_fieldnames{f}).Tag(2:10);
        Series_Info_tag_struct.(Series_Info_tag_string).Series_Info_fieldname = Series_Info_fieldnames{f};
        Series_Info_unused_fieldnames.(Series_Info_fieldnames{f}) = 1;
    else
        Series_Info_notag_fieldnames.(Image_Info_fieldnames{f}) = 1;
    end
end

%% Convert XMLREC structure to PARDEF portion of INFO structure
for k=1:length(pardef_names),
        pardef_name = pardef_names{k};

        if ( (par_version >= philips.pardef.(pardef_name).par_min_version) & (par_version <= philips.pardef.(pardef_name).par_max_version) ),

            group    = philips.pardef.(pardef_name).group;
            element  = philips.pardef.(pardef_name).element;
            
            value = [];
            for e=1:length(element),
                tag_string = ['x' dec2hex(group(e),4) dec2hex(element(e),4)];
                if isfield(Series_Info_tag_struct,tag_string),
                    Series_Info_fieldname = Series_Info_tag_struct.(tag_string).Series_Info_fieldname;
                    value{e} = info.xmlrec_struct.Series_Info.(Series_Info_fieldname).value;
                    Series_Info_unused_fieldnames.(Series_Info_fieldname) = 0;
                    
                    switch info.xmlrec_struct.Series_Info.(Series_Info_fieldname).Type,
                        case {'Float','Int16','Int32'}
                            value{e} = str2num( value{e} );
                        case {'String','Date','Time','Boolean','Enumeration'}
                            % do nothing, keep as string
                        otherwise
                            % do nothing, keep as string
                    end
                    
                end
            end
            
            if isempty(value),
                if isfield(philips.pardef.(pardef_name),'default'),
                    value = philips.pardef.(pardef_name).default;
                    disp( sprintf('PARDEF defaulted: %s',pardef_name) );
                    switch info.xmlrec_struct.Series_Info.(Series_Info_fieldname).Type,
                        case {'Float','Int16','Int32','Boolean'}
                            value = str2num(value);
                        case {'String','Date','Time','Enumeration'}
                            % do nothing, keep as string
                        otherwise
                            % do nothing, keep as string
                    end
                    
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

%% Store additionally available (not used yet) XMLREC MRSeries values in the extra definition (INFO.EXTDEF) section
for f=1:length(Series_Info_fieldnames),
    if ( Series_Info_unused_fieldnames.(Series_Info_fieldnames{f}) ),
        attribute_names = fieldnames( info.xmlrec_struct.Series_Info.(Series_Info_fieldnames{f}) );
        for a=1:length(attribute_names),
            info.extdef.xml.(Series_Info_fieldnames{f}).(attribute_names{a}) = info.xmlrec_struct.Series_Info.(Series_Info_fieldnames{f}).(attribute_names{a});
        end
    end
end

%% Convert XMLRECHEADER structure to IMGDEF portion of INFO structure
info.ndims = length(info.dimnames);
info.n_xmlrec_imgs = length(info.xmlrec_struct.Image_Array);

%% determine number of columns in the table
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
info.table = NaN(info.n_xmlrec_imgs,n_table_cols);

%% Create Image_Info Key tag structure from info.xmlrec_struct.Image_Array(1).Image_Info.Key 
Image_Info_Key_tag_struct = [];
Image_Info_Key_unused_fieldnames = [];
Image_Info_Key_notag_fieldnames = [];
Image_Info_Key_fieldnames = fieldnames(info.xmlrec_struct.Image_Array(1).Image_Info.Key);
for f=1:length(Image_Info_Key_fieldnames),
    % tag values have the format 0xGGGGEEEE
    if ( isfield(info.xmlrec_struct.Image_Array(1).Image_Info.Key.(Image_Info_Key_fieldnames{f}),'Tag') ),
        Image_Info_Key_tag_string = info.xmlrec_struct.Image_Array(1).Image_Info.Key.(Image_Info_Key_fieldnames{f}).Tag(2:10);
        Image_Info_Key_tag_struct.(Image_Info_Key_tag_string).Image_Info_Key_fieldname = Image_Info_Key_fieldnames{f};
        Image_Info_Key_unused_fieldnames.(Image_Info_Key_fieldnames{f}) = 1;
    else
        Image_Info_Key_notag_fieldnames.(Image_Info_Key_fieldnames{f}) = 1;
    end
end

%% Create Image_Info Key tag structure from info.xmlrec_struct.Image_Array(1).Image_Info
Image_Info_tag_struct = [];
Image_Info_unused_fieldnames = [];
Image_Info_notag_fieldnames = [];
Image_Info_fieldnames = fieldnames(info.xmlrec_struct.Image_Array(1).Image_Info);
for f=1:length(Image_Info_fieldnames),
    % tag values have the format 0xGGGGEEEE
    if ( ~strcmp(Image_Info_fieldnames{f},'Key') ),
        if ( isfield(info.xmlrec_struct.Image_Array(1).Image_Info.(Image_Info_fieldnames{f}),'Tag') ),
            Image_Info_tag_string = info.xmlrec_struct.Image_Array(1).Image_Info.(Image_Info_fieldnames{f}).Tag(2:10);
            Image_Info_tag_struct.(Image_Info_tag_string).Image_Info_fieldname = Image_Info_fieldnames{f};
            Image_Info_unused_fieldnames.(Image_Info_fieldnames{f}) = 1;
        else
            Image_Info_notag_fieldnames.(Image_Info_fieldnames{f}) = 1;
        end
    end
end

%% fill in table
start_col = 0;
stop_col = 0;

if info.loadopts.waitbar,
    hwait = waitbar(0,'loadXMLREC: Creating XML header information structure...');
end

for k=1:count_imgdef_fieldnames,
    
    imgdef_philips_name = imgdef_philips_names{k};
    imgdef_fieldname = imgdef_fieldnames{k};
    
    start_col = stop_col + 1;
    stop_col  = stop_col + philips.imgdef.(imgdef_philips_name).imgdef_size;           
    
    info.imgdef.(imgdef_fieldname).size = philips.imgdef.(imgdef_philips_name).imgdef_size;

    group    = philips.imgdef.(imgdef_philips_name).group;
    element  = philips.imgdef.(imgdef_philips_name).element;
    for e=1:length(element),
        tag_strings{e} = ['x' dec2hex(group(e),4) dec2hex(element(e),4)];
    end
    
    Image_Info_Key_fieldnames = [];
    Image_Info_fieldnames = [];
    if ( isfield(philips.imgdef.(imgdef_philips_name),'image_key') ),
        for e=1:length(element),
            if isfield(Image_Info_Key_tag_struct,tag_strings{e}),
                Image_Info_Key_fieldnames{e} = Image_Info_Key_tag_struct.(tag_strings{e}).Image_Info_Key_fieldname;
                Image_Info_Key_unused_fieldnames.(Image_Info_Key_fieldnames{e}) = 0;
            else
                % not in tag structure, it must be missing or be a 'Calc' entry
                % zeroing InstanceNumber (value is still NaN)
                
                % special cases
                switch imgdef_philips_name,
                    case 'InstanceNumber'
                        Image_Info_Key_fieldnames{e} = 'Index';
                end

            end
        end
    else    
        for e=1:length(element),
            if isfield(Image_Info_tag_struct,tag_strings{e}),
                Image_Info_fieldnames{e} = Image_Info_tag_struct.(tag_strings{e}).Image_Info_fieldname;
                Image_Info_unused_fieldnames.(Image_Info_fieldnames{e}) = 0;
            else
                % not in tag structure, it must be missing or be a 'Calc' entry

                % special cases
                switch imgdef_philips_name,
                    case 'MRStackAngulation'
                        MRStackAngulation_fieldnames = {'Angulation_AP','Angulation_FH','Angulation_RL'};
                        Image_Info_fieldnames{e} = MRStackAngulation_fieldnames{e};
                    case 'ImagePlanePositionPatient'
                        Image_Info_fieldnames{1} = 'Offcenter_AP';
                        Image_Info_fieldnames{2} = 'Offcenter_FH';
                        Image_Info_fieldnames{3} = 'Offcenter_RL';
                        element = [1:3]; % make element size 3, to loop over offcenter fields
                    case 'MRStackViewAxis'
                        Image_Info_fieldnames{e} = 'Slice_Orientation';
                end
            end
        end
    end
    
    vals = NaN(info.n_xmlrec_imgs, info.imgdef.(imgdef_fieldname).size);
    
    for v=1:info.n_xmlrec_imgs,
        
        value = [];
        value_type = [];
        for e=1:length(element),
            value{e} = 'NaN';
            value_type{e} = 'NONE';
        end
        
        if ( isfield(philips.imgdef.(imgdef_philips_name),'image_key') ),
            if ~isempty(Image_Info_Key_fieldnames),
                for e=1:length(element),
                    value{e} = info.xmlrec_struct.Image_Array(v).Image_Info.Key.(Image_Info_Key_fieldnames{e}).value;
                    value_type{e} = info.xmlrec_struct.Image_Array(v).Image_Info.Key.(Image_Info_Key_fieldnames{e}).Type;
                end
            end
        else
            if ~isempty(Image_Info_fieldnames),
                for e=1:length(element),
                    value{e} = info.xmlrec_struct.Image_Array(v).Image_Info.(Image_Info_fieldnames{e}).value;
                    value_type{e} = info.xmlrec_struct.Image_Array(v).Image_Info.(Image_Info_fieldnames{e}).Type;
                end
            end
        end
        
        % All values from XML are strings
        % Most are already numbers as string requiring only str2num()
        % Some are enumerations
        for e=1:length(element),
            if ( strcmp(value_type{e},'Enumeration') || strcmp(value_type{e},'String') ),
                if isfield(philips.imgdef.(imgdef_philips_name),'enum'),
                    value{e} = enum_value(value,philips.imgdef.(imgdef_philips_name).enum);
                elseif isfield(philips.imgdef.(imgdef_philips_name),'format_func'),
                    format_func = philips.imgdef.(imgdef_philips_name).format_func;
                    eval( sprintf('%s;', format_func) );
                    %disp( sprintf('%s;', format_func) );
                end
                if isnan(value{e}),
                    if isfield(philips.imgdef.(imgdef_philips_name),'default'),
                        value{e} = philips.imgdef.(imgdef_philips_name).default(e);
                        if (v==1), disp( sprintf('IMGDEF defaulted: %s (unknown enum value)',imgdef_philips_name)); end
                    else
                        value{e} = 0;
                        if (v==1), disp( sprintf('zeroing %s (value is still NaN)',imgdef_philips_name)); end
                    end
                end       
            else
                value{e} = str2num(value{e});
                if isnan(value{e}),
                    if isfield(philips.imgdef.(imgdef_philips_name),'default'),
                        value{e} = philips.imgdef.(imgdef_philips_name).default(e);
                        if (v==1), disp( sprintf('IMGDEF defaulted: %s (value is still NaN)',imgdef_philips_name)); end
                    else
                        value{e} = 0;
                        if (v==1), disp( sprintf('IMGDEF zeroed: %s (value is still NaN)',imgdef_philips_name)); end
                    end
                end
            end
        end
        vals(v,:) = [value{:}];
    end

    info.table(:,start_col:stop_col) = vals;
    info.imgdef.(imgdef_fieldname).vals = vals;
    info.imgdef.(imgdef_fieldname).uniq = unique(vals,'rows');
    info.imgdef.(imgdef_fieldname).cols = [start_col:stop_col];
    
    % if size is one, store unique values as row vector for easier display at prompt
    if info.imgdef.(imgdef_fieldname).size==1,
        %info.imgdef.(imgdef_fieldname).vals = (info.imgdef.(imgdef_fieldname).vals(:)).';
        info.imgdef.(imgdef_fieldname).uniq = (info.imgdef.(imgdef_fieldname).uniq(:)).';
    end
    
    if info.loadopts.waitbar,
        waitbar(k/count_imgdef_fieldnames,hwait);
    end
    
end

if info.loadopts.waitbar,
    close(hwait);
end

%% Return if there are no images
if info.n_xmlrec_imgs==0,
    return
end

end % end load INFO section

%% Set dimension names and important columns based on version number
switch info.par_version,
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
        disp( sprintf('Unknown version : %s', info.par_version) );
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
info.img_pixels = prod(info.imgdef.recon_resolution_x_y.uniq);
info.recon_x = info.imgdef.recon_resolution_x_y.uniq(1);
info.recon_y = info.imgdef.recon_resolution_x_y.uniq(2);
info.dims.x = [1:info.imgdef.recon_resolution_x_y.uniq(1)]; 
info.dims.y = [1:info.imgdef.recon_resolution_x_y.uniq(2)];


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
fid = fopen(recname,'r','l');
if fid<0,
    error(sprintf('cannot open REC file: %s', rec_filename));
end
info.n_loaded_imgs=0;

if info.loadopts.waitbar,
    hwait = waitbar(0,'Loading XMLREC data ...');
end
for n=1:info.n_xmlrec_imgs,
    
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
        
        byte_offset = rec_index*info.img_pixels*(info.pixel_bits/8);
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
    if info.loadopts.waitbar,
        waitbar(n/info.n_xmlrec_imgs,hwait);
    end
end
fclose(fid);
if info.loadopts.waitbar,
    close(hwait);
end

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

%% Eliminate unloaded images in info.xmlrec_struct.Image_Array
info.xmlrec_struct.Image_Array = info.xmlrec_struct.Image_Array(info.table_row_index_array);


%% If VERBOSE, display execution information
if info.loadopts.verbose==true,
    disp( sprintf('XMLREC loaded as a V%s PARREC file', info.par_version) );
    disp( sprintf('Loaded images are in ''%s'' scale', info.loadopts.scale) );
    disp( sprintf('Loaded %d of %d available images of original size [%d x %d]', info.n_loaded_imgs, info.n_xmlrec_imgs, info.recon_x, info.recon_y) );
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
        value = [date_str ' / ' time_str];
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
        value = [value{:}];
        %value = value{1};
        %value = value(2:3);
    end

    function format_str2num,
        tmp = value;
        value = [];
        for k=1:length(tmp),
            if ischar(tmp{k}),
                value(k) = str2num(tmp{k});
            else
                value(k) = tmp{k};
            end
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
            case {'N','NO','n','no','No','0'},
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
        switch info.par_version,
            case '3',
                slice_thickness = info.pardef.Slice_gap_mm;
            case {'4','4.1','4.2'},
                slice_thickness = info.table(v,start_col-1);
        end
        value = value - slice_thickness; % subtract slice thickness
    end

    function format_stack_view_axis_to_slice_orientation,
        % {'UNDEFINED','TRANSVERSAL','SAGITTAL','CORONAL'}
        switch value{1},
            case {'FH','TRANSVERSAL','Transversal'}, % transversal
                value{1} = 1;
            case {'RL','SAGITTAL','Sagittal'}, % sagittal
                value{1} = 2;
            case {'AP','CORONAL','Coronal'}, % coronal
                value{1} = 3;
            otherwise, % unknown
                value{1} = 0;
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

    if strcmp(value_str,'-'),
        n = 0;
    end
    
    for k=1:length(enum),
        if strcmp(deblank(value_str),enum{k}),
            n=k-1;
            break;
        end
    end
end
