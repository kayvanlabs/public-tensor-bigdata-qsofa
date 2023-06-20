%% SCRATCH EPSILON SELECTION
%
%   This script is used for work on selecting the correct epsilon values
%   for Taut String.
%
%   PURPOSE: The purpose of this script is to design a method for selecting
%   the epsilon values of a signal based on the Fourier spectrum.
%
%   Based on visual inspection, a reasonable lower bound on epsilon is 
%   10e-2. This is a near inflection point when the MSEs are plotted on a
%   semilogx scale.
%
%   The upper bound could be selected the following ways:
%       1. For each signal, for each sample, find the epsilon value first
%       corresponding to the maximum value. Average them.


%
% 4/13/2022 Post meeting ideas
%   1. filter signal and find maximum epsilon value producing low MSE on
%   lowest frequency part of the signal
%       - still uses MSE
%   2. Match each frequency band with an associated epsilon value
%       - I dont know how to do this yet
%       - The small epsilon values (high frequency) will have an addative
%       effect on the low frequency components (which should be modeled
%       with large epsilon values), unless we do each frequency band
%       separately
%
%
%% Load Data

data_raw = load_data_raw("CWR");

%% Epsilon for a frequency band

x = data_raw.Signals{1,1};
x = x{1};
Ts = 48000;
x_fft = fft(x);
fs = 1/Ts;
f = (0:length(x)-1)*fs/length(x);
% y_TS = fft(x_TS);
plot(f, x_fft)

%% Fourier Spectrum of signal and its TS approximation

for h=1:height(data_raw)
    % Select signal and parameters
    x_data = data_raw.Signals{h};
    figure;
for q=1:8
    x = x_data{q};
    Ts = 48000;
    epsilons = logspace(-4, 1, 20);
    MSEs = [];
    MSEs_signal = [];
    
    for epsilon=epsilons
        % TS Approximation
        [x_TS, ~] = taut_string(x, epsilon);

        
        err = abs(x - x_TS);
        err_sq = err.^2;
        MSEs_signal = [MSEs_signal mean(err_sq)];
        
        %{
        % Fourier Transforms
        y = fft(x);   
        fs = 1/Ts;
        f = (0:length(y)-1)*fs/length(y);
        y_TS = fft(x_TS);

        
        %figure;
        %subplot(2,2,1:2);
        %hold on
        n = length(x);                         
        fshift = (-n/2:n/2-1)*(fs/n);
        yshift_real = fftshift(y);
        %plot(fshift,abs(yshift_real));
        %xlabel('Frequency (Hz)');
        %ylabel('Magnitude');
        yshift_TS = fftshift(y_TS);
        %plot(fshift,abs(yshift_TS));
        %legend(["Original", "TS"]);
        % Calculate the MSE

        err = abs(yshift_real - yshift_TS);
        err_sq = err.^2;
        mse = mean(err_sq);
        MSEs = [MSEs mse];
        %}
        %{
        title("Fourier Transform, MSE: " + string(mse));

        %[PksL,LocsL] = findpeaks(abs(yshift), 'NPeaks', 3, 'SortStr', 'descend');
        %disp(LocsL);

        subplot(2,2,3:4);
        hold on;
        plot(x);
        plot(x_TS);
        xlabel('Time');
        title("Epsilon: " + string(epsilon));
        legend(["Original", "TS"]);
        %}
    end

    % Select the lower and upper bounds of epsilon values using MSE
    subplot(2,3,3*(q-1) + 1);
    semilogx(epsilons, MSEs, 'o');
    title("MSE between Fourier Spectrum"); %: " + string(h) + "," + string(q));
    ylabel("MSE");
    xlabel("Epsilon Value");
    
    subplot(2,3,3*(q-1) + 2);
    loglog(epsilons, MSEs, 'o');
    title("MSE between Fourier Spectrum"); %: " + string(h) + "," + string(q));
    ylabel("MSE");
    xlabel("Epsilon Value");

    subplot(2,3,3*(q-1) + 3);
    semilogx(epsilons, MSEs_signal, 'o');
    title("MSE between Signals"); %: " + string(h) + "," + string(q));
    ylabel("MSE");
    xlabel("Epsilon Value");

    
end
end
    

%% Upper bound

[val, max_epsval] = max(MSEs)

%% Lower bound

[val, max_epsval] = min(MSEs)

MSEs(5)

%% Sample script for selecting upper epsilon bound

% Set search space
low = -2; % 10e-2
high = 2; % 10e1
epsilon_search = logspace(low, high, 20);

max_vals = cell(2,1);
for q=1:8
    s_max = [];
    for s=1:height(data_raw)
        x_data = data_raw.Signals{s};
        x = x_data{q};

        MSEs = [];
        for epsilon=epsilon_search
            % TS Approximation
            [x_TS, ~] = taut_string(x, epsilon);

            % Fourier Transforms
            y = fft(x);   
            fs = 1/Ts;
            f = (0:length(y)-1)*fs/length(y);
            y_TS = fft(x_TS);

            n = length(x);                   
            fshift = (-n/2:n/2-1)*(fs/n);
            yshift_real = fftshift(y);
            yshift_TS = fftshift(y_TS);

            % Calculate the MSE
            err = abs(yshift_real - yshift_TS);
            err_sq = err.^2;
            mse = mean(err_sq);
            MSEs = [MSEs mse];
        end
        
        [max_val, max_idx] = max(MSEs);
        disp(max_idx);
        s_max = [s_max max_idx];        
    end
    max_vals{q} = s_max;
end

%% Select EMG epsilon values
%   Search range from 10e-10, 10e-3

max_vals = cell(8,1);

for q=1:8
    % Select signal and parameters
    x_data = data_raw.Signals{h};
    %close all
    %figure;
    s_max = [];
    for h=1:height(data_raw)
        disp(string(q) + " -- " + string(h) + "/" + string(height(data_raw)));
        x = x_data{q};
        epsilons = logspace(-10, -3, 20);
        % MSEs = [];
        MSEs_signal = [];
        for epsilon=epsilons
            % TS Approximation
            [x_TS, ~] = taut_string(x, epsilon);
            err = abs(x - x_TS);
            err_sq = err.^2;
            MSEs_signal = [MSEs_signal mean(err_sq)];
        end
        [max_val, max_idx] = max(MSEs_signal);
        disp(max_idx);
        s_max = [s_max max_idx];      
        %{
        subplot(8,1,q);
        title("Lead :" + string(q));
        semilogx(epsilons, MSEs_signal, 'o');
        ylabel("MSE");
        xlabel("Epsilon Value");
        %}
    end
    max_vals{q} = s_max;    
end


