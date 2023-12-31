function negativeSignals = getNegativeSignals(noiseDir, signalDuration, gapDuration, wavTab, thisEvent, startCol, endCol, idCol, encCol, waveCol, waveIdCol, onlyUseFirstPerEnc)
% DESCRIPTION
% Find negative case by creating a random event
%
% REQUIRES
% iWavems.(waveCol) is of type 'EKG II' or 'Art Line'
% checkIfSignalUsable()
% createRandomStart()
%
% INPUT
%   noiseDir: string, location of noise files generated by checkNoise()
%   signalDuration: duration, desired length of precdiction signal
%   gapDuration: duration, time between end of prediction signal and event
%   wavTab: table, waveform times
%   thisEvent: table, event information from find<event>Occurrences.m
%   startCol: string, column of wavTab with start time of full signal
%   endCol: string, column of wavTab with end time of full signal
%   idCol: string, column of wavTab/thisEvent with SepsisID
%   encCol: string, column of wavTab/thisEvent with EncID
%   waveCol: string, column of wavTab for Wave Type
%   waveIdCol: string, column of wavTab for Wave ID
%
% OUTPUT
%   negativeSIgnals: table merged from wavTab and thisEvent with 
%     randomly generated negative event times

    %% Initialize output
    negativeSignals = [];
    
    %% Set more column names
    pSigStart = 'predictionSignalStart';
    pSigEnd = 'predictionSignalEnd';
    
    %% Set up for iterations
    ekgRows = strcmp(wavTab.(waveCol), 'EKG II');
    nEkg = sum(ekgRows);
    artRows = strcmp(wavTab.(waveCol), 'Art Line');
    thisEvent.(encCol) = [];
    
    % Find latest possible end times / earlist start times for prediction signal
    latestEkgStart = wavTab{ekgRows, endCol} - signalDuration;
    earliestEkgStart = wavTab{ekgRows, startCol};
    waveRows = 1:size(wavTab, 1);
    
    %% Main loop of function
    % Iterate over every instance of EKG, find matching Art if applicable
    for j = 1:nEkg
        rowToAdd = [];
        negIsUsable = false;
        
        % For indexing
        jEkgIdx = waveRows(ekgRows);
        jEkgIdx = jEkgIdx(j);
        
        nIters = 0;
        jSkip = false;
        
        % If using Art Line, first see if this EKG signal overlaps at all
        if any(artRows)
            artEndsBeforeEkgStarts = wavTab{artRows, endCol} < ...
                                     wavTab{jEkgIdx, startCol};
            artStartsAfterEkgEnds = wavTab{jEkgIdx, endCol} < ...
                                    wavTab{artRows, startCol};
            timesDoAgree = (~artStartsAfterEkgEnds & ~artEndsBeforeEkgStarts);
        end
        
        % Try 10 different random starts; if all fail, give up
        while ~negIsUsable && nIters < 10
            if any(artRows)
                jArtIdx = waveRows(artRows);
                if ~any(timesDoAgree)
                    % If no Art matches, skip
                    jSkip = true;
                    break
                elseif sum(timesDoAgree) > 1
                    % If many matches, randomly select Art Line
                    jArtIdx = jArtIdx(randi(sum(timesDoAgree)));
                else
                    jArtIdx = jArtIdx(timesDoAgree);
                end
                
                % Modify start/end of prediction signal based on Art Line
                latestEkgStart(j) = min([latestEkgStart(j), ...
                                         wavTab{jArtIdx, endCol} - signalDuration]);
                earliestEkgStart(j) = max([earliestEkgStart(j), ...
                                           wavTab{jArtIdx, startCol}]);
            else
                jArtIdx = [];
            end
            
            % If nothing works, skip
            if latestEkgStart(j) < earliestEkgStart(j)
                jSkip = true;
                break
            end
            
            % Catch-all
            if jSkip
                continue
            end
            
            % Create random start based on EKG
            rowToAdd = createRandomStart(earliestEkgStart(j), latestEkgStart(j), ...
                                         signalDuration, thisEvent, ...
                                         wavTab([jEkgIdx; jArtIdx], :), ...
                                         gapDuration);
            % Sanity check
            if any(rowToAdd.(pSigStart) < rowToAdd.(startCol)) || ...
               any(rowToAdd.(pSigEnd) > rowToAdd.(endCol))
                error('Prediction signal does not fall in signal duration')
            end
            
            % Check quality of signal vs noise
            rtaEkg = strcmp(rowToAdd.(waveCol), 'EKG II');
            [negIsUsable, isGarbage] = checkIfSignalUsable(noiseDir, wavTab, ...
                                                       rowToAdd{rtaEkg, pSigStart}, ...
                                                       rowToAdd{rtaEkg, pSigEnd}, ...
                                                       rowToAdd{rtaEkg, idCol}, ...
                                                       rowToAdd{rtaEkg, encCol}, ...
                                                       rowToAdd{rtaEkg, waveCol}, ...
                                                       rowToAdd{rtaEkg, waveIdCol});
            if isGarbage
                rowToAdd = [];
                break
            end
            nIters = nIters + 1;
        end  % end of while
        negativeSignals = [negativeSignals; rowToAdd];
        if ~isempty(negativeSignals) && onlyUseFirstPerEnc
            return  % If only looking for 1 instance, return
        end
    end  % end of for
end