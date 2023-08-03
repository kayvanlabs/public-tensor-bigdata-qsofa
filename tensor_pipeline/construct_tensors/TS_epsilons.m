% DESCRIPTION: This function was intended to select the epsilon values
% used by Taut String; however, it did not work as intended, and it
% currently has a number of errors. Please do not use this function.
%
%   Joshua Pickard (jpic@umich.edu)
function epsilons = TS_epsilons(data, params, MSE_values)
    % Check the number of signals
    signals = data.Signals{1};
    num_signals = length(signals);
    epsilons = zeros(num_signals, length(MSE_values));
    for s=1:num_signals
        e_MSEs_c = cell(length(MSE_values), 1);
        disp(height(data));
        %% Test code
        for sample=1:height(data)
            disp(string(sample));
            % Extract the signal
            signals = data.Signals{sample};
            signal = signals{s};
            % Rotate the signal
            sizes = size(signal);
            if sizes(1) > sizes(2)
                signal = signal';
            end
            %signal = signal';
            % Compute the maximum MSE, if a straight line is used
            large_epsilon = 1000000000;
            %[a,~] = taut_string(signal,large_epsilon);
            a = zeros(1, length(signal));
            error = (signal-a);
            sqd = error .* error;
            max_MSE = mean(sqd);
            MSE_new = max_MSE;
            large = params('Max Epsilon');
            small = 0;
            epsilon = (large + small) / 2;
            for mse_i=1:length(MSE_values)
                %% mse_i = 9
                mse = MSE_values(mse_i);
                upper_mse = mse * 1.05 * max_MSE; %(1 - mse + tolerance);
                lower_mse = mse * 0.95 * max_MSE; %(1 - mse - tolerance);
                small = 0; % Reset small, but if the MSE values are sorted
                           % then large doesn't neet to be reset
                while MSE_new > upper_mse || MSE_new < lower_mse
                    [a,~] = taut_string(signal,epsilon);
                    error = (signal-a);
                    sqd = error .* error;
                    MSE_new = mean(sqd);
                    if MSE_new < lower_mse
                        small = epsilon;
                        epsilon = (epsilon + large) / 2;
                    elseif MSE_new > upper_mse
                        large = epsilon;
                        epsilon = (epsilon + small) / 2;
                    end
                end
                e_MSEs_c{mse_i} = [e_MSEs_c{mse_i}, epsilon];
                %figure; plot(signal); hold on; plot(a); legend(["Raw" "TS"]); title(string(mse));
                
            end
        end
        % Compute the average values of the epsilons
        signal_epsilons = zeros(length(MSE_values), 1);
        for e=1:length(MSE_values)
            signal_epsilons(e) = mean(e_MSEs_c{e});
        end
        epsilons(s,:) = signal_epsilons;
    end
end

% figure; plot(signal); hold on; plot(a);


