function [features,names] = ...
                      feature_compute_art(x,Lmax,primary,secondary,smpRate)
% DESCRIPTION   Feature extraction on preprocessed arterial waveform
%
% INPUTS
%   x           vector: pre-processed arterial signal
%      
%   Lmax        vector: indices of local maxima
%   
%   primary     vector: indices of primary peaks of x
% 
%   secondary   vector: indices of secondary peaks of x
% 
%   smpRate     floating point number: sampling rate
%
% OUTPUTS
%     features  1xN array of numbers representing the calculated features
% 
%     names     Nx1 cell containing the names of the calculated features
%
% Language: MATLAB R2017b
% OS: Windows 10
% Author: Larry Hernandez
% Date: Dec 18, 2018
%% Compute Features

% Time between consecutive first peaks 'p1'
dt = diff(primary);
if isempty(dt)
    dt = nan;
end
mean_dt_p1p1 = mean(dt) / smpRate;
med_dt_p1p1 = median(dt) / smpRate;
std_dt_p1p1 = std(dt) / smpRate;
max_dt_p1p1 = max(dt) / smpRate;
min_dt_p1p1 = min(dt) / smpRate;

% Time between first peak (p1) and secondary peak (p2) in cycle
n = length(secondary);
dt = secondary - primary(1:n);
if isempty(dt)
    dt = nan;
end
mean_dt_p1p2 = mean(dt) / smpRate;
med_dt_p1p2 = median(dt) / smpRate;
std_dt_p1p2 = std(dt) / smpRate;
max_dt_p1p2 = max(dt) / smpRate;
min_dt_p1p2 = min(dt) / smpRate;

% Relative amplitude between consecutive primary peaks (p1)
ra = x(primary(1:end-1)) ./ x(primary(2:end));
if isempty(ra)
    ra = nan;
end
mean_ra_p1p1 = mean(ra);
med_ra_p1p1 = median(ra);
std_ra_p1p1 = std(ra);
max_ra_p1p1 = max(ra);
min_ra_p1p1 = min(ra);

% Relative amplitude between Primary (p1) and Secondary peak (p2)
ra = x(primary(1:n)) ./ x(secondary);
if isempty(ra)
    ra = nan;
end
mean_ra_p1p2 = mean(ra);
med_ra_p1p2 = median(ra);
std_ra_p1p2 = std(ra);
max_ra_p1p2 = max(ra);
min_ra_p1p2 = min(ra);

% Total number of peaks
nPeaks = length(Lmax);

% Pack features and names
features = [mean_dt_p1p1, med_dt_p1p1, std_dt_p1p1, max_dt_p1p1, min_dt_p1p1, ...
            mean_dt_p1p2, med_dt_p1p2, std_dt_p1p2, max_dt_p1p2, min_dt_p1p2, ...
            mean_ra_p1p1, med_ra_p1p1, std_ra_p1p1, max_ra_p1p1, min_ra_p1p1, ...
            mean_ra_p1p2, med_ra_p1p2, std_ra_p1p2, max_ra_p1p2, min_ra_p1p2, ...
            nPeaks];

names = [cellstr('mean_dtP1P1'); cellstr('med_dtP1P1'); cellstr('std_dtP1P1'); cellstr('max_dtP1P1'); cellstr('min_dtP1P1');...
         cellstr('mean_dtP1P2'); cellstr('med_dtP1P2'); cellstr('std_dtP1P2'); cellstr('max_dtP1P2'); cellstr('min_dtP1P2');...
         cellstr('mean_relAmpP1P1'); cellstr('med_relAmpP1P1'); cellstr('std_relAmpP1P1'); cellstr('max_relAmpP1P1'); cellstr('min_relAmpP1P1');...
         cellstr('mean_relAmpP1P2'); cellstr('med_relAmpP1P2'); cellstr('std_relAmpP1P2'); cellstr('max_relAmpP1P2'); cellstr('min_relAmpP1P2'); ...
         cellstr('numPeaks')];

end % eof