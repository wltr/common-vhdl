%-------------------------------------------------------------------------------
%- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
%-
%- Description:
%- Transfer function.
%-------------------------------------------------------------------------------

function h = ads1281_coeff(z)
% This function generates the ADS1281 filter coefficients
% Inputs:
% - z: Array of zeros

len = length(z);
h = ones(1, z(1));

for k = 2:len
  h = conv(h, ones(1, z(k)));
end

h = [h zeros(1, 10)];
