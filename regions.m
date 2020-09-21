function [regions,paa_stats] = regions( prcmap,thresh,size_thresh )
%
%   Function to identify the potentially affected areas (PAAs) based on the
%   inverse percentile map of the event coherence.
%
%   INPUTS
%       'prcmap'            the map of inverse percentile values
%       'tresh'             should be in percentile (e.g., everything < 5th percentile is defined as PAA)
%       'size_thresh'       the minimum PAA size (in contiguous pixels)
%
%   OUTPUTS
%       regions             map of PAAs in which each PAA has a unique
%                           integer ID
%       paa_stats           table containing relevant stats of each PAA
%
%
%   S. Olen, 12.12.2019

%%
% Create binary image of 'damage' based on percentile threshold (e.g., only
% regions < 5th percentile of coherence distribution are 'damaged regions')
binary_image = prcmap < thresh;

% Calculate connected components of the binary image
conncomp = binary_image; conncomp.Z = [];
conncomp.Z = bwlabel(binary_image.Z);
regions = conncomp;

%%
numeldb = nanmax(nanmax(regions.Z));
for i = 1:numeldb
    idx = regions.Z == i;
    if size(regions.Z(idx)) <= size_thresh
        regions.Z(idx) = 0;
    end
end
clear numeldb

%%


% Calculate region properties of each connected components
stats = regionprops(regions.Z,prcmap.Z,...
    'area',... % Scalar; the actual number of pixels in the region
    'centroid',... % 1-by-Q vector that specifies the center of mass of the region.
    'Eccentricity',... %  Scalar that specifies the eccentricity of the ellipse that has the same second-moments as the region.
    'FilledArea',... % Scalar specifying the number of on pixels in FilledImage.
    'FilledImage',... % Binary image (logical) of the same size as the bounding box of the region.
    'MajorAxisLength',... % Scalar specifying the length (in pixels) of the major axis of the ellipse that has the same normalized second central moments as the region. 
    'Orientation',... % Scalar; the angle (in degrees ranging from -90 to 90 degrees) between the x-axis and the major axis of the ellipse that has the same second-moments as the region.
    'MaxIntensity',... % Maximum prctile included in region
    'MeanIntensity',... % Mean prctile of reagion
    'MinIntensity');    % Minimum prctile in region

% Extract UTM zone from the GRIDobj
% splitStr = regexp(prcmap.georef.GeoKeyDirectoryTag.GTCitationGeoKey,' ','split');
% zone = num2str(splitStr{3}); clear splitStr

% Convert centroid locations to grid coordinates (typically UTM);
for i = 1:length(stats)
    [centroid(i,1),centroid(i,2)] = sub2coord(prcmap,round(stats(i).Centroid(1)),round(stats(i).Centroid(1)));
    [centroid_deg(i,1),centroid_deg(i,2)] = utm2deg(centroid(i,1),centroid(i,2),'38 N' );
end

%%
count = 0;
for i = 1:length(stats)
    if stats(i).Area ~= 0
        count = count +1;
        paa_stats(count) = stats(i);
        idx_passsize(count) = i;
    end
end

%%
try
    for i = 1:numel(idx_passsize)
        j = idx_passsize(i);
        paa_stats(i).Centroid_UTM = centroid(j,:);
        paa_stats(i).Centroid_DEG = centroid_deg(j,:);
        paa_stats(i).ID = j;

    end
catch
    paa_stats = NaN;
end

