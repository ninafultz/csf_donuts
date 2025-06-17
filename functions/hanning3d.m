function out = hanning3d( n_x, n_y, n_z, pad_array )

% Create 3d Hanning filter:
% out = hanning3d( n_x, [n_y, n_z])
% if only n_x is specified [n_x, n_y, n_z] is assumed

if (nargin == 1)
    n_y = n_x;
    n_z = n_x;
end
a = .25; %default hanning is 2    
xx = linspace(-1,1,n_x).*(a/2);
yy = linspace(-1,1,n_y).*(a/2);
zz = linspace(-1,1,n_z).*(a/2);

[x,y,z] = ndgrid(xx, yy, zz);


if n_z ==1
    out = (cos(pi.*x / a).^2) .* (cos(pi.*y / a).^2);
else
    out = (cos(pi.*x / a).^2) .* (cos(pi.*y / a).^2) .* (cos(pi.*z / a).^2);
end

if (nargin == 4)
    % center the hanning window in 3-D array. e.g. for low-pass filtering
    pad_x = size(pad_array,1);
    pad_y = size(pad_array,2);
    pad_z = size(pad_array,3);
    x_2 = floor(pad_x / 2);
    y_2 = floor(pad_y / 2);
    z_2 = floor(pad_z / 2);
    array = zeros(pad_x, pad_y, pad_z,'single');
    array(x_2-floor(n_x/2)+1 : x_2+ceil(n_x/2), y_2-floor(n_y/2)+1: y_2+ceil(n_y/2), z_2-floor(n_z/2)+1:z_2+ceil(n_z/2)) = out;
    out = array;
end

end