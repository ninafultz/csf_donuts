%% XMLRECPARSEXML     Convert a Philips XMLREC XML file to a structure
%
% [INFO] = XMLRECPARSEXML(XMLFILENAME)
%
%   INFO is a structure containing the tag information within the XML file
%   XMLFILENAME.
%
%   INFO = XMLRECPARSEXML(XMLFILENAME,'waitbar',true)
%
%   Dislpays a waitbar while the XML tags are being parsed.
%
%  See also: LOADXMLREC, WRITEXMLREC, XMLRECWRITEXML
%
%  Dependencies: none
%

%% Revision History
% * 2009.03.20    initial version - brianwelch

function info = XMLRECparsexml(xmlfilename,varargin)

%% parse options
p = inputParser;
p.StructExpand = true;
p.CaseSensitive = true;
p.KeepUnmatched = true; % keep unmatched for now
p.addRequired('xmlfilename', @ischar);
p.addParamValue('waitbar', false, @islogical);
p.parse(xmlfilename, varargin{:});
parsed_varargin_struct = p.Results;

xmlfilename = parsed_varargin_struct.xmlfilename;

%% Open XML file and read all text
fid = fopen(xmlfilename,'r');
if fid~=-1,
    textblob = fread(fid,inf,'uint8=>char')';
    fclose(fid);
else
    error( sprintf('Cannot open %s for reading', xmlfilename) );
end

%% Open waitbar if it is activated
if parsed_varargin_struct.waitbar,
    hwait = waitbar(0,'XMLRECparse: Parsing XML file...');
end

%% Insert carriage-return, newline between XML tags to guarantee one tag per line
textblob = regexprep(textblob,'>\s*<','>\r\n<');

%% Turn textblob into separate lines
% leading whitespace will not be returned
% ending carriage-return, newline (\r\n) will not be returned
% empty lines will not be returned
xml_tokens_as_cells = regexp(textblob,'\s*([^\r\n]+)\r\n','tokens');

%% Convert cell array of cell tokens into a cell array of strings
xml_tokens_as_strs = [xml_tokens_as_cells{:}];

%% Find start and stop points for Series_Info
detected_start_as_cells = regexp(xml_tokens_as_strs,'<\/?Series_Info>','start');
found = find(1-cellfun('isempty',detected_start_as_cells));
Series_Info_starts = found(1);
Series_Info_stops = found(2);

%% Find start and stop points for Image_Info
detected_start_as_cells = regexp(xml_tokens_as_strs,'<\/?Image_Info>','start');
found = find(1-cellfun('isempty',detected_start_as_cells));
Image_Info_starts = found(1:2:end);
Image_Info_stops = found(2:2:end);

%% Find start and stop points for Key
detected_start_as_cells = regexp(xml_tokens_as_strs,'<\/?Key>','start');
found = find(1-cellfun('isempty',detected_start_as_cells));
Key_starts = found(1:2:end);
Key_stops = found(2:2:end);

%% attribute regular expression tokens: 
% name
% value
% subattribute name(s)
% subattribute value(s)
%attribute_regexp_token_patterns = {'>(.*)<',' (\w+)=','"([\w ]+)"'};
attribute_name_regexp_token_pattern  = ' Name="([\w ]+)" ';
attribute_value_regexp_token_pattern = '>(.*)<';
attribute_subattribute_name_regexp_token_pattern = ' (\w+)=';
attribute_subattribute_value_regexp_token_pattern = '"([\w ]+)"';

%% Create Series_Info structure
selected_xml_tokens_as_strs = [xml_tokens_as_cells{(Series_Info_starts+1):(Series_Info_stops-1)}];
name_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_name_regexp_token_pattern,'tokens');
value_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_value_regexp_token_pattern,'tokens');
subattribute_name_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_subattribute_name_regexp_token_pattern,'tokens');
subattribute_value_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_subattribute_value_regexp_token_pattern,'tokens');
for k=1:length(name_tokens_as_cells),
    parent_fieldname = char(regexprep(name_tokens_as_cells{k}{1},'\s*','_'));
    child_fieldnames = [subattribute_name_tokens_as_cells{k}{:}];
    child_values = [subattribute_value_tokens_as_cells{k}{:}];
    info.Series_Info.(parent_fieldname) = cell2struct(child_values,child_fieldnames,2);
    info.Series_Info.(parent_fieldname).value = char(value_tokens_as_cells{k}{1});
end

%% Create Image_Array structure for the first image
info.Image_Array = [];

