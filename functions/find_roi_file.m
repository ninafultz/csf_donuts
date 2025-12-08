% Function to find ROI file with either extension
function roi_file = find_roi_file(base_path)
    nii_file   = [base_path '.nii'];
    niigz_file = [base_path '.nii.gz'];
    
    if exist(nii_file, 'file')
        roi_file = nii_file;
    elseif exist(niigz_file, 'file')
        roi_file = niigz_file;
    else
        error('No ROI file found: %s(.nii or .nii.gz)', base_path);
    end
end