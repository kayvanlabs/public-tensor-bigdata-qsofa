%   DESCRIPTION: This function constrcuts tensors according to the
%   parameters passed to it and the data table loaded in from a
%   load_<dataset>_raw.m file.
%
%   PARAMETERS:
%       1. data: loaded in directly from a load_... file
%       2. params: a dictionary of parameters for tensorization. These are
%                  also loaded in from a load_... file. Fields include the
%                  Max and Min frequency of the signal, so that the signals
%                  period can be calculated and the sampling rate
%       3. feature type: TS or DTCWPT
%       4. num_periods: The number of periods of the signal represented in 
%                       each tensor
%       5. num_windows: the number of windows in each tensor
%       6. epsilons: the epsilon values used for feature extraction
%       7. balanced: this parameter is set to determine if the data need to
%                    rebalanced. If set true, it is hard coded for a
%                    specific data set (CWR), so you should probably leave
%                    it as false.
%   
%   Joshua Pickard (jpic@umich.edu)

function data_table=construct_tensors(data, params, feature_type, num_periods, num_windows, epsilons, balance) %, first_1, h, f, max_level)
    % To save the results to return
    data_table = table([],[],[],[],[],'VariableNames',{'Ids','EncID','Labels','Tensors','Non-Tensor-Features'});

    % Calculate the tensor dimensions num_windows is also included
    signals = data.Signals{1};
    num_signals = length(signals);
    num_epsilons = length(epsilons(1,:));
    if strcmp(feature_type, "TS")
        num_features = 6;
    elseif strcmp(feature_type, "DTCWPT")
        num_features = 152; % DTCPWT is 19, TS is 16, I could do both but haven't yet
    elseif strcmp(feature_type, "ABP")
        num_features = 21;
        epsilons = [];
        num_epsilons = 1;
    else
        error('Unrecognized feature type')
    end
    
    % Calculate the period length of the signal in terms of the number of
    % data points that are included
    if num_periods == 0
        signal_length = length(signals{1});
    else
        mean_F = (params('Max F') + params('Min F')) / 2;
        period = 1 / mean_F;
        samples_per_period = period * params('Sampling F');
        signal_length = round(samples_per_period * num_periods);
    end

    % Compute window size and overlap
    window_size = round(signal_length / num_windows);
    overlap = round(0.05 * window_size);
    disp(height(data));
    for sample=1:height(data)
        disp(sample);
        used_data = 0;
        signals = data.Signals{sample};
        while used_data + signal_length < length(signals{1}) || (used_data == 0)
            tensor = tenzeros([num_signals, num_windows, num_epsilons, num_features]);
            for signal_i=1:num_signals
                signal = signals{signal_i};
                if length(signal) ~= signal_length
                    disp('Error in signal length');
                    continue
                end
                tensor_signal = signal(used_data+1:used_data+signal_length);
                for window=1:num_windows
                    start = 1 + (window-1) * window_size;
                    stop = (start - 1) + window_size;
                    if window ~= 1
                        start = start - overlap;
                    end
                    if window ~= num_windows
                        stop = stop + overlap;
                    else
                        stop = signal_length;
                    end
                    % Extract features for this window
                    window_view = tensor_signal(start:stop);
                    [one, ~] = size(window_view);
                    if one ~= 1
                        window_view = window_view';
                    end
                    % Taut String Features
                    if strcmp(feature_type, "TS")
                        [features_TS,~,~] = feature_compute_staticTS(window_view, epsilons(signal_i,:));
                        features_TS = reshape(features_TS,[num_epsilons, num_features]);
                        features = features_TS;
                    % DTCWPT Features
                    elseif strcmp(feature_type, "DTCWPT")
                        TS_signals = [];
                        for e=1:length(epsilons(signal_i,:))
                            ts_sig = taut_string(window_view, epsilons(signal_i, e));
                            TS_signals = [TS_signals; ts_sig];
                        end                    
                        features_DTCWPT = feature_compute_staticDTCWPT_2(TS_signals);
                        features = features_DTCWPT;
                    elseif strcmp(feature_type, "ABP")
                        sigAttributes.sampleRate = 120;
                        sigAttributes.signalType = 'art';
                        features = art_feature_extraction(window_view,sigAttributes,window);
                        if ~isempty(features)
                            features = features.art;
                        else
                            continue
                        end
                    end
                    tensor(signal_i, window, :, :) = features;    
                end
            end
            if num_signals == 1
                % Squash signal dimension
                %tensor = tensor(1,:,:,:);
            end
            id = data.ID(sample);
            enc = data.EncID(sample);
            label = data.Label(sample);
            try
                non_tensor_features = data.EHR(sample); %data.('Non-Tensor Features')(sample);
            catch
                non_tensor_features =[];
            end
            tensor = remove_nan_4d(tensor);
            tensor = {tensor};
            
            if ~(collapse(tensor{1}) == 0)  % if all values in tensor == 0
                data_table = [data_table; {id, enc, label, tensor, non_tensor_features}];
            end
            % Increment how much data we have used
            used_data = used_data + signal_length;
        end
    end
    if balance % This is hardcoded to the CWR data set Joshua is working with
        baseline = (data_table.Labels == "N");
        readd = data_table(baseline, :);
        data_table = [data_table; readd];
        data_table = [data_table; readd];
    end
end