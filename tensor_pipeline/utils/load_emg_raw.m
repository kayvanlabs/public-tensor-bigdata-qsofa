function [loaded_data, params, data_path, filtered]=load_emg_raw()
    if ispc
        data_path = 'Z:\Projects\DoD_Multimodal\Code\Joshua\datasets\EMG\raw\';
    else
        data_path = '/nfs/turbo/med-kayvan-lab/Projects/DoD_Multimodal/Code/Joshua/datasets/EMG/raw/';
    end
    loaded_data = table([],[],[],[],'VariableNames',{'ID','Label','Signals','Non-Tensor Features'});
    % These calculations can be found in data_set_exploration.m
    params = containers.Map;
    params('Max F') = 150;
    params('Min F') = 50;
    params('Sampling F') = 200;
    params('Max Epsilon') = 2;
    params('Non-Tensor Features') = false;
    if isfile(data_path + "un_filtered_signals.mat")
        load(data_path + "filtered_signals.mat");
        loaded_data = data_bandpass;
        filtered = true;
    else
        filtered = false;
        num_leads = 8;
        for patient=1:36
            patient_folder = string(patient);
            if patient < 10
                patient_folder = "0" + patient_folder;
            end
            file_path = data_path + patient_folder + '/';
            files = dir(file_path);
            files=files(~ismember({files.name},{'.','..'}));

            % Loop over a patients files
            for file=1:length(files)
                file_name = files(file).name;
                data_sample = readtable(file_path + file_name); % This is the files data

                % Iterate over each of the 7 gestures. Each of these should be
                % stored in the loaded_data table
                for gesture=1:6
                    logic_indices = (data_sample.class == gesture);
                    logic_dif = diff(logic_indices);
                    spots = find(logic_dif,4);
                    if isempty(spots)
                        continue
                    end
                    if length(spots) == 3
                        spots = cat(1,[0],spots);
                    end
                    % Iterate over instance of class
                    for j=[1,3]
                        % Iterate over the lead for the class instance
                        row = {patient, gesture};
                        loaded_data = [loaded_data; {patient, gesture, {}, {}}];
                        signals = cell(num_leads,1);
                        for emg_lead=1:num_leads
                            lead = "channel" + string(emg_lead);
                            emg_signal_long = data_sample.(lead);
                            emg_signal = emg_signal_long(spots(j)+1:spots(j+1));
                            signals(emg_lead) = {emg_signal'};
                            %row{emg_lead + 2} = emg_signal;
                        end
                        loaded_data.('Signals')(height(loaded_data)) = {signals};
                        %loaded_data = [loaded_data; row];
                    end
                end % Gesture loop
            end % File loop
        end % Patient loop
    end
end
