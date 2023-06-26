function [features,names] = art_feature_extraction(y,sigAttributes,winNum)
% DESCRIPTION   Detects peaks and extracts features from a clean arterial
%               (or Spo2) waveform.
% 
% INPUTS
%   y                   vector: clean 1-D arterial or Spo2 signal
%      
%   signalAttributes    structure containing the following fields:
%                       'SignalType' & 'sampleRate'
%
%   winNum              integer-value > 0; represents which sub-window is 
%                       being processed
% 
% OUTPUTS
%   features            structure containing Arterial or Spo2 features
%
%   names               structure containing Arterial or Spo2 feature names
%
% Language: MATLAB R2017b
% OS: Windows 10
% Author: Larry Hernandez
% Date: Jan 19, 2019
%% Detect Systolic & Dicrotic Peaks
verbose = false;
isClean = true;
[idxF,idxSys,~,idxDi,~,bpwaveform] = ...
         BP_annotate(y,sigAttributes.sampleRate,verbose,'unknown',isClean);

% Shift signal to rest above x-axis
bpwaveform = shift_above_horizontal(bpwaveform);

% Revise indices of peaks if necessary
[idxF,idxSys,idxDi] = update_dicrotic_peak_pos(bpwaveform,idxF,idxSys,idxDi);

% Find all local maxima
[Lmax,~] = GetFSABP(bpwaveform);
%% Extract Features
sigType = (sigAttributes.signalType);
[features.(sigType),names.(sigType)] = ...
                    feature_compute_art(bpwaveform,Lmax,idxSys,idxDi,...
                                        sigAttributes.sampleRate);
%% Modify names of features to reflect the type of signal that was used
names = prepend_feature_names_with_signal_type(names, ...
                                               sigAttributes.signalType, ...
                                               winNum);
                                           
end % eof