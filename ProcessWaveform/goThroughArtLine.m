function goThroughArtLine()
    rng(0)
    baseDir = 'Z:\Projects\Tensor_Sepsis\Data\Processed\Non-Specific\Modeling\qSOFA\';
    extractDir = 'Z:\Projects\Tensor_Sepsis\Data\Processed\Non-Specific\Extracted\';
    % Load in signals
    filteredAbpTable = load(fullfile(baseDir, 'filteredAbpTable.mat'));
    filteredAbpTable = filteredAbpTable.filteredAbpTable;
    filteredAbpTable = filteredAbpTable(randperm(size(filteredAbpTable, 1)), :);
    %rawAbpTable = load(fullfile(baseDir, 'rawAbpTable.mat'));
    %rawAbpTable = rawAbpTable.rawAbpTable;
    
    % Get signals info
    signalInfoFile = 'signalsInfo_gap_6_hr_signal_10_min_temporalEHR.mat';
    signalInfoFile = load(fullfile(baseDir, signalInfoFile));
    signalsInfo = signalInfoFile.allSignalsInfo;
    signalsInfo = signalsInfo(strcmp(signalsInfo.WaveType, 'Art Line'), :);
    
    % Get EHR data
    vitals = readtable('Z:\Projects\Tensor_Sepsis\Data\Processed\Non-Specific\EHR\nursingstandardvitalsigns-all.csv');
    vitals.ObservationDate.TimeZone = signalsInfo.predictionSignalStart(1).TimeZone;
    
    % Loop through IDs/Encounters
    for i = 1:size(filteredAbpTable, 1)
        iId = filteredAbpTable{i, 'SepsisID'};
        iEnc = filteredAbpTable{i, 'Sepsis_EncID'};
        iVitals = ismember(vitals.SepsisID, iId) & ismember(vitals.EncID, str2double(iEnc));
        iVitals = iVitals & ~isnan(vitals.BPDiaInvasive);
        iVitals = vitals(iVitals, [1, 2, 4, 9:11, 6:8]);
        iSigInfo = ismember(signalsInfo.Sepsis_ID, iId) & strcmp(signalsInfo.Sepsis_EncID, iEnc);
        if isempty(iVitals)
            disp(strcat("No Vitals Data available for ", num2str(iId), "-", iEnc))
        else
            wSigInfo = signalsInfo(iSigInfo, [1:4, 5:6, 7, 8, 10]);
            %wStart = wSigInfo.EventTime - minutes(10);
            %wEnd = wSigInfo.EventTime + hours(1);
            %wSigInfo.StartTime = wStart;
            %wSigInfo.EndTime = wEnd;
            wVitals = iVitals.ObservationDate >= wSigInfo.StartTime & ...
                      iVitals.ObservationDate <= wSigInfo.EndTime;
            %wVitals = iVitals(wVitals, :);
            wVitals = iVitals(wVitals, :);
            if isempty(wVitals)
                disp(strcat("No Vitals Data available for ", num2str(iId), "-", iEnc))
            else
                % Just select 3 instances per Enc
                if size(wVitals, 1) > 3
                    wVitals = wVitals(randperm(size(wVitals, 1)), :);
                    wVitals = wVitals(1:3, :);
                end
                for j = 1:size(wVitals, 1)
                    iCsv = strcat(num2str(iId), "_", iEnc, "_Art Line_", wSigInfo{1, 'WaveID'}, ".csv");
                    rawAbpTable = readmatrix(fullfile(extractDir, iCsv));
                    foundIndices = find_signal_index_from_time(wSigInfo, ...
                                    wSigInfo.Sepsis_ID, wSigInfo.Sepsis_EncID, ...
                                    wVitals{j, 'ObservationDate'}, wSigInfo.WaveType, wSigInfo.WaveID);
                    try
                    figure;
                    xaxisVals = [1:length(rawAbpTable)] / 120;
                    plot(xaxisVals, rawAbpTable); hold on;
                    line('XData', repelem(xaxisVals(foundIndices), 200), 'YData', [1:200]);
                    %xrange = [max(min(xaxisVals(foundIndices)) - 100, 1), min(max(xaxisVals(foundIndices)) + 100, 72000)];
                    xrange = [max(min(xaxisVals(foundIndices)) - 3, 1), min(max(xaxisVals(foundIndices)) + 1, length(rawAbpTable))];
                    xlim(xaxisVals(xrange * 120));
                    ylim([0,140])
                    legend('Art Line', 'EHR Timestamp');
                    hold off;
                    wVitals{j, 'SepsisID'}
                    wVitals(j, 'EncID')
                    wSigInfo(:, 'EventTime')
                    wVitals(j, {'ObservationDate', 'BPSysInvasive', 'BPDiaInvasive'})

                    catch ME
                        disp('issue with plotting')
                    end
                end
            end
        end
    end
end