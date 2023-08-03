% New ECG noise annotation function
%
% Required helper functions:
% get_binary_pos.m
% pan_tompkin.m
% check_r_gaps.m
%
% Inputs:
%   ecg - 1D vector containing preprocessed ECG segment. Cannot be
%         shorter in length than [wl].
%   Fs  - sampling frequency (number of samples per second) i.e. 240 Hz
%   wl  - window length in samples (i.e. wl of 10 sec => Fs*10).
%         Should be at least 5 sec long
%
% Outputs:
%   noisy   - 1D vector with length of input [ecg]. values 0 if non-noisy, 1 if noisy
%   R       - 1D vector containing R peak indices found by pan-tompkins algo
%   amp     - 1D vector with length of input [ecg]. 0 if amplitude thresholds
%             met, 1 if amplitude thresholds exceeded
%   tp      - 1D vector containing indices of significant turning points
%             (inflection points right before large amplitude changes)
%   noisy_w - 2D matrix with [floor(length(ecg)/wl)] rows and 3 columns.
%             1st col is amplitude, 2nd col is tp density, 3rd col is R-R gaps.
%             Value 1 at row 2, col 3 means window 2 was marked noisy because of 
%             its R-R gaps. Non-noisy window has zeros in all columns.
%   new_ecg - input ecg smoothed by Savitsky-Golay filter
%
% Description:
% Divides input [ecg] into multiple windows with length [wl].
% Finds R peak indices in each window using pan-tompkins algorithm.
% Labels each window noisy or non-noisy based on heuristic thresholds
% in peak amplitude, curve inflection point density, and R-R gaps.
%
% 3 classes of noise/abnormal ecg:
%   0 - no noise detected
%   1 - high amplitude
%   2 - high frequency
%   3 - irregular periodicity
%
% Winston Zhang April 6th, 2020

function [noisy,R,amp,tp,noisy_w,new_ecg] = new_noise_detect_WZ_shared(ecg, Fs, wl)

    ECG_L = length(ecg);  % ecg length

    % initialize output vars
    noisy = zeros(ECG_L,1);
    R = [];
    amp = zeros(ECG_L,1);
    tp = [];
    
    % check number of inputs
    if nargin == 2
        wl = 30*Fs;
    elseif nargin < 2
        disp('too few args');
        return
    end
    
    % check if inputs are valid
    if ~isvector(ecg) || Fs < 1 || wl < 5*Fs
        disp('invalid input arguments');
        return
    end

    % ///// begin noise detection hyperparameters /////
    
    
    % thresholds
    POSAMP_T         = 5.00;  % percent amp of avg r high to mark as noisy
    NEGAMP_T         = 10.0;  % percent amp of avg r low to mark as noisy
    FLATAMP_T        = 0.02;  % percent amp of avg r high to mark as flat
    
    FLATTIME_T       = 2.50;  % percent length of avg beat duration flat to mark as noisy
    
    TP_DIFF_T        = 0.30;  % percent amp of avg r peak for peak to be significant
    R_TP_RATE_T      = 15.0;  % num of significant turning pts per R peak
    R_HIGH_TP_RATE_T = 10.0;  % num sig turning pts for sig tp sum check
    R_SUM_T          = 0.20;  % area under ecg signal per R beat
    
    INT_AVG_T        = 3.00;  % mean area under ecg signal greater than X percent R height

    SGLY_ORD_T       = 3.00;  % sgolay filter order
    SGLY_FLEN_T      = 11.0;  % sgolay filter frame length
    
    RRGAP_T          = 2.50;  % RR interval gap threshold in sec
    
    % heart rate thresholds
    HIGHHR_T = 250;
    LOWHR_T = 20;
    

    % ///// end noise detection hyperparameters /////
    
    
    % init vars
    if size(ecg, 2) > size(ecg,1)
        ecg = ecg';
    end
    ecg = double(ecg);
    WIN_L = wl;  % window length
    NUM_W = floor(ECG_L/WIN_L);
    
    % smooth out ecg to get rid of high freq noise
    ecg = sgolayfilt(ecg,SGLY_ORD_T,SGLY_FLEN_T);
    
    % get average peak highs and lows
    tempecg = ecg(1:ECG_L - rem(ECG_L, WIN_L));
    tempecg = reshape(tempecg, [], NUM_W);
    % remove flat signal windows
    temp_w_means = mean(abs(tempecg),1);
    tempecg(:,temp_w_means < 0.002) = [];
    maxpeakamps = max(tempecg, [], 1);
    minpeakamps = min(tempecg, [], 1);
    maxpeakamps = rmoutliers(maxpeakamps);
    minpeakamps = rmoutliers(minpeakamps);
    
    AVG_R_HIGH = mean(maxpeakamps);
    AVG_R_LOW = mean(minpeakamps);
    
    % basic checks to save cpu time
    if ECG_L < WIN_L || sum(ecg) == 0
        noisy = ones(ECG_L,1);
        R = [];
        amp = [];
        tp = [];
        noisy_w = [];
        new_ecg = [];
        return
    end
    
    
    % CLASS 1 AMPLITUDE
    lowampecg = abs(ecg) < FLATAMP_T*AVG_R_HIGH;
    flat_pos = get_binary_pos(lowampecg,1);
    
    if AVG_R_HIGH < 0.1
        AVG_R_HIGH = 0.2;
    end
    amp_lbl = ecg > 2 | ecg > AVG_R_HIGH*POSAMP_T | ecg < AVG_R_LOW*NEGAMP_T;

    
    % CLASS 2 FREQUENCY
    % get all turning points (pos and neg peaks)
    firstdiff = diff([0;ecg])./diff([0;(1:length(ecg))']);
    signd = sign(firstdiff)';
    negpos = strfind(signd,[-1 1]);
    posneg = strfind(signd,[1 -1]);
    all_tp = sort([negpos'; posneg']);
    % find diff of tp magnitudes, higher variance = more noisy
    tp_mags = ecg(all_tp);
    tp_diffs = abs(diff([0;tp_mags]));
    sig_tps = tp_diffs > TP_DIFF_T*AVG_R_HIGH;
    sig_tp_i = all_tp(sig_tps);
    
    % average area under abs signal per second
    sig_integral = movmean(abs(ecg),Fs);
    

    
    %%%%%%%%%% WINDOWED ANALYSIS %%%%%%%%%%
    
    % initialize arrays for parfor
    noisy_w = zeros(NUM_W,3);  % 3 types of noise
    R_out_cell = cell(NUM_W,1);
    
    % ecg array, remove very end remainder of window length
    winrem = rem(ECG_L, WIN_L);
    w_ecg_arr = reshape(ecg(1:ECG_L - winrem), [], NUM_W);
    w_amp_arr = reshape(amp_lbl(1:ECG_L - winrem),[],NUM_W);
    w_int_arr = reshape(sig_integral(1:ECG_L - winrem),[],NUM_W);
    
    for wi = 1:NUM_W
        
        w_sidx = (wi-1)*WIN_L+1; % window start idx
        w_eidx = w_sidx+WIN_L-1;
%         w_idx = w_sidx:w_eidx;

        w_noisy_lbl = [0 0 0];
        
        % window section to analyze
        w_ecg = w_ecg_arr(:,wi);
        % window sig turning point peak idx
        w_tp_i = sig_tp_i(sig_tp_i >= w_sidx & sig_tp_i <= w_eidx) - (w_sidx-1);
        
        % get R indices for window
        [~,w_R,~,~] = pan_tompkin(double(w_ecg),Fs,0);
        R_out_cell{wi} = w_R' + (wi-1)*WIN_L;
        % if very few R indices
        if length(w_R) < 3
            w_noisy_lbl(3) = 1;
            noisy_w(wi,:) = w_noisy_lbl;
            continue
        end
        
        % check if heart rate is within range
        w_RR = diff(w_R);
        w_hr = (60*Fs)/mean(w_RR);
        if w_hr < LOWHR_T || w_hr > HIGHHR_T
            w_noisy_lbl(3) = 1;
            noisy_w(wi,:) = w_noisy_lbl;
            continue
        end
        % get avg beat duration after removing outliers
        [~, minidx] = mink(w_RR, floor(length(w_RR)/4));
        [~, maxidx] = maxk(w_RR, floor(length(w_RR)/4));
        w_RR([minidx maxidx]) = [];
        w_avg_RR = mean(w_RR);
        
        
        % CLASS 1 Amplitude
        % check for basic amp thresh
        w_amp = w_amp_arr(:,wi);
        if sum(w_amp) ~= 0
            w_noisy_lbl(1) = 1;
            noisy_w(wi,:) = w_noisy_lbl;
            continue
        end
        % check for flat ecg
        w_flat_pos = flat_pos(flat_pos(:,1) >= w_sidx & flat_pos(:,1) <= w_eidx,:);
        if ~isempty(w_flat_pos)
            w_lowamps = w_flat_pos(:,2) - w_flat_pos(:,1);
            if any(w_lowamps > FLATTIME_T*w_avg_RR)
                w_noisy_lbl(1) = 1;
                noisy_w(wi,:) = w_noisy_lbl;
                continue
            end
        end
        
        
        % CLASS 2 Frequency

        % find tp rate in relation to r peaks
        for ri = 2:1:length(w_R)-1
            prevr = w_R(ri-1);
            nextr = w_R(ri+1);
            r_ecg = w_ecg(prevr:nextr-1);

            % turning point rate threshold
            r_tp_i = w_tp_i(w_tp_i >= prevr & w_tp_i < nextr);
            if numel(r_tp_i) > R_TP_RATE_T*2
                w_noisy_lbl(2) = 1;
                noisy_w(wi,:) = w_noisy_lbl;
                break
            elseif numel(r_tp_i) > R_HIGH_TP_RATE_T*2
                % integral of absolute valued ecg
                r_sum = sum(abs(r_ecg));
                if r_sum > R_SUM_T*AVG_R_HIGH*(nextr-prevr)
                    w_noisy_lbl(2) = 1;
                    noisy_w(wi,:) = w_noisy_lbl;
                    break
                end
            end
        end

        % save comp time by continuing if noise found
        if w_noisy_lbl(2) == 1
            noisy_w(wi,:) = w_noisy_lbl;
            continue
        end
        
        
        % CLASS 3 Periodicity
        % find abnormal spikes or large area waves
        w_int = w_int_arr(:,wi);
        int_T = R_SUM_T*AVG_R_HIGH;  % integral amplitude thresh
        int_l_T = 2*w_avg_RR;  % length of signal above integral thresh
        abnorm_ints = w_int > int_T;
        if sum(abnorm_ints) > int_l_T && mean(w_int(abnorm_ints)) > int_T*INT_AVG_T
            w_noisy_lbl(3) = 1;
            noisy_w(wi,:) = w_noisy_lbl;
            continue
        end
        % check for large RR gaps
        gapflag = check_r_gaps(w_R,RRGAP_T*Fs,w_avg_RR,WIN_L);
        if ~gapflag
            w_noisy_lbl(3) = 1;
            noisy_w(wi,:) = w_noisy_lbl;
        end
        
    end
    
    % populate ECG_L noisy label vector
    noisy_lbl = zeros(ECG_L,1);
    % set remaining portion of ecg at very end as noisy
    noisy_lbl(ECG_L-winrem+1:end,:) = 1;
    
    for wi = 1:size(noisy_w,1)
        if noisy_w(wi,1) || noisy_w(wi,2) || noisy_w(wi,3)
            w_sidx = (wi-1)*WIN_L+1; % window start idx
            w_eidx = w_sidx+WIN_L-1;
            w_idx = w_sidx:w_eidx;
            
            noisy_lbl(w_idx) = 1;
        end
    end
    
    
    % finalize outputs
    noisy = noisy_lbl;
    R = vertcat(R_out_cell{:});
    amp = amp_lbl;
    tp = sig_tp_i;
    new_ecg = ecg;
    
    % plot if debugging
    if 0
        figure
        plot(ecg)
        hold on
        plot(noisy)
        close
    end

end

