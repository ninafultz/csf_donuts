%% CONVERTPARREC     Convert a Philips PARREC image file to a different version
%
% [SUCCESS] = CONVERTPARREC(SRCFILENAME,DSTFILENAME,VERSION)
%
%   SRCFILENAME is a string containing a file prefix or name of the PAR header
%   file or REC data file, e.g. SURVEY_1 or SURVEY_1.PAR or SURVEY_1.REC
%
%   DSTFILENAME is a string containing a file prefix or name of the PAR header
%   file or REC data file, e.g. SURVEY_1 or SURVEY_1.PAR or SURVEY_1.REC
%
%   VERSION is a string specifying the PARREC version to which to convert,
%   e.g. '3', '4', '4.1' or '4.2'
%
%  See also: LOADPARREC, WRITEPARREC
%
%  Dependencies: LOADPARREC, WRITEPARREC, DICTPARREC
%

%% Revision History
% * 2008.05.16    initial version - brianwelch

%% Function definition
function success = convertParRec(srcfilename,dstfilename,version)

% Assume successful unless proven to be otherwise
success = 1;

%% Parse the source filename.
[srcparname,srcrecname] = parse_parrec_filename(srcfilename);

%% Parse the destination filename.
[dstparname,dstrecname] = parse_parrec_filename(dstfilename);

%% Specify load options
loadopts.verbose = false;

%% load the source PAR file (info only)
try
    [info] = loadParRec(srcparname,loadopts);
    if ~isempty(info),
        disp( sprintf('convertParRec success : loadParRec (%s)', srcparname ) );
    else
        success = 0;
        disp( sprintf('convertParRec failure : loadParRec (%s)', srcparname ) );
        return;        
    end
catch
    success = 0;
    disp( sprintf('convertParRec failure : loadParRec (%s)', srcparname ) );
    return;
end

%% write the destination PAR file (info only)
try 
    [success_write] = writeParRec(dstparname,[],info,version);
    if success_write,
        disp( sprintf('convertParRec success : writeParRec (%s)', dstparname) );
    else
        success = 0;
        disp( sprintf('convertParRec failure : writeParRec (%s)', dstparname) );
        return;
    end
catch
    success = 0;
    disp( sprintf('convertParRec failure : writeParRec (%s)', dstparname) );
    return;
end

%% copy the source REC file to the destination REC file
try
    [success_copy, message,messageid] = copyfile(srcrecname,dstrecname);
    if success_copy,
        disp( sprintf('convertParRec success : copyfile (%s to %s)', srcrecname, dstrecname) );
    else
        success = 0;
        disp( sprintf('convertParRec failure : copyfile (%s to %s)', srcrecname, dstrecname) );
        return;
    end
catch
    success = 0;
    disp( sprintf('convertParRec failure : copyfile (%s to %s)', srcrecname, dstrecname) );
    return;
end

%% function PARSE_PARREC_FILENAME
function [parname,recname] = parse_parrec_filename(filename)
% It may be the PAR filename, REC filename or just the filename prefix
% Instead of REGEXP, use REGEXPI which igores case
filename = regexprep(filename,'\\*','/');
toks = regexpi(filename,'^(.*?)(\.PAR|\.REC)?$','tokens');
fileprefix = toks{1}{1};
parname = sprintf('%s.PAR',fileprefix);
recname = sprintf('%s.REC',fileprefix);