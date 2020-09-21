function [timeseries] = pixel_timeline(base_file,dates,locs,zone,hem)
%
%
%   Function to plot timeseries of a single pixel or group of pixels in a
%   timeseries stack of rasters.
%
%	INPUT:
%   	base_file		string that contains the directory and filename of the
%   					rasters
%		dates 			date strings to fill in base file
%		locs 			location coordiantes, in decimal degrees, 
%						where loc{1} = lat, loc{2} = lon.
%		zone			UTM zone
%		hem 			UTM hemisphere.
%
%	OUTPUT:	
%		timeseries 		a vector time-series of coherence values for a given location
%
%	S. Olen, 20.11.2019



%% Convert date strings into matlab dates
for i = 1:(length(dates)-1)
    matlab_dates(i) = datetime(dates{i},'InputFormat','yyyyMMdd'); % lower-case m is minutes
end
% Convert to Julian Days for later data fitting and plotting
julian_days = juliandate(matlab_dates);

clear i j cmd

%%  Start loop through pixel locations
for i = 1:length(locs{1})
    
    %%  Convert coordinates and extract raster indicies
    lat = locs{1}(i); lon = locs{2}(i);
    [utmx,utmy] = wgs2utm(lat,lon,zone,hem);
    
    % Create empty vectors
    loc_coherence_median = zeros(length(dates)-1,1);
    loc_coherence_prc25 = zeros(length(dates)-1,1);
    loc_coherence_prc75 = zeros(length(dates)-1,1);
    loc_coherence_prc10 = zeros(length(dates)-1,1);
    loc_coherence_prc90 = zeros(length(dates)-1,1);
    %%  Start loop through observation dates
    for j = 1:length(dates)-1
    
        % Load coherence file from server
        try
            coherence_file = sprintf(base_file,dates{j},dates{j+1},dates{j},dates{j+1});
            coherence = GRIDobj(coherence_file);
            if j == 1
                bounds = coherence;
            else
                resample(coherence,bounds);
            end
        catch
            sprintf('Coherence file for %s, %s does not exist...\n',dates{j},dates{j+1});
        end
        
        % Extract the row and column of the location from the grid
        [r,c] = coord2sub(coherence,utmx,utmy);
        
        % Create a window around the location pixel
        r_bounds = (r-5):(r+5);
        c_bounds = (c-5):(c+5);
%         for k = 1:length(r_bounds);
%             for l = 1:length(c_bounds);
%                 window(k,l) = coherence.Z(r_bounds(k),c_bounds(l));
%             end
%         end
        window = coherence.Z(r_bounds, c_bounds);
        
        % Calculate statistics for the window
        loc_coherence_median(j) = nanmedian(nanmedian(window));
        loc_coherence_prc25(j) = prctile(prctile(window,25),25);
        loc_coherence_prc75(j) = prctile(prctile(window,75),75);
        loc_coherence_prc10(j) = prctile(prctile(window,10),10);
        loc_coherence_prc90(j) = prctile(prctile(window,90),90);
        
    end
    
    %% Save in a structure for exporting
     cmd = ['timeseries.loc',num2str(i),'.median = loc_coherence_median']; eval(cmd); clear cmd
     cmd = ['timeseries.loc',num2str(i),'.prc10 = loc_coherence_prc10']; eval(cmd); clear cmd
     cmd = ['timeseries.loc',num2str(i),'.prc25 = loc_coherence_prc25']; eval(cmd); clear cmd
     cmd = ['timeseries.loc',num2str(i),'.prc75 = loc_coherence_prc75']; eval(cmd); clear cmd
     cmd = ['timeseries.loc',num2str(i),'.prc90 = loc_coherence_prc90']; eval(cmd); clear cmd
    
    %%
    p(i) = polyfit(julian_days,loc_coherence_median)
    x = julain_days(1):julaindays(length(julian_days));
    xfun = p(1)*julian_days + p(2);
    
    %%  Make a timeseries plot for the location
    fig = figure('Visible','Off');
    p = plot(matlab_dates,loc_coherence_median,'k-','LineWidth',2,'Marker','o');
    set(p,'MarkerFaceColor','w')
    hold on
    grid on
    plot(matlab_dates,loc_coherence_prc10,'k:');
    plot(matlab_dates,loc_coherence_prc25,'k--');
    plot(matlab_dates,loc_coherence_prc75,'k--');
    plot(matlab_dates,loc_coherence_prc90,'k:');
    plot(matlab_dates,xfun,'--r');
    xlabel('Date')
    ylabel('Local Coherence')
    title(['Coherence for ',num2str(locs{1}(i)),', ',num2str(locs{2}(i))]);
    set(gca,'FontSize',12);
    legend('Median Coherence','10th Percentile','25th Percentile','75th Percentile','90th Percentile','Location','SouthOutside')
    
    cmd = ['export_fig timeseries_loc_',num2str(locs{1}(i)),'_',num2str(locs{2}(i)),'_',geocode,'_',corr_type,'.png'];
    eval(cmd); clear cmd
    
    print(fig,['timeseries_loc_',num2str(locs{1}(i)),'_',num2str(locs{2}(i)),'_',geocode,'_',corr_type,'.eps'],'-depsc');
    
    
end
end
