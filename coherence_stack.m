dfunction [zstack] = coherence_stack(base_file,dates,season)
%
%
%   Function to create x-by-y-by-n stack of coherence images for region of
%   interest. The coherence stack can entire include the entire time-series
%   of cohernece images, or else only a subset of images based on a chosen
%   season (here defined based on boreal seasons).
%
%	INPUT:
%   	base_file 		string containing directory and filename of coherence
%		dates 			dates of coherence pairs to be processed, should be strings in
%		season 			string containing the season to be processed.
%       					'winter' = DJF
%       					'spring' = MAM
%       					'summer' = JJA
%       					'autumn' = SON
%       					'annual' = JFMAMJJASOND
%
%   OUTPUT:
%		zstack			an x-by-y-by-n stack of georeferenced coherence images for either the
%						entire time-series ('annual') or a particular season (e.g., 'winter')
%
%	S. Olen, 20.11.2019



% Convert date strings into matlab dates
for i = 1:(length(dates)-1)
    matlab_dates(i) = datetime(dates{i},'InputFormat','yyyyMMdd'); % lower-case m is minutes
end
[y,m,d] = ymd(matlab_dates);

% Create list of dates dependent on season
switch season
    case 'winter'
        idx = ismember(m,[12 1 2]);
        seasonal_dates = dates(idx);
    case 'spring'
        idx = ismember(m,[3 4 5]);
        seasonal_dates = dates(idx);
    case 'summer'
        idx = ismember(m,[6 7 8]);
        seasonal_dates = dates(idx);
    case 'autumn'
        idx = ismember(m,[9 10 11]);
        seasonal_dates = dates(idx);
    case 'annual'
        seasonal_dates = dates;
end

% Create stack using the selected dates. Output will be a 3-dimensional
% array stored in a topotoolbox GRIDobj.
for i = 1:length(dates)-1
    try
        coherence_file = sprintf(base_file,dates{i},dates{i+1},corr_type,dates{i},dates{i+1});
        coherence = GRIDobj(coherence_file);
    catch
        sprintf('Coherence file for %s - %s not found...\n',dates{i},dates{i+1});
    end
    
    % Store current coherence image in stack
    if i == 1
      zstack = coherence;
    else
        coherence = resample(coherence,zstack);
	    zstack.Z(:,:,i) = coherence.Z;
    end
end

