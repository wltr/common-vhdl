%-------------------------------------------------------------------------------
%- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
%-
%- Description:
%- ADS1281 filter.
%-------------------------------------------------------------------------------

function [y, p1, p2, s1, s2] = ads1281_filter(x, b)
% This function filters the ADS1281 input
% Inputs:
% - x: Decoded input data
% - b: Coefficients

b_len = length(b);
x_len = length(x);

if x_len < b_len
  error('Input length has to be bigger than number of coefficients.');
end

t = floor(x_len / b_len);
y1 = zeros(1, t);
y2 = zeros(1, t);
p1 = zeros(1, t * b_len);
p2 = zeros(1, t * b_len);
s1 = zeros(1, t * b_len);
s2 = zeros(1, t * b_len);

% First interleaved filter
j = 1;
for k = 1:b_len:x_len - b_len
  p = x(k:k + b_len - 1) .* b;

  s = zeros(1, b_len);
  s(1) = p(1);
  for i = 2:b_len
    s(i) = s(i - 1) + p(i);
  end

  s1(k:k + b_len - 1) = s;
  p1(k:k + b_len - 1) = p;
  y1(j) = sum(p);
  j = j + 1;
end

% Second interleaved filter
p = x(1:b_len / 2) .* b(b_len / 2 + 1:b_len);

s = zeros(1, b_len / 2);
s(1) = p(1);
for i = 2:b_len / 2
  s(i) = s(i - 1) + p(i);
end

s2(1:b_len / 2) = s;
p2(1:b_len / 2) = p;
y2(1) = sum(p);
j = 2;
for k = b_len / 2 + 1:b_len:x_len - b_len
  p = x(k:k + b_len - 1) .* b;

  s = zeros(1, b_len);
  s(1) = p(1);
  for i = 2:b_len
    s(i) = s(i - 1) + p(i);
  end

  s2(k:k + b_len - 1) = s;
  p2(k:k + b_len - 1) = p;
  y2(j) = sum(p);
  j = j + 1;
end
p = x(t * b_len - b_len / 2 + 1:t * b_len) .* b(1:b_len / 2);

s = zeros(1, b_len / 2);
s(1) = p(1);
for i = 2:b_len / 2
  s(i) = s(i - 1) + p(i);
end

s2(t * b_len - b_len / 2 + 1:t * b_len) = s;
p2(t * b_len - b_len / 2 + 1:t * b_len) = p;

y = [y2; y1];
y = [0 y(:)'];
