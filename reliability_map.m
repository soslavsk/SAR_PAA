function [stdcoh,reliabilityMap] = reliability_map(stack,filter_flag)
%
%
%   Function to calculate the reliability of damage estimates for a region
%   of interest. Reliability is deternined pixel-by-pixel based on the standard deviation of
%   coherence images within the time-series. The standard reliability
%   breaks are defined below, but can be edited if the user wishes.
%
%	Here we use the reliablity breaks as:
%			STD < 0.1 ==> Most reliable
%			0.1 < STD < 0.2 ==> Reliable
%			STD > 0.2 ==> Least Reliable
%	These values can be changed depending on the characteristics of the region of interest.
%
%
%   INPTUS
%       stack           stack of coherence images created by the
%                       coherence_stack.m function
%       filter_flag     flag to filter data or not (1 = filter, 0 = no filter).
%
%   OUTPUTS
%       stdcoh          GRIDobj map of standard deviation of the time
%                       series
%       reliabilityMap  Reclassified reliability map
%
%   S. Olen, 12.12.2019


stdcoh = stack; stdcoh.Z = [];
stdcoh.Z = nanstd(stack.Z,0,3);

% filter data
if filter_flag == 1
    stdcoh = filter(stdcoh,'mean',[5 5]);
end

reliabilityMap = stdcoh; 
% Define most reliable as area with stadard deviation < 0.1
idx = stdcoh.Z < 0.1;
reliabilityMap.Z(idx) = 100;
clear idx

% Define second most reliable as area with stadard deviation 0.1 <=, < 0.2
idx = stdcoh.Z >= 0.1 & stdcoh.Z < 0.2;
reliabilityMap.Z(idx) = 200;
clear idx

% Define least reliable as area with stadard deviation >= 0.2
idx = stdcoh.Z >= 0.2;
reliabilityMap.Z(idx) = 300;
clear idx

