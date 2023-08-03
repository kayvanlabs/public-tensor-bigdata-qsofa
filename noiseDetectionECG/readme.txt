Description of folder contents:
ECG noise detection function created in 2020 by Winston Zhang
Uses butterworth filter function "preprocess_ecg.m" created by An Nguyen in 2017
Email Winston at "wwzhang@umich.edu" for questions or suggestions.

Usage Instructions:
Remove baseline wander and smooth ECG signal using "preprocess_ecg.m"
Get noise annotation binary vector using noise detection algorithm "new_noise_detect_WZ_shared.m"

Example Usage:
ecg - raw ecg vector
Fs - sampling frequency (number of samples per second)

ecg = preprocess_ecg(ecg,Fs,'BP',1); % remove baseline wander and smooth signal
win_length = Fs*10;                  % divide ecg into windows of 10 second length

% get noise annotations, R peak indices, and other data
[noisy,R,amp,tp,noisy_w,new_ecg] = new_noise_detect_WZ_shared(ecg, Fs, win_length);

Download Pan-Tompkins implementation from 
Hooman Sedghamiz (2023). Complete Pan Tompkins Implementation ECG QRS detector (https://www.mathworks.com/matlabcentral/fileexchange/45840-complete-pan-tompkins-implementation-ecg-qrs-detector), MATLAB Central File Exchange. Retrieved June 19, 2023. 
and inlcude in this directory.