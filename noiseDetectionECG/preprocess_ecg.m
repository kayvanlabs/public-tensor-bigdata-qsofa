 function [ signal_clean ] = preprocess_ecg( signal,Fs,filtertype,scaling )
 %% An Nguyen (annguy@umich.edu) June 2017
% preprocessing of preventice ECG raw data signal
% uses double median filter to remove baseline wandering
% applies butterworth BP filter to remove noise
% INPUT: signal - raw ecg data signal; Fs - sampling frequency; filtertype
% - 'BP', 'LP' or 'HP'; scaling - 1 if wanted should lead to an amplitude
% of around 1 in the end to be easily processable for the wfdb peak
% detection toolbox
% OUTPUT: preprocessed ecg signal
 
%% remove mean and scale
                signal = signal - mean(signal);
                
                if scaling == 1
                    scale = 1/1000; %---> 2mV for 1/500 and in mV for 1/1000
                    signal =  signal * scale;
                end


                %% BP
                f_cutoff_hp = 0.5; %to remove base 

                f_cutoff_lp = 40.0; % in case there is


                order = 2;
                if filtertype == 'BP'
                    ff = [f_cutoff_hp,f_cutoff_lp];
                    [b1,a1] = butter(order,ff.*2.0./Fs,'bandpass'); % Butterworth filter (low-pass by defualt). The first input is the filter oreder, the 2nd one is the cutoff frequency in the form (freq in Hz)*2/Fs
                elseif filtertype == 'LP'
                    [b1,a1] = butter(order,f_cutoff_lp*2/Fs,'low'); % Butterworth filter (low-pass by defualt). The first input is the filter oreder, the 2nd one is the cutoff frequency in the form (freq in Hz)*2/Fs
                else
                    [b1,a1] = butter(order,f_cutoff_hp*2/Fs,'high'); % Butterworth filter (low-pass by defualt). The first input is the filter oreder, the 2nd one is the cutoff frequency in the form (freq in Hz)*2/Fs
                end
                %% double meadian filter
               % 200 and 600msec
                n_median_200 = round(0.2*Fs);
                n_median_600 = round(0.6*Fs);

                %% apply butterworth BP filter designed in calc_features.m
                signal = filter(b1,a1,signal); %apply BP filter

            %% double meadian filter
            %200msec = 60 samples; 600msec 180 sample
                double_median = medfilt1(medfilt1(signal,n_median_200),n_median_600); %1D double median filter 200msec then 600msec
                signal_clean = signal - double_median;
            % 
            %
 end