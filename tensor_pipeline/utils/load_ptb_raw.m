function [loaded_data, params, data_path, filtered]=load_ptb_raw()
    file_name = "loaded_data.mat";
    if ispc
        data_path = "Z:\Projects\DoD_Multimodal\Code\Joshua\datasets\PTB\raw\";
    else
        data_path = "/nfs/turbo/med-kayvan-lab/Projects/DoD_Multimodal/Code/Joshua/datasets/PTB/raw/";
    end
    % These calculations can be found in data_set_exploration.m
    params = containers.Map;
    params('Max F') = 100/60; % Reasonable ranges on HR
    params('Min F') = 60/60;
    params('Sampling F') = 1000; % https://physionet.org/content/ptbdb/1.0.0/
    params('Max Epsilon') = 2;
    params('Non-Tensor Features') = false;
    if isfile(data_path + "filtered_signals.mat") && 0 == 1
        load(data_path + "filtered_signals.mat");
        loaded_data = data_bandpass;
        filtered = true;
    else
        filtered = false;
        file_path = data_path + file_name;
        load(file_path);
        loaded_data.Properties.VariableNames = {'ID', 'Label', 'Signals'};
        % Reformat into cell
        for r=1:height(loaded_data)
            sig = loaded_data.Signals{r};
            c = cell(12,1);
            for lead=1:12
                c{lead} = sig(:,lead);
            end
            loaded_data.Signals{r} = c;
        end
    end
end

% The below code was initially used to open and read each signal file
% separately, but this was a slow process, so I saved it all to 1 file.
% Additionally, the filtered data was saved for this dataset because it
% took multiple hours to filter (not using GL).
    %{
    data_path = 'Z:\Projects\Tensor_Sepsis\Data\Processed\PublicData\PhysionetPTB\csvFiles\Processed\normal\lowNoise';
    loaded_data = table([],[],[],[],'VariableNames',{'ID','Label','Signals','Non-Tensor Features'});
    % List of control samples
    controls = [
        "patient104/s0306lre","patient105/s0303lre","patient116/s0302lre","patient117/s0291lre",
        "patient117/s0292lre","patient121/s0311lre","patient122/s0312lre","patient131/s0273lre",
        "patient150/s0287lre","patient155/s0301lre","patient156/s0299lre","patient165/s0322lre",
        "patient165/s0323lre","patient166/s0275lre","patient169/s0328lre","patient169/s0329lre",
        "patient170/s0274lre","patient172/s0304lre","patient173/s0305lre","patient174/s0300lre",
        "patient174/s0324lre","patient174/s0325lre","patient180/s0374lre","patient180/s0475_re",
        "patient180/s0476_re","patient180/s0477_re","patient180/s0490_re","patient180/s0545_re",
        "patient180/s0561_re","patient182/s0308lre","patient184/s0363lre","patient185/s0336lre",
        "patient198/s0402lre","patient198/s0415lre","patient214/s0436_re","patient229/s0452_re",
        "patient229/s0453_re","patient233/s0457_re","patient233/s0458_re","patient233/s0459_re",
        "patient233/s0482_re","patient233/s0483_re","patient234/s0460_re","patient235/s0461_re",
        "patient236/s0462_re","patient236/s0463_re","patient236/s0464_re","patient237/s0465_re",
        "patient238/s0466_re","patient239/s0467_re","patient240/s0468_re","patient241/s0469_re",
        "patient241/s0470_re","patient242/s0471_re","patient243/s0472_re","patient244/s0473_re",
        "patient245/s0474_re","patient245/s0480_re","patient246/s0478_re","patient247/s0479_re",
        "patient248/s0481_re","patient251/s0486_re","patient251/s0503_re","patient251/s0506_re",
        "patient252/s0487_re","patient255/s0491_re","patient260/s0496_re","patient263/s0499_re",
        "patient264/s0500_re","patient266/s0502_re","patient267/s0504_re","patient276/s0526_re",
        "patient277/s0527_re","patient279/s0531_re","patient279/s0532_re","patient279/s0533_re",
        "patient279/s0534_re","patient284/s0543_re","patient284/s0551_re","patient284/s0552_re"
    ];
    % Load in the files
    subdirs_s = dir(fullfile(data_path));
    subdirs_s=subdirs_s(~ismember({subdirs_s.name},{'.','..'}));
    subdirs = cell(length(subdirs_s),1);
    for s=1:length(subdirs_s)
        subdirs(s) = {subdirs_s(s).name};
    end
    for s=1:length(subdirs)
        % Extract patient number
        data_dir = subdirs(s);
        dir_name = data_dir{1};
        id = dir_name(14:16)
        % Set label
        short = dir_name(7:length(dir_name));
        short(11) = '/';
        label = 1;
        if any(strcmp(controls,string(short)))
            label = 0;
        end
        loaded_data = [loaded_data; {id, label, {}, {}}];
        data_dir = data_path + "\" + string(dir_name) + "\";
        files_s = dir(data_dir);
        files_s=files_s(~ismember({files_s.name},{'.','..'}));
        files = cell(length(files_s),1);
        for f=1:length(files_s)
            files{f} = files_s(f).name;
        end
        signals = cell(12,1);
        for f=1:length(files)
            file_dir = data_dir + "/" + files{f};
            signals(f) = {load(file_dir)};
        end
        loaded_data.('Signals')(height(loaded_data)) = {signals};
    end
    %}

