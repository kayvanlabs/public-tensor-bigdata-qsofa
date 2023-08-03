function [tableOfTensors] = groupEcgArtTensors(baseFolder, tensorNums)
    dirResults = struct2table(dir(baseFolder));
    
    tsEcgFolder = constructDirNameForSignal(dirResults, 'ECG', 'TS');
    tsArtFolder = constructDirNameForSignal(dirResults, 'Art', 'TS');
    tsHrvFolder = constructDirNameForSignal(dirResults, 'HRV', 'TS');
    dtcwptFolder = constructDirNameForSignal(dirResults, 'ECG', 'DTCWPT');
    
    useTsEcg = true;  % must be true
    useTsArt = true;
    useTsHrv = false;
    useDtcwptEcg = false;
    useTensors = [useTsArt, useTsHrv, useDtcwptEcg];
    
    featureMode = 4;
    
    idCol = 'Ids';
    encCol = 'EncID';
    labelCol = 'Labels';
    tensorCol = 'Tensors';

    baseFile = 'tensors_';

    for i = tensorNums
        iName = strcat(baseFile, num2str(i), '.mat');
        iEcgTsFile = loadTensorTable(fullfile(baseFolder, tsEcgFolder, iName), useTsEcg);
        iArtTsFile = loadTensorTable(fullfile(baseFolder, tsArtFolder, iName), useTsArt);
        iHrvTsFile = loadTensorTable(fullfile(baseFolder, tsHrvFolder, iName), useTsHrv);
        iDtcwptFile = loadTensorTable(fullfile(baseFolder, dtcwptFolder, iName), useDtcwptEcg);
        
        tableOfTensors = iEcgTsFile;
        for j = 1:size(tableOfTensors, 1)
            jId = tableOfTensors(j, {idCol, encCol});
            jTsRow = iEcgTsFile{j, tensorCol}{1};
            jArtRow = getRelevantRow(iArtTsFile, jId, idCol, encCol, tensorCol);
            jHrvRow = getRelevantRow(iHrvTsFile, jId, idCol, encCol, tensorCol);
            jDtcwptRow = getRelevantRow(iDtcwptFile, jId, idCol, encCol, tensorCol);
            stackedTensor = stackAlongFeatureMode(jTsRow, jArtRow, jHrvRow, jDtcwptRow, featureMode);
            tableOfTensors{j, tensorCol} = {stackedTensor};
        end
    end
end

function dirName = constructDirNameForSignal(baseDir, signal, featureType)
    dirName = contains(baseDir.name, strcat(signal, '_prediction')) & ...
              contains(baseDir.name, featureType);
    dirName = string(baseDir.name(dirName));
end

function thisTensorTable = loadTensorTable(tensorFile, doLoadTensor)
    if doLoadTensor
        thisTensorTable = load(tensorFile);
        fnames = fieldnames(thisTensorTable);
        thisTensorTable = thisTensorTable.(fnames{1});
    else
        thisTensorTable = [];
    end
end

function thisTensor = getRelevantRow(thisTable, toMatch, idCol, encCol, tensorCol)
    if ~isempty(thisTable)
        thisRow = ismember(thisTable(:, {idCol, encCol}), toMatch);
        thisTensor = thisTable{thisRow, tensorCol}{1};
    else
        thisTensor = [];
    end
end

function stackedTensor = stackAlongFeatureMode(ten1, ten2, ten3, ten4, featureMode)
    ten1Size = size(ten1);
    tenSizes = [ten1Size(featureMode), size(ten2, featureMode), ...
                size(ten3, featureMode), size(ten4, featureMode)];
    
    stackedTenSize = ten1Size;
    stackedTenSize(featureMode) = sum(tenSizes);
    
    tensorList = {ten1, ten2, ten3, ten4};
    
    stackedTensor = tenzeros(stackedTenSize);
    iStart = 1;
    push = 0;
    for i = 1:4
        if ~isempty(tensorList{i})
            stackedTensor(:, :, :, iStart:(tenSizes(i) + push)) = tensorList{i};
        end
        iStart = tenSizes(i) + 1;
        push = tenSizes(i);
    end    
end