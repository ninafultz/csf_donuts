% The light version of the SWI matlab tool, without GUI.
% script SWI_Duyn_ParRec
% to do SWI and unwrapping retrospectively on PARREC data
% default is kernel = 92 and SWI = 4
% please contact Emiel in case of problems

clc;
clearvars;
%% data info
% nrFiles = 1;
source_location = "R:\Emiel\PRIDE\pride_duyn\scripts\"; % input directory
destination_location = "R:\Emiel\PRIDE\pride_duyn\scripts\";    % output directiory
input_filename = 'DBIEX_6_1.REC';  % name of parrec to read

% or the UI way:
% nrFiles = 1;
% studyDir = "R:\Emiel\PRIDE\pride_duyn\";
% [input_filename,source_location] = uigetfile(studyDir, '*.PAR');
% destination_location = source_location;

% or all files within a folder and its subfolder
% full_location = "R:\Emiel\PRIDE\pride_duyn\";
% duyn_scan_name = "*duyn*.REC";
% files = dir(full_location+"**\"+duyn_scan_name);
% nrFiles = size(files,1);

%%
for scan = 1:nrFiles
    if exist('full_location','var')
        input_filename = files(scan).name;
        source_location = files(scan).folder+"\";
        destination_location = files(scan).folder+"\";
    end
    
    clc;
    try
    subject = ""; % you can fill in a name here
    disp("Data info...");
    disp("Running SWI on: "+source_location+input_filename);

    %% settings for SWI 
    output_filename_base = subject+'WIP_';
    kernel = 92;    % parameter for unwrapping
    swi = 4;    % swi weighting
    masking = 0; % 0 means no mask (mask not tested)
    disp("Settings SWI...")

    %% check for not overwriting data
    %(don't change anything from here!)
    disp("Running some checks...")
    output_filename = strcat(output_filename_base, num2str(kernel),'_', num2str(swi),'_',input_filename);
    if contains(input_filename,output_filename_base)
        disp("Already SWI scan...")
        continue
    end
    if isfile(destination_location+output_filename)
        disp("Output file already existing...")
        disp("Prompt user...")
        answer = questdlg('Output filename already exist, Overwriting data?', ...
        "scan:"+source_location, ...
        "Yes, overwrite data","No","Hell Nooo!!!","Yes, overwrite data");
        if answer ~= "Yes, overwrite data"
            disp("Skipping...");
            continue
            %error("User Terminated: change output file name");
        else
            disp("User: Overwrite data...")
        end
    end

    %% load data 
    disp("Data reading...")
    [data_in,info] = loadParRec(char(source_location+input_filename));

    data_out = data_in.*0;
    disp("Data reading completed...")
    %% SWI
    disp("Start SWI...")
    mask = 1; % initialize mask
    for ix = 1:info.datasize(3)    
        [data_up, data_swi] = my_unwrap2(...
            data_in(:,:,ix,1,1,1,1) .* exp(1i*data_in(:,:,ix,1,1,1,2)),...
            kernel, kernel, 1, 1, ...
            1, swi ); %unwrapping and applying SWI
        if (masking == 1)
            mask = computeicmask_v2(data_in(:,:,ix,1,1,1,1), data_in(:,:,ix,1,1,1,2));
        end
        data_out(:,:,ix,1,1,1,1) = mask .* data_swi; % SWI data
        data_out(:,:,ix,1,1,1,2) = mask .* data_up; %unwrapped phase
    end
    disp("SWI finished...")
    %% write data
    % another check to not change the existing data
    if (input_filename == output_filename)
        error("User Terminated: change output file name");
    else
        disp("Data writing as "+destination_location+output_filename+"...")
        info.pardef.Technique = 'SWI';
        writeParRec(destination_location+output_filename,data_out,info);
        disp("Done...")
    end
    
    clearvars -except full_location files scan nrFiles duyn_scan_name %clear some memory
    %% error handling
    catch err
        h = errordlg('Some error occured, data not saved');
    end
end
    
