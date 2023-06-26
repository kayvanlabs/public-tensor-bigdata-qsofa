function  [features, names, tautStrings] = feature_compute_staticTS(hrv, widths)
% DESCRIPTION For each numerical value in 'widths', calculates Taut-String
% estimate of the input signal 'hrv' and returns statistical features
% derived from this Taut-String estimate. The features are meant for use in
% machine learning models.
%
% INPUTS
%     hrv       one-dimensional row array of numbers: "the signal"
%     widths    one-dimensional array of non-negative integer values, each
%               representing the Taut-String parameter "epsilon"
%     tautStrings  2-array containing all of the taut-string estimates
% OUTPUTS
%     features  1xN array of numbers representing the calculated features
%     names     Nx1 cell containing the names of the calculated features
%
% OS: Windows 10
% Language: Matlab R2017b 
% Revision Author: Larry Hernandez
% Date of Revision: April 3, 2018
%
% Original OS: Unknown
% Original Language: Matlab (version unknown)
% Original Author: Unknown (Maybe Sardar Ansari)
% Original Date: Unknown
%%
    % Initialization
    features = [];     
    names = [];
    warning('off');
    
    % Convert signal to row array for proper use with 'taut_string()'
    if(iscolumn(hrv))
        hrv = hrv';
    end
    
    n=length(hrv);
    m=length(widths);

    %
    tautStrings = zeros(m,n);
    
    % Calculate / extract features for each value of epsilon
    for i=1:m
        epsilon = widths(i);
        [hrv_denoised,hrv_bends_signal]=taut_string(hrv,epsilon);
        tautStrings(i,:) = hrv_denoised;
%         plot_hrv_tautstring(hrv, hrv_denoised, epsilon);
        hrv_bends = hrv_bends_signal(find(abs(hrv_bends_signal)));
        inflection_segments =abs(hrv_bends - [0,hrv_bends(1:end-1)]) / 2;
        
        hrv_noise=hrv-hrv_denoised;
        hrv_noise_derivative=hrv_noise-[0,hrv_noise(1:end-1)];
        
        epsilonAsString = num2str(epsilon);
        commonSuffix = strcat('_TS_StaticEpsilon_', epsilonAsString);
        
        sum_line_seg = sum(abs(hrv_bends_signal))/n;
        features = [features, sum_line_seg];
        names = [names;cellstr(strcat('Num_line_segments_per_beat', commonSuffix))];

        num_inflection_segments_per_beat = sum(inflection_segments)/n;
        features = [features, num_inflection_segments_per_beat];
        names = [names;cellstr(strcat('Num_inflection_segments_per_beat', commonSuffix))];

        %%% added 1/22/2015
        total_variation_per_beat = mean(abs(hrv_noise_derivative));
        features = [features, total_variation_per_beat];
        names = [names;cellstr(strcat('Total_variation_of_noise_per_beat', commonSuffix))];
        
        if (length(hrv_denoised) > 1)
            total_variation_of_denoised_signal = mean(abs(hrv_denoised(2:end)-hrv_denoised(1:end-1)));
        else
            total_variation_of_denoised_signal = 0;
        end
        features = [features, total_variation_of_denoised_signal];
        names = [names;cellstr(strcat('Total_variation_of_denoised_signal_per_beat', commonSuffix))];


        % power of HRV noise
        if (length(hrv_noise) > 1)
            power_of_hrv_noise = sqrt(mean((hrv_noise(2:end)-hrv_noise(1:end-1)).^2));
        else
            power_of_hrv_noise = 0;
        end 
        features = [features, power_of_hrv_noise];
        names = [names;cellstr(strcat('Power_of_hrv_noise', commonSuffix))];

        % power of denoised HRV signal
        if (length(hrv_denoised) > 1)
            power_of_hrv_denoised = sqrt(mean((hrv_denoised(2:end)-hrv_denoised(1:end-1)).^2));
        else
            power_of_hrv_denoised = 0;
        end
        features = [features, power_of_hrv_denoised];
        names = [names;cellstr(strcat('Power_of_hrv_denoised', commonSuffix))];
        

    end



end
