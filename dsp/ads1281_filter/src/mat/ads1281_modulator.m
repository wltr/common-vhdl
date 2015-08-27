%-------------------------------------------------------------------------------
%- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
%-
%- Description:
%- ADS1281 delta-sigma modulator.
%-------------------------------------------------------------------------------

function [m0, m1] = ads1281_modulator(vin, vref)
% This function simulates the ADS1281 modulator
% Inputs:
% - vin: Analogue input signal
% - vref: DAC voltage reference

if nargin < 2
  vref = 2.5;
end

len = length(vin);
x = vin;

rn = ones(1, len) * vref;
rn2 = ones(1, len) * vref;
en = ones(1, len) * vref;
yn = ones(1, len);
yn2 = ones(1, len);
m0 = ones(1, len);
m1 = ones(1, len);

for k = 5:len
  % First cascaded modulator
  en(k)= x(k) - rn(k - 1);
  yn(k) = 2 * yn(k - 1) - yn(k - 2) + en(k - 2) / 3 - 2 * en(k - 3) / 3 + 4 * en(k - 4) / 9;
  m0(k) = sign(yn(k));
  rn(k) = m0(k) * vref;
  errq(k) = m0(k) - yn(k);

  % Second cascaded modulator
  en2(k) = errq(k) - rn2(k - 1);
  yn2(k) = 2 * yn2(k - 1) - yn2(k - 2) + en2(k - 2) / 3 - 2 * en2(k - 3) / 3 + 4 * en2(k - 4) / 9;
  m1(k) = sign(yn2(k));
  rn2(k) = m1(k) * vref;
  errq2(k) = m1(k) - yn2(k);
end

m0 = (m0 + 1) / 2;
m1 = (m1 + 1) / 2;