%% Key
selected_xml_tokens_as_strs = [xml_tokens_as_cells{(Key_starts(1)+1):(Key_stops(1)-1)}];
name_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_name_regexp_token_pattern,'tokens');
value_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_value_regexp_token_pattern,'tokens');
subattribute_name_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_subattribute_name_regexp_token_pattern,'tokens');
subattribute_value_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_subattribute_value_regexp_token_pattern,'tokens');
for k=1:length(name_tokens_as_cells),
    parent_fieldname = char(regexprep(name_tokens_as_cells{k}{1},'\s*','_'));
    child_fieldnames = [subattribute_name_tokens_as_cells{k}{:}];
    child_values = [subattribute_value_tokens_as_cells{k}{:}];
    info.Image_Array(1).Image_Info.Key.(parent_fieldname) = cell2struct(child_values,child_fieldnames,2);
    info.Image_Array(1).Image_Info.Key.(parent_fieldname).value = char(value_tokens_as_cells{k}{1});
end

%% Attributes
selected_xml_tokens_as_strs = [xml_tokens_as_cells{(Key_stops(1)+1):(Image_Info_stops(1)-1)}];
name_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_name_regexp_token_pattern,'tokens');
value_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_value_regexp_token_pattern,'tokens');
subattribute_name_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_subattribute_name_regexp_token_pattern,'tokens');
subattribute_value_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_subattribute_value_regexp_token_pattern,'tokens');
for k=1:length(name_tokens_as_cells),
    parent_fieldname = char(regexprep(name_tokens_as_cells{k}{1},'\s*','_'));
    child_fieldnames = [subattribute_name_tokens_as_cells{k}{:}];
    child_values = [subattribute_value_tokens_as_cells{k}{:}];
    info.Image_Array(1).Image_Info.(parent_fieldname) = cell2struct(child_values,child_fieldnames,2);
    info.Image_Array(1).Image_Info.(parent_fieldname).value = char(value_tokens_as_cells{k}{1});
end

%% pre-allocate Image_Array structure
nImages = length(Key_starts);
info.Image_Array(2:nImages) = info.Image_Array(1);


%% close waitbar if it is activated
if parsed_varargin_struct.waitbar,
    close(hwait);
end

%% loop through remaining images
if parsed_varargin_struct.waitbar,
    hwait = waitbar(0,'XMLRECparse: Parsing XML Image Array tags...');
end
for idx = 2:nImages,
   
    %% Key
    selected_xml_tokens_as_strs = [xml_tokens_as_cells{(Key_starts(idx)+1):(Key_stops(idx)-1)}];
    name_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_name_regexp_token_pattern,'tokens');
    value_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_value_regexp_token_pattern,'tokens');
    subattribute_name_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_subattribute_name_regexp_token_pattern,'tokens');
    subattribute_value_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_subattribute_value_regexp_token_pattern,'tokens');
    for k=1:length(name_tokens_as_cells),
        parent_fieldname = char(regexprep(name_tokens_as_cells{k}{1},'\s*','_'));
        child_fieldnames = [subattribute_name_tokens_as_cells{k}{:}];
        child_values = [subattribute_value_tokens_as_cells{k}{:}];
        info.Image_Array(idx).Image_Info.Key.(parent_fieldname) = cell2struct(child_values,child_fieldnames,2);
        info.Image_Array(idx).Image_Info.Key.(parent_fieldname).value = char(value_tokens_as_cells{k}{1});
    end

    %% Attributes
    selected_xml_tokens_as_strs = [xml_tokens_as_cells{(Key_stops(idx)+1):(Image_Info_stops(idx)-1)}];
    name_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_name_regexp_token_pattern,'tokens');
    value_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_value_regexp_token_pattern,'tokens');
    subattribute_name_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_subattribute_name_regexp_token_pattern,'tokens');
    subattribute_value_tokens_as_cells = regexp(selected_xml_tokens_as_strs,attribute_subattribute_value_regexp_token_pattern,'tokens');
    for k=1:length(name_tokens_as_cells),
        parent_fieldname = char(regexprep(name_tokens_as_cells{k}{1},'\s*','_'));
        child_fieldnames = [subattribute_name_tokens_as_cells{k}{:}];
        child_values = [subattribute_value_tokens_as_cells{k}{:}];
        info.Image_Array(idx).Image_Info.(parent_fieldname) = cell2struct(child_values,child_fieldnames,2);
        info.Image_Array(idx).Image_Info.(parent_fieldname).value = char(value_tokens_as_cells{k}{1});
    end

    if parsed_varargin_struct.waitbar,
        waitbar(idx/nImages,hwait);
    end
end
if parsed_varargin_struct.waitbar,
    close(hwait');
end
