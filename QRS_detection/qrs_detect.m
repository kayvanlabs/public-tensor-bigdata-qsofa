%   qrs_detect perform qrs detection using several different detection
%   algorithms
%
%   function signature:
%   [qrs, ecg] = qrs_detect(ecg,Fs,method,correct_location,scale_ecg,filter_ecg)
%
%   The code needs to be accompanied by a partial copy of the wfdb
%   toolbox that is available in the current folder.
%
%   The code has been tested on Windows 7.
%   
%   ------required inputs--------------------------------------------------
%   ecg: the input ecg signal
%   Fs: the sampling rate in Hz
%
%   ------optional inputs--------------------------------------------------
%   method: the method used for qrs detection. Possible values are
%       gqrs(default): the gqrs routine in physionet's wfdb toolbox. See https://www.physionet.org/physiotools/matlab/wfdb-app-matlab/html/gqrs.html
%       sqrs: the sqrs routine in physionet's wfdb toolbox. See https://www.physionet.org/physiotools/matlab/wfdb-app-matlab/html/sqrs.html
%       wqrs: the wqrs routine in physionet's wfdb toolbox. See https://www.physionet.org/physiotools/matlab/wfdb-app-matlab/html/wqrs.html
%       harm: an algorithm designed by Dr. Harm Derksen. For details, contact Dr. Derksen.
%       ptom: the Pan-Tompkin algorithm.
%   correct_location(default=true): a boolean input controlling whether a postprocessing
%       step will be conducted to adjust the location of the detected beats to
%       the closest local extrema using ecgpuwave function.
%   scale_ecg(default=true): a boolean input controlling whether the amplitude of the input ecg signal
%       will be scaled to an appropriate level for the detection algorithm.
%   filter_ecg(default=false): a boolean input controlling whether a preprocessing step
%       will be conducted to denoise the signal using a butterworth filter
%       between 0.5 and 119Hz and baseline wander will be removed using a
%       double median filter.
%
%   ------outputs----------------------------------------------------------
%   qrs: the location of the detected qrs complexes
%   ecg: the processed ecg signal that has been used for qrs detection
%       (will be different from the input ecg signal if either scale_ecg or
%       filter_ecg are true.
%
%   Author: Sardar Ansari (sardara@umich.edu)
%   Copyright: Biomedical and Clinical Informatics Lab
%   
%   Version: 1.0 beta
%   Birthdate: 02/26/2018
%   Last update: 04/27/2022

function [qrs, ecg] = qrs_detect(ecg,Fs,varargin)

    % set the default values for the inputs         
    [method,correct_location,scale_ecg,filter_ecg] = parse_input(varargin);
   
    % ensures that ecg is a column vector
    if(isrow(ecg))
        ecg = ecg';
    end    

    % use the WFDB in the current this folder since it does not cause
    % popups in windows
    wfdb_adr = which('rdmat');    
    if(isempty(wfdb_adr) || ~strcmp(pwd,wfdb_adr(1:length(pwd))))
        addpath(genpath('./wfdb'));
    end
   
    % this is to handle parallel processing
    t = getCurrentTask(); 
    if(isempty(t))
        name = 'ecg';
    else
        name = ['ecg_' num2str(t.ID)];
    end   

    % filter the ecg signal using a bandpass butterworth filter to remove 
    % noise and a double median filter to remove baseline wander
    if(filter_ecg)
        ecg = ecg_filter(ecg,Fs);
    end
      
    % scaling the ecg signal
    if(scale_ecg)
        ecg = ecg_scale(ecg,Fs);
    end
 
    if(strcmp(method,'gqrs') || strcmp(method,'wqrs') || strcmp(method,'sqrs'))      
        % wfdb uses different suffixes for different qrs detection methods
        if(strcmp(method,'wqrs'))
            suffix = 'wqrs';
        else
            suffix = 'qrs';
        end
        
        % write the signal into a wfdb file
        tm = (1:length(ecg))'/Fs;
        wrsamp(tm,ecg*200,name,Fs, 200, '32');

        % perform qrs detection
        feval(method,name);
       
        % correct the locatoin of the complexes
        if(correct_location)
            ecgpuwave(name,[suffix '2'],[],[],suffix);
            
            % read the qrs locations
            [qrs,qrs_type]=rdann(name,[suffix '2']);            
        else
            % read the qrs locations
            [qrs,qrs_type]=rdann(name,suffix);            
        end    
        delete([name '.*']);
      
        % keep the QRS complexes and discard other annotations
        qrs = qrs(qrs_type=='N');
    elseif(strcmp(method,'harm'))
        qrs = harm_peak_detection(ecg,Fs);
    elseif(strcmp(method,'ptom'))
        [~,qrs]=pan_tompkin(ecg,Fs,0);
        qrs = qrs';
    else
        error('The QRS detection method not recognized. Valid inputs are "gqrs", "wqrs", "sqrs" or "harm".');
    end

end

% set the default values for the inputs
function [method,correct_location,scale_ecg,filter_ecg] = parse_input(inputs)
    
    n_inputs = length(inputs);

    if(n_inputs<1 || isempty(inputs{1}))
        method = 'gqrs';
    else
        method = inputs{1};
    end
    
    if(n_inputs<2 || isempty(inputs{2}))
        correct_location = true;
    else
        correct_location = inputs{2};        
    end    

    if(n_inputs<3 || isempty(inputs{3}))
        scale_ecg = true;
    else
        scale_ecg = inputs{3};        
    end     
    
    if(n_inputs<4 || isempty(inputs{4}))
        filter_ecg = false;
    else
        filter_ecg = inputs{4};        
    end         

end

% scales the ecg signal to have an amplitude level that is suitable for the
% qrs detection algorithms
function ecg = ecg_scale(ecg,Fs)

    ecg = ecg - median(ecg);
    
    % find the peaks and troughs that are at least 2 seconds apart
    pks = findpeaks(ecg,'minpeakdistance',2*Fs);
    trs = findpeaks(-ecg,'minpeakdistance',2*Fs);
    
    % use the median of peaks or troughs, whichever one is lager to scale
    % the ecg signal
    amp = max(median(pks),median(trs));
    
    ecg = ecg/amp;
end

% denoises the signal using a bandpass butterworth filter between 0.5 and
% 119 Hz and removes the baseline wander using a double median filter
function ecg_cln = ecg_filter(ecg,Fs)

    ecg = ecg - median(ecg,'omitnan');

    % bandpass filter cutoffs
    f_cutoff_hp = 0.5;
    f_cutoff_lp = 119; %changed to accommodate RDW signals, which are sampled at 240 Hz

    order = 2;
    
    % filter the signal using butterworth filter
    [b1,a1] = butter(order,[f_cutoff_hp,f_cutoff_lp]*2/Fs); % Butterworth bandpass filter. The first input is the filter order, the 2nd one is the cutoff frequency in the form (freq in Hz)*2/Fs
    ecg = filtfilt(b1,a1,ecg);

    % double median filter with 200 and 600msec spans
    n_median_200 = round(0.2*Fs);
    n_median_600 = round(0.6*Fs);
    
    double_median = medfilt1(ecg,n_median_200, 'omitnan');
    double_median = medfilt1(double_median,n_median_600, 'omitnan');
    ecg_cln = ecg - double_median;

end