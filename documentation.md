#Calculating potentially affected areas (PAAs)

###Set up some I/O variables

```matlab
% Base name for file directory and location. This script assumes that the base file will include
% the dates of both image pairs in the format YYYYMMDD and the coherence type, either 'phsig' or 'topophase'.
base_file = '/raid/InSAR/Iran/S1/desc_orb6/%s_%s/merged/S1_Iran_tr6_desc_Rg12_Az2_SRTM1_30m_procstep3_%s_%s_%s_UTM38N_WGS84.tif';

```
Coherence pairs to process, as date list. This program requires at least three separate SAR scenes, but runs best if a minimum of 10 scenes are used to calculate the background coherence values. The dates for the potential event should be listed separately here in event_dates and all other dates for the background coherence should be in the dates_file. Dates should be in format YYYYMMDD (string).

```matlab
% Files will need to be namedd in a systematic way. Filenames will need to
% be specified below.
dates_file = '../example_dates.dat';
event_dates = {'20171107','20171119'};  % Dates of scenes before and after the event

% Select which season to restrict the time series to.
season = 'annual';		% options 'annual','winter','spring','summer','autumn'

% File containing locations to track coherence through time for points in the landscape
% Should be entered as "lat, long" decimal degrees
loc_file = '../example_locs.dat';

% UTM zone of the region of interest 
ZONE_NUMBER = 33;
ZONE_LETTER = 'N';

% Thresholds for defining PAA regions
thresh = 1;		% 'tresh' should be in percentile (e.g., everything < 5th percentile is defined as PAA)
size_thresh = 50;	% minimum PAA size (in contiguous pixels)
```

###Construct the coherence timeseries (raster stack)
Begin by constructing a stack of all or a subset of coherence image in the time series. This can be done either for the entire time series or for specific seasons. 

```matlab
fid = fopen(dates_file);
dates = textscan(fid,'%s');
fclose(fid); 
dates = dates{1}; 

% Feed dates into the coherence stack function to construct a time-series 
% of coherence images.
stack = coherence_stack(base_file,dates,season);
```
Note that the coherence time series should not include the post-event coherence image.

###Calcualte reliability map based on the event percentiles
Calculate relaiblity map based on timeseries noise

```matlab
filterFlag = 1;
[stdmap,reliability] = reliability_map(stack,filterFlag);
```
Here we use the reliablity breaks as:

* STD < 0.1 ==> Most reliable
* 0.1 < STD < 0.2 ==> Reliable
* STD > 0.2 ==> Least Reliable

These values can be changed depending on the characteristics of the region of interest.

###Calculate the inverse percentile of the cohernece time series.
Calculate the inverse percentile of the event image with respect to the coherence time series. In other words, pixel by pixel, where does the event date fit into the distribution of coherence values for that pixel through time? e.g., 50th percentile, 10th percentile, 90th percentile of the distribution.

```matlab
% Load event coherence. In case of mismatching alignment, resample the
% event to the stack geographic bounds.
event_file = sprintf(base_file,event_dates{1},event_dates{2},event_dates{1},event_dates{2});
event = GRIDobj(event_file);
clear event_file

% Calculate the percentile of each event pixel compared to the stacked
% timeseries of coherence images.
prcMap = calculate_invrprctile(stack,event);
```
###Create timeseries of specific locations.

```matlab
% Plot coherence timeseries for locations
timeseries = pixel_timeline(base_file,dates,locs,ZONE_NUMBER,ZONE_LETTER,geocode,corr_type);
```

###Define PAA regions and write out region statistics

```matlab
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
```

