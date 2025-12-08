% THIS SCRIPT IS TO GET vis ctx 

clear
subjects(:,1) = {'20201008', '20201014','20201016','20201019','20201020','20201110'}; %1st column=cardiac/respi

GENERALDIR = 'R:\- Gorter\CSF_STREAM\Data\';
tmpSubCardiac = dir([GENERALDIR '*_Reconstruction']);

for s=1:size(tmpSubCardiac,1)
    tmp = strsplit(tmpSubCardiac(s).name,'_');
    allSubjectsCardiac(s,:) = str2double(tmp{1});
end

tmpSubVisStim = dir([GENERALDIR 'VisualStim\' '2020*']);
for s=1:size(tmpSubVisStim,1)
    allSubjectsVisStim(s,:) = str2double(tmpSubVisStim(s).name);
end

for s=1:size(subjects,1)
    subjNb(s,1) = find(allSubjectsCardiac== str2double(subjects(s,1)));
end

for i=2:3
    if i == 1
        physioFolder = '\Cardiac\T2prep';
        physio = 'cardiac';
    elseif i == 2
        physioFolder = '\Respiration';
        physio = 'respi';
    elseif i == 3
        physioFolder = '\Random';
        physio = 'random';
    end
    
    nameFolderFit = 'fitAllROIs5\';
    numPhase = 6; %61;
    
    ADC_FA_ROImean = nan(numel(subjects(:,1)),numPhase,2); %6 phases
    ADC_FA_ROIstd= nan(numel(subjects(:,1)),numPhase,2);
    numVoxelsROI_ADC = nan(numel(subjects(:,1)),2);
    NbSub = 0;
    
    for s = 1:size(subjNb,1)
        subject = tmpSubCardiac(subjNb(s,1));
        disp(subject.name)
        NbSub = NbSub+1;            
        csfScanVisStim = ['R:\- Gorter\- Personal folders\Fultz, N\csfdonuts_lydiane' subject.name '\ROIs\' 'm1_left_externaldonut.nii'];
        disp(csfScanVisStim)
        ROI_VC = flip(flip(permute(niftiread(csfScanVisStim),[3 2 1]),1),3);
        roi2use = ROI_VC>0;
         
        %% Get ADC and FA
        for param = 1:2
            if param == 1
                data2processTemp = load([subject.folder '\' subject.name  physioFolder '\Results\' 'ADC_' physio 'Thres50.mat']);
                data2processTemp = eval(['data2processTemp.ADC_' physio]);
                %                 ROIsize1Save = size(ROIs,1);
            elseif param == 2
                data2processTemp = load([subject.folder '\' subject.name  physioFolder '\Results\' 'FA_' physio 'Thres50.mat']);
                data2processTemp = eval(['data2processTemp.FA_' physio]);
            end            
 
            data2use = data2processTemp;
            clearvars data2processTemp
            
  
            reshapeSize = [size(data2use,1)*size(data2use,2)*size(data2use,3),size(data2use,4)];
            
            
            tmp=reshape(data2use.* repmat(roi2use, 1,1,1,size(data2use,4)), reshapeSize);
            tmp(tmp==0)=NaN;
            tmp(isnan(tmp(:,1)),:)=[];

            v = tmp;
            [~, maxPhase] = max(tmp,[],2);
            
            for vox = 1:size(v,1)
                     tmpShifted(vox,:) = circshift(v(vox,:),-maxPhase(vox),2);
            end

            if size(v,1)>0
                ADC_FA_ROImean(s,:,param)=nanmean(tmpShifted,1);
                ADC_FA_ROIstd(s,:,param)=nanstd(tmpShifted,1);
                numVoxelsROI_ADC(s,param) = numel(find(~isnan(tmpShifted(:,1))));
            end
            %individualData(s,:,1,param,1:numel((find(~isnan(tmp(:))))))=tmp(~isnan(tmp(:)));
            clear tmp tmpShifted tmpPhase maxPhase
        end
        
        clear roi2use data2use v vq2 xq ROI_VC
    end
end
