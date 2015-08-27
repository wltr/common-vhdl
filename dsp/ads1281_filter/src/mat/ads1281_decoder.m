%-------------------------------------------------------------------------------
%- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
%-
%- Description:
%- Delta-sigma decoder.
%-------------------------------------------------------------------------------

function x = ads1281_decoder(m0, m1)
% This function simulates the ADS1281 decoder
% Inputs:
% - m0: M0 input stream
% - m1: M1 input stream

m0_len = length(m0);
m1_len = length(m1);

if m0_len ~= m1_len
  error('M0 and M1 have to be of the same length.');
end

x = zeros(1, m0_len - 4);

for k = 5:m0_len
  x(k-4) = 3 * m0(k-2) - 6 * m0(k-3) + 4 * m0(k-4) + 9 * (m1(k) - 2 * m1(k-1) + m1(k-2));
end
