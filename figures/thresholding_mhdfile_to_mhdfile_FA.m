%% loading mhd file and thresholding



GENERALDIR = 'R:\- Gorter\- Personal folders\Fultz, N\csfdonuts_lydiane\'

allSubjects = dir([GENERALDIR '*20191022_Reconstruction']);
subjectNb = 1;
subject = allSubjects(subjectNb); 
disp(subject.name)
refScanTemp = dir([subject.folder '\' subject.name '\mhd\Scan*.mhd']);
referenceScanOrig = metaImageRead([refScanTemp.folder '\' refScanTemp.name]);
threshold = 175;

adc = dir([subject.folder '\' subject.name '\mhd\*FA*150*.mhd']);
adc = metaImageRead([adc.folder '\' adc.name]);



adc_thresh = adc .* (referenceScanOrig>threshold);

metaImageWrite(adc_thresh,[subject.folder '\' subject.name '\mhd\' 'meanFAthresh175onCSF.mhd']);


%% if mat file...

% 
% referenceScanOrig = metaImageRead([refScanTemp.folder '\' refScanTemp.name]);
% threshold = 75;
% 
% adc = dir(['R:\- Gorter\CSF_STREAM\Data' '\' subject.name '\Cardiac\T2prep\Results\*ADC*50*.mat']);
% adc = load([adc.folder '\' adc.name]);
% 
% ADC_map = adc.ADC_cardiac;
% 
% adc = mean(ADC_map, 4); 
% 
% adc_thresh = adc .* (referenceScanOrig>threshold);
% 
% metaImageWrite(adc_thresh,[subject.folder '\' subject.name '\mhd\' 'meanADCthresh75onCSF.mhd']);
