function uniqueWaveTypes = getUniqueWaveTypes(waveformsIn, wvTypeCol)
% DESCRIPTION
% Get unique list of wave types
%
% INPUT
%   waveformsIn: table of waveform information
%   wvTypeCol: string, column of waveformsIn that has wave type information
%
% OUTPUT
%   uniqueWaveTypes: array of unique wave types
    uniqueWaveTypes = unique(waveformsIn.(wvTypeCol));
end