function DSP = load_sepsis_processing_params(winDuration,fullAnalysisWin,gapDuration,...
                                          pathToGitRepo)
% DESCRIPTION Load parameters for processing physiological signals in the
% DoD project. Primary emphasis on epsilons for Taut-String Estimation and
% filters for Dual-Tree Complex Wavelet Packet Transform.
%
% INPUTS
%   winDuration         floating point representing number of seconds the
%                       temporal width of the sub-window (sliding window)
%                       that the signal processing algorithms will analyze
%   fullAnalysisWin     floating point representing the duration, in 
%                       seconds, the full window that the signal processing
%                       algorithms will analyze
%   pathToGitRepo       char vector: the path name to the DOD git repo
% 
% OUTPUTS
%   DSP                 structure with various fields storing parameters 
%                       for signal processing
% 
% Language: MATLAB R209a
% OS: Windows 10
% Author: Larry Hernandez, modified by Olivia Alge
% Date: April 2020
%% Define parameters: sampling rate, window size, start time, stop time

% Sampling rate; filled later
sampleRate = get_sampling_rate('ekg_ii');

% Parameters for Taut-String Analysis of HRV Signal
DSP.epsilons_hrv = linspace(.001,.1,5); % linspace(.001,.15,5); % linspace(.001,.01,5);

% Parameters for Taut-String Analysis of ECG Signal
DSP.epsilons = linspace(.01,0.6,5); % 10.^(-5:1:-1);
DSP.numEpsilons = length(DSP.epsilons);

% Parameters for Taut-String Analysis of Arterial & Spo2 Signals
DSP.art_doTautString = true;
DSP.epsilons_art = linspace(.1,2.5,5); % linspace(0.10, 0.75, 5);
DSP.epsilons_spo2 = linspace(1,32,5); % linspace(1,32,5); % 2.^(0:5);

% Parameters for Dual-Tree Complex Wavelet Packet Transform
DSP.dtcwpt_mbands = 2;
DSP.dtcwpt_level = 2;
DSP.dtcwpt_pruneTree = 0;
DSP.dtcwpt_entropy_type = 'Renyi';
DSP.dtcwpt_entropy_params = 'Inf';
DSP.dtcwpt_filter_ecg = fullfile(pathToGitRepo, 'matlab','DTCWPacket',...
                                 'dtcwpt/','dtcwpt_filters_long.mat');
%% Parameters specific to ECG signal processing
DSP.qrs_detect_method = 'harm';
DSP.qrs_detect_correctLocation = 'true';
DSP.qrs_detect_scaleECG = 'true';
DSP.qrs_detect_filterECG = 'true';

%% Specify analysis window & time gap between event and analysis window

% FJob Array 
DSP.gap = gapDuration; % minutes
DSP.gap = seconds(DSP.gap);   % seconds
DSP.gapInSamples = time_freq_to_sample_size(sampleRate, DSP.gap);

% Which signals to analyze (Uses the convention listed in signal_type.m)
% DSP.signalsToAnalyze = {'ekg_ii'; 'art'; 'spo2'};
DSP.signalsToAnalyze = {'ekg_ii', 'art'};

% Window to Analyze
DSP.fullAnalysisWin = fullAnalysisWin; % seconds
DSP.fullAnalysisWinLen = ...
                 time_freq_to_sample_size(sampleRate, DSP.fullAnalysisWin);

% Determine size of subwindow to analyze
DSP.winDuration = winDuration;   % seconds
DSP.win_len = time_freq_to_sample_size(sampleRate, ...
                                       DSP.winDuration);
DSP.winDuration = DSP.win_len / sampleRate;

% Minimum amount of time after an adverse event that must elapse before we
% can generate a non-adverse event (non-Event) to analyze
DSP.stabilization_time = 0;  % hours
DSP.stabilization_time = hours_to_seconds(DSP.stabilization_time); %seconds

% Total length of time before an adverse event that should be used 
% exclusively for analysis; not allowed to use any of this time for 
% generating non-adverse instances (aka non-Events)
% DSP.event_zone = 0; % hours
% DSP.event_zone = hours_to_seconds(DSP.event_zone); % seconds
DSP.event_zone = DSP.fullAnalysisWin + DSP.gap; % seconds

% Parameters for Elyas's ECG Peak Detection code (based on Pan-Tompkin)
DSP.coefRmin = 0.3;
DSP.coefRmax = 1.8;
DSP.plot_figs = false;
DSP.debugging = false;
%% Some Calculations

% Create duration object for the stabilization time, event_zone
[h,m,s] = hours_minutes_seconds(DSP.stabilization_time);
DSP.stabilization_time_as_duration = duration(h,m,s);

[h,m,s] = hours_minutes_seconds(DSP.event_zone);
DSP.event_zone_as_duration = duration(h,m,s);

% Calculate minimum time needed for a nonEvent instance to reside between events
min_time_between_events = DSP.stabilization_time + ...
                          DSP.event_zone;

[nHours, nMins, nSecs] = hours_minutes_seconds(min_time_between_events);
DSP.min_time_between_events = duration(nHours, nMins, nSecs);

%% Check if the sub-window size is larger than the full window
if DSP.win_len > DSP.fullAnalysisWinLen
    error('Sliding windows cannot be longer than the entire analysis period');
end

end % eof