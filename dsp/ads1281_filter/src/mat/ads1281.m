%-------------------------------------------------------------------------------
%- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
%-
%- Description:
%- ADS1281 filter simulation.
%-------------------------------------------------------------------------------

% Reset
close all;
clear all;
fig_num = 1;

% Parameters
write_files = false;
save_figures = false;

%-------------------------------------------------------------------------------
% Create Filter

z = [1000, 736, 128, 129];
h = ads1281_coeff(z);

%-------------------------------------------------------------------------------
% Read Coefficients

b = csvread('../../res/ads1281_filter_coefficients.csv');
b = b';
b_len = length(b);

b1 = max(b) - b;

% Test filter function for symmetry
b_diff = max(abs(b) - abs([b1(1001:2000) b1(1:1000)]));
if b_diff == 0
  disp('Filter function is symmetrical.');
else
  disp('Filter function is NOT symmetrical.');
end

% Compare coefficients
h_diff = max(abs(h) - abs(b));
if h_diff == 0
  disp('Filter coefficients are similar.');
else
  disp('Filter coefficients are NOT similar.');
end

% Plot
fig = figure(fig_num);
fig_num = fig_num + 1;
set(fig, 'Name', 'Filter');

subplot(3, 1, 1);
plot(0:length(h) - 1, h);
grid on;
box on;
title('Calculated Coefficients');

subplot(3, 1, 2);
plot(0:length(b) - 1, b);
grid on;
box on;
title('CSV Coefficients (1)');

subplot(3, 1, 3);
plot(0:length(b1) - 1, b1);
grid on;
box on;
title('CSV Coefficients (2)');

if save_figures
  print -dpng filter.png
end

%-------------------------------------------------------------------------------
% Test Input

%~ % Create the input waveform
%~ ampl = 0.5;
%~ offset = 2.5;
%~ vin = [zeros(1, 1e4), 0:0.0001:1, ones(1, 1e4), 1:-0.0001:0, zeros(1, 1e4), 0:-0.0001:-1, (-1)*ones(1, 1e4), -1:0.0001:0, zeros(1, 1e4)] * ampl + offset;
%~
%~ % Modulator
%~ vref = 2.5;
%~ [am0, am1] = ads1281_modulator(vin, vref);
%~
%~ % Plot
%~ fig = figure(fig_num);
%~ fig_num = fig_num + 1;
%~ set(fig, 'Name', 'Modulator');
%~
%~ subplot(3, 1, 1);
%~ stairs(0:length(vin)-1, vin);
%~ grid on;
%~ box on;
%~ title('Input Signal');
%~
%~ subplot(3, 1, 2);
%~ stairs(0:length(am0)-1, am0);
%~ grid on;
%~ box on;
%~ title('M0');
%~
%~ subplot(3, 1, 3);
%~ stairs(0:length(am1)-1, am1);
%~ grid on;
%~ box on;
%~ title('M1');

% CSV input
m = csvread('../../res/ads1281_bitstreams/ads1281_+10V.csv', 0, 0, [0 0 5e3 1]);
m = [m; csvread('../../res/ads1281_bitstreams/ads1281_+09V.csv', 0, 0, [0 0 5e3 1])];
m = [m; csvread('../../res/ads1281_bitstreams/ads1281_+07V.csv', 0, 0, [0 0 5e3 1])];
m = [m; csvread('../../res/ads1281_bitstreams/ads1281_+05V.csv', 0, 0, [0 0 5e3 1])];
m = [m; csvread('../../res/ads1281_bitstreams/ads1281_+02V.csv', 0, 0, [0 0 5e3 1])];
m = [m; csvread('../../res/ads1281_bitstreams/ads1281_+01V.csv', 0, 0, [0 0 5e3 1])];
m = [m; csvread('../../res/ads1281_bitstreams/ads1281_+00V.csv', 0, 0, [0 0 4e3 1])];
m = [m; csvread('../../res/ads1281_bitstreams/ads1281_-01V.csv', 0, 0, [0 0 5e3 1])];
m = [m; csvread('../../res/ads1281_bitstreams/ads1281_-02V.csv', 0, 0, [0 0 5e3 1])];
m = [m; csvread('../../res/ads1281_bitstreams/ads1281_-05V.csv', 0, 0, [0 0 5e3 1])];
m = [m; csvread('../../res/ads1281_bitstreams/ads1281_-07V.csv', 0, 0, [0 0 5e3 1])];
m = [m; csvread('../../res/ads1281_bitstreams/ads1281_-09V.csv', 0, 0, [0 0 5e3 1])];
m = [m; csvread('../../res/ads1281_bitstreams/ads1281_-10V.csv', 0, 0, [0 0 5e3 1])];

if write_files
  csvwrite('input.csv', m);
end

m = (m' * 2 - 1) * (-1);

m0 = m(1, :);
m1 = m(2, :);

%-------------------------------------------------------------------------------
% Decode Input

x = ads1281_decoder(m0, m1);

%-------------------------------------------------------------------------------
% Filter

[y, p1, p2, s1, s2] = ads1281_filter(x, b);

if write_files
  dlmwrite('output.csv', y', 'delimiter', ',', 'precision', '%d', 'newline', 'pc');
end

f = filter(fliplr(b), 1, x);

% Calculate Errors
y_len = length(y);
e = zeros(1, y_len);

e(1) = abs(f(1) - y(1));
for k = 1:y_len - 1
  e(k + 1) = abs(f(k * b_len / 2) - y(k + 1));
end

% Plot
fig = figure(fig_num);
fig_num = fig_num + 1;
set(fig, 'Name', 'Output');

subplot(3, 1, 1);
stairs(0:length(f)-1, f);
grid on;
box on;
title('Matlab FIR');
axis([0 8e4 -6e9 6e9]);

subplot(3, 1, 2);
stairs(0:length(y)-1, y);
grid on;
box on;
title('MAC FIR');
axis([0 80 -6e9 6e9]);

subplot(3, 1, 3);
stairs(0:length(e)-1, e);
grid on;
box on;
title('Errors');

if save_figures
  print -dpng output.png
end
