function [ newWaveform, newx, oldx ] = BP_resample( waveform, origFs, Fs)
    %BP_RESAMPLE Resample to 200 Hz
%     global Fs;
    duration = length(waveform) / origFs;
    oldx = linspace(0, duration, length(waveform));
    newx = linspace(0, duration, Fs * duration);

    newWaveform = interp1(oldx, waveform, newx, 'pchip');
end