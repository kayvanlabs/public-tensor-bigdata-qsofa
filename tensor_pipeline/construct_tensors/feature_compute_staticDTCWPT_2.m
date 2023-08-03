function features=feature_compute_staticDTCWPT_2(tautStringsSignals)
% DESCRIPTION It extracts DTCWPT features from the CWR dataset to construct
% tensors. This file is based off of a similar file in the DOD repository 
% written by Larry. The reason it was rewritten is to change how parameters
% are passed to the mdtcWavePacket object there is no dsp object here.
%
% For each numerical value in 'widths', calculates Taut-String
% estimate of the input signal 'hrv' and returns statistical features
% derived from this Taut-String estimate. The features are meant for use in
% machine learning models.
%
% INPUTS
%     tautStringsECG       2-array containing all of the taut-string estimates
%     dsp    
% OUTPUTS
%     features  1xN array of numbers representing the calculated features
%     names     Nx1 cell containing the names of the calculated features
%
% OS: Windows 10
% Language: Matlab R2017b 
% Original Author: Larry Hernandez
% Date: Sep 14, 2018
%
% Modified by: Joshua Pickard
% Feb 2022
%% Set DSP Object

dsp.dtcwpt_mbands = 2;
dsp.dtcwpt_level = 2;
dsp.dtcwpt_pruneTree = 0;
dsp.dtcwpt_entropy_type = 'Renyi';
dsp.dtcwpt_entropy_params = 'Inf';
if ispc
    dsp.dtcwpt_filter_ecg = 'Z:\Projects\DoD_Multimodal\Code\Larry\DOD\matlab\DTCWPacket\dtcwpt\dtcwpt_filters.mat';
else
    dsp.dtcwpt_filter_ecg = '/nfs/turbo/med-kayvan-lab/Projects/DoD_Multimodal/Code/Larry/DOD/matlab/DTCWPacket/dtcwpt/dtcwpt_filters.mat';
end
% dsp.dtcwpt_filter_ecg = 'H:\My Documents\DOD\matlab\DTCWPacket\dtcwpt\dtcwpt_filters.mat';

% Old code
% Initialize empty arrays for storing data
features = [];     
names = [];

for idx = 1:min(size(tautStringsSignals)) %length(tautStringsSignals)
    
    % Initialize a wavelet packet worker
    wpworker = mdtcWavePacket(dsp.dtcwpt_mbands, ...
                              dsp.dtcwpt_level, ...
                              dsp.dtcwpt_filter_ecg);
    wpworker.entropy_type = dsp.dtcwpt_entropy_type;
    wpworker.entropy_params = dsp.dtcwpt_entropy_params;
    wpworker.initialize(length(tautStringsSignals(idx,:)));
    
    % Decompose the signal with the wavelets
    wpworker.loadTrees(tautStringsSignals(idx,:), dsp.dtcwpt_pruneTree);

    % Export the wavelet features
    [dtcwptFeatures, ~] = wpworker.extractFeatures();
    
    % Reconstruct the signal
    % [s, ~] = wpworker.synthesizeSignal();
    
    % Append epsilon values to the feature names
    % dtcwptNames = strcat(dtcwptNames, '_StaticEpsilon_', num2str(dsp.epsilons(idx)));
    
    % Aggregate feature values. Aggregate feature names.
    features = [features; dtcwptFeatures];
    % names = [names; dtcwptNames];
end

end % eof