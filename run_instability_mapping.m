%   run_instability_mapping.m
%   S. Olen, 07.02.2018
%
%   Script to use interferometric coherence pairs to calculate potential
%   locations of instabilities following a natural hazard event (e.g.,
%   mudslide, earthquake, landslides), using the pixel-by-pixel
%   distribution of coherence preceiding the event.
%
%   This script requires Topotoolbox v.2 (https://topotoolbox.wordpress.com/)
%   ...BrewerMap (https://www.mathworks.com/matlabcentral/fileexchange/45208-colorbrewer-attractive-and-distinctive-colormaps)



%%  Part 0: User-defined parameters

% Sensor (e.g., 'S1' for Sentinel-1, 'TSX' for TerraSar-X)
sensor = 'S1';

% Base name for file directory and location. This script assumes that the base file will include
% the dates of both image pairs in the format YYYYMMDD and the coherence type, either 'phsig' or 'topophase'.
base_file = '/raid/InSAR/Iran/S1/desc_orb6/%s_%s/merged/S1_Iran_tr6_desc_Rg12_Az2_SRTM1_30m_procstep3_%s_%s_%s_UTM38N_WGS84.tif';

% Geocoding units used
geocode = 'Rg12Az2';	% corresponds to multilooking used (Range 12, Aximuth 2)
season = 'annual';		% options 'annual','winter','spring','summer','autumn'
corr_type = 'phsig';	% 'phsig' or 'topophase' depending on coherence used

% Coherence pairs to process, as date list. This program requires at least
% three separate SAR scenes, but runs best if a minimum of 10 scenes are used
% to calculate the background coherence values. The dates for the potential event
% should be listed separately here in event_dates and all other dates for the background
% coherence should be in the dates_file. Dates should be in format YYYYMMDD (string).
%
% Files will need to be namedd in a systematic way. Filenames will need to
% be specified below.
dates_file = '../example_dates.dat';
event_dates = {'20171107','20171119'};  % Dates of scenes before and after the event

% File containing locations to track coherence through time for points in the landscape
% Should be entered as "lat, long" decimal degrees
loc_file = '../example_locs.dat';

% UTM zone of the region of interest 
ZONE_NUMBER = 33;
ZONE_LETTER = 'N';

% Thresholds for defining PAA regions
thresh = 1;		% 'tresh' should be in percentile (e.g., everything < 5th percentile is defined as PAA)
size_thresh = 50;	% minimum PAA size (in contiguous pixels)



%% Part 1:  Read in dates and locations to be processed

fid = fopen(dates_file);
dates = textscan(fid,'%s');
fclose(fid); clear dates_file;
dates = dates{1}; clear fid

fid = fopen(loc_file);
locs = textscan(fid,'%f%f%s','delimiter',',');
fclose(fid); clear loc_file fid



%%  Part 3: Create stack, percentile map, and a regional reliability estimate

% Create 3-dimensional stack of coherence images.
stack = coherence_stack(base_file,dates,season,geocode,corr_type);

% Load event coherence. In case of mismatching alignment, resample the
% event to the stack geographic bounds.
event_file = sprintf(base_file,event_dates{1},event_dates{2},event_dates{1},event_dates{2});
event = GRIDobj(event_file);
event = resample(event,stack);
clear event_file

% Calculate the percentile of each event pixel compared to the stacked
% timeseries of coherence images.
prcmap = calculate_invprctile(stack,event,season,geocode,corr_type);

% Calculate relaiblity map based on timeseries noise
[stdmap,reliability] = reliability_map(stack,geocode,season,corr_type,1);



%%  Part 4: Create timeseries of specific locations.

% Plot coherence timeseries for locations
timeseries = pixel_timeline(base_file,dates,locs,ZONE_NUMBER,ZONE_LETTER,geocode,corr_type);



%%	Part 5: Define PAA regions and write out region statistics

% Define PAA regions, including coherence threshold and minimum PAA size trehshold
% 'tresh' should be in percentile (e.g., everything < 5th percentile is defined as PAA)
% 'size_thresh' is the minimum PAA size (in contiguous pixels)
% 
[regions,stats] = regions(prcmap,thresh,size_thresh);

fid = fopen('paa_stats_table.csv','w');
fprintf(fid,'ID,Area,Filled Area,Centroid UTM,Centroid UTM,Centroid DEG,Centroid DEG,ID_2,Population Density,Mean Coh,MinCoh,StdCoh\n');
for i = 1:length(stats)
    ID = stats(i).ID;
    area = stats(i).Area;
    farea = stats(i).FilledArea;
    centr_utm = stats(i).Centroid_UTM;
    centr_deg = stats(i).Centroid_DEG;
    ID_2 = paa_stats(i).ID;
    pop = paa_stats(i).Populatoin_Density_ppl_sqkm;
    cohmean = paa_stats(i).MeanCoh;
    cohmin = paa_stats(i).MinCoh;
    cohstd = paa_stats(i).StdCoh;
    
    fprintf(fid,'%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n',ID,area,farea,centr_utm(1),centr_utm(2),centr_deg(1),centr_deg(2),ID_2,pop,cohmean,cohmin,cohstd);
end

% print_stats = rmfield(stats,'FilledImage');
% struct2csv(print_stats,'Iran_Rg12Az_desc6_psig_stats.csv')
% struct2csv(paa_popstats,'Iran_Rg12Az_desc6_psig_population_stats.csv')