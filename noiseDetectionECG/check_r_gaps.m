function [window_ok] = check_r_gaps(R_idx,th,avg_RR,windowsize)
%check_gaps checks if a window misses too many R peaks
%   If too many R peaks are missing output is 0 otherwise 1
%   INPUTS: R_idx vector for current window, Fs sampling frequency,
%   threshold(in %) if sum of gap time is in total more than threshold % of
%   windowsize(in seconds) then window_ok = 0 otherwise 1
% OUTPUT: 1 if not too many gaps and 0 if too many gaps

if ~isempty(R_idx) && length(R_idx) > 3 % if there are R peaks

    % gap to first R ind
    gap1 = R_idx(1);
    
    % gap to last R ind
    gap2 = windowsize - R_idx(end);
    
    % any gaps btwn r idx
    RR = diff(R_idx);
    gap3 = max(RR);
    
    %output
    if gap1 > th || gap2 > th || gap3 > th
        gap = max([gap1 gap2 gap3]);
        if gap > avg_RR * 1.5
            window_ok = 0;
            return
        end
    end
    
    window_ok = 1;
    
else
    window_ok = 0; % there are too few R peaks in this window
end

end

