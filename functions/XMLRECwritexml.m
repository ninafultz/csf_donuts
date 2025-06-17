function result = XMLRECwritexml(xmlrec_struct,filename)

%% Assumes the following structure format
% xmlrec_struct.Series_Info
% xmlrec_struct.Image_Array(:)
%
% xmlrec_struct.Series_Info.ATTRIBUTE_NAME.subattribute_1
% xmlrec_struct.Series_Info.ATTRIBUTE_NAME.subattribute_2
% ...
% xmlrec_struct.Series_Info.ATTRIBUTE_NAME.subattribute_N
% xmlrec_struct.Series_Info.ATTRIBUTE_NAME.value
%
% xmlrec_struct.Image_Array([1:nImages]).Image_Info.Key.ATTRIBUTE_NAME.subattribute_1
% xmlrec_struct.Image_Array([1:nImages]).Image_Info.Key.ATTRIBUTE_NAME.subattribute_2
% ...
% xmlrec_struct.Image_Array([1:nImages]).Image_Info.Key.ATTRIBUTE_NAME.subattribute_N
% xmlrec_struct.Image_Array([1:nImages]).Image_Info.Key.ATTRIBUTE_NAME.value
%
% xmlrec_struct.Image_Array([1:nImages]).Image_Info.ATTRIBUTE_NAME.subattribute_1
% xmlrec_struct.Image_Array([1:nImages]).Image_Info.ATTRIBUTE_NAME.subattribute_2
% ...
% xmlrec_struct.Image_Array([1:nImages]).Image_Info.ATTRIBUTE_NAME.subattribute_N
% xmlrec_struct.Image_Array([1:nImages]).Image_Info.ATTRIBUTE_NAME.value
%

fid = fopen(filename,'w');

pride_tag_name = 'PRIDE_V5';
newline_str = sprintf('\r\n');

fprintf(fid,'<%s>%s', pride_tag_name, newline_str);

%% Series_Info
fprintf(fid,'  <Series_Info>%s', newline_str);
f = fieldnames(xmlrec_struct.Series_Info);
attribute_indent = '    ';
for k=1:length(f),
    tmp_struct = xmlrec_struct.Series_Info.(f{k});
    xmlrec_print_attribute(f{k},tmp_struct);
end
fprintf(fid,'  </Series_Info>%s', newline_str);

%% Image_Array
fprintf(fid,'  <Image_Array>%s', newline_str);
for n=1:length(xmlrec_struct.Image_Array(:)),
    fprintf(fid,'    <Image_Info>%s', newline_str);
    
    %% Key
    fprintf(fid,'      <Key>%s', newline_str);
    key_fieldnames = fieldnames(xmlrec_struct.Image_Array(n).Image_Info.Key);
    attribute_indent = '        ';
    for key=1:length(key_fieldnames),
        tmp_struct = xmlrec_struct.Image_Array(n).Image_Info.Key.(key_fieldnames{key});
        xmlrec_print_attribute(key_fieldnames{key},tmp_struct);
    end
    fprintf(fid,'      </Key>%s', newline_str);
    
    %% Other Image_Info
    other_Image_Info_fieldnames = fieldnames(xmlrec_struct.Image_Array(n).Image_Info);
    attribute_indent = '      ';
    for other=2:length(other_Image_Info_fieldnames),
        tmp_struct = xmlrec_struct.Image_Array(n).Image_Info.(other_Image_Info_fieldnames{other});
        xmlrec_print_attribute(other_Image_Info_fieldnames{other},tmp_struct);
    end
    
    fprintf(fid,'    </Image_Info>%s', newline_str);
end
fprintf(fid,'  </Image_Array>%s', newline_str);

fprintf(fid,'</%s>', pride_tag_name);
fclose(fid);

    function xmlrec_print_attribute(attribute_name,attribute_struct)
        fprintf(fid,'%s<Attribute', attribute_indent);
        f2 = fieldnames(attribute_struct);
        for k2 = 1:(length(f2)-1),
            fprintf(fid,' %s="%s"', f2{k2}, attribute_struct.(f2{k2}) );
        end
        fprintf(fid,'>%s', attribute_struct.value );
        fprintf(fid,'</Attribute>%s', newline_str);
    end

end