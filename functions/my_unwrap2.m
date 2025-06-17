function [out, swi_image] = my_unwrap2( in, x_f, y_f, z_f, twoD, create_SWI, swi_factor )
% Unwrap 3-D complex data using FFT approach
% function out = my_unwrap( in, x_f, y_f, z_f, twoD )
% A 3-D hanning filter is constructed and is used to highpass filter
% the complex data

% get rid of possible NaN's and replace by 0's
in(isnan(in)) = 0;

if nargin == 4;
    twoD = 0;
    create_SWI = 0;
end
out = in.*0;
if (twoD)
    for idx = 1:size(in,3)
    my_filter = squeeze(hanning3d( x_f, y_f, 1, in(:,:,idx)));        
    kspace = fftshift(fftn(in(:,:,idx)));
    kspace = kspace.* my_filter;
    clear my_filter
    temp = ifftn(ifftshift(kspace));
    clear kspace
    out(:,:,idx) = angle(in(:,:,idx) ./ temp);    
    end
else
    my_filter = hanning3d( x_f, y_f, z_f, in);
    kspace = fftshift(fftn(in));
    kspace = kspace.* my_filter;
    clear my_filter
    kspace = ifftshift(kspace);
    out = ifftn((kspace));
    clear kspace
    out = in./out;
    out = angle(out);
end

if (create_SWI)
    % All the phases <= 0 should be one:
    % the phases > 0 should be (pi-phi(x))/pi
    phase_mask = (pi - (out .* (out > 0)) ) / pi; %was < 0
    phase_mask(out < 0) = 1; %new
    %select out all the values greater then zero and linearize them between 0 and zero (pi-phi(x))/pi
    % now enhance the original image with the phase mask      
    swi_image = (phase_mask .^ swi_factor) .* abs(in);
end
clear temp
clear my_filter
clear kspace
end


