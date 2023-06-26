%   qrs_detect_example is an exmaple code that uses the qrs_detect code to
%   find qrs complexes in a sample ecg recording from physionet's mit-bih
%   database.
%
%   Author: Sardar Ansari (sardara@umich.edu)
%   Copyright: Sardar Ansari (sardara@umich.edu)
%   
%   Version: 1.0 beta
%   Birthdate: 02/26/2018
%   Last update: 02/26/2018

function qrs_detect_example

    % use the WFDB in the current this folder since it does not cause
    % popups in windows
    wfdb_adr = which('rdmat');    
    if(isempty(wfdb_adr) | ~strcmp(pwd,wfdb_adr(1:length(pwd))))
        addpath(genpath('./wfdb'));
    end

    % The labels that Physionet uses for beat annotations ('N' represents
    % normal sinus rhythm)
    qrs_ann_labels = 'NLRBAaJSVrFejnE/fQ';
    
    % mit-bih record to process
    record = 'mitdb/100';

    % read the ecg signal
    [ecg,Fs,tm] = rdsamp(record);
    ecg = ecg(:,1);    
    
    % correct the location of the reference qrs complexes
    %ecgpuwave(record,'atr2',[],[],'atr');
    
    % read the reference qrs complexes
    [anns,ann_type] = rdann(record,'atr');   
    true_qrs = [];
    for i = 1:length(qrs_ann_labels)
        % only keep the beat annotations
        true_qrs = [true_qrs ; anns(ann_type==qrs_ann_labels(i))];
    end
    true_qrs = unique(true_qrs);    
    
    % detect the qrs complexes
    [detected_qrs, processed_ecg] = qrs_detect(ecg,Fs,'ptom');
    
    % plot the results
    figure;    
    plot(tm,processed_ecg);
    hold all;
    plot(tm(true_qrs), processed_ecg(true_qrs), 'og');
    plot(tm(detected_qrs), processed_ecg(detected_qrs), 'xr');
    xlabel('Time (s)');
    title(['MIT-BIH Record ' record]);
    legend({'ECG','True QRS','Detected QRS'});

end

