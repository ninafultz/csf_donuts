function mask = computeicmask_v2(mag,phi,Parenchyma_Only)
% function mask = ComputeICMask(mag,phi,Parenchyma_Only)

% Changes
% 29/09/09: Initial release (JM)
% 30/09/09: Added Parenchyma_Only swith in order to include the skull
%           when needed (JM)

if nargin==2
    Parenchyma_Only = 1;
end

mask = zeros(size(phi),'single');
%phi = FourierUnwrap(mag,phi,[1 1]*max(size(phi)));

%(mag,phi,[1 1]*max(size(phi)));

sig_mag = std(mag(:));
sig_phi = std(phi(:));

if 0 % Example of OR operator on the masks instead of AND
    tmp = zeros(size(phi));
    tmp(abs(mag(:))>sig_mag) = 1;
    tmp(abs(phi(:))<sig_phi) = tmp(abs(phi(:))<sig_phi)+1;
    figure, imagesc(tmp)
end

mask(abs(mag(:))>sig_mag) = 1;
mask(abs(phi(:))>sig_phi) = 0;

if Parenchyma_Only
    mask = bwlabeln(mask);

    v = hist(mask(:),max(mask(:))+1);
    v(1) = 0;
    n = find(v(:)==max(v))-1;

    mask(mask(:)~=n) = 0;
    mask = mask/n;
end

for i=1:size(mask,3)
    mask(:,:,i) = imfill(mask(:,:,i));
end

return