%% HOSVD Mode 2 Binary Search
%
% This function does a binary search looking for the minimum mode 2 length
% so that the tensor decomposition to that mode length acheives a certain
% tolerance.
%
% Parameters:
%   - tensor: the tensor for the HOSVD decomposition
%   - hosvd_error: the error tolerance for the HOSVD decomposition
%   - modes: the dimension of each mode except mode 2
%   - upper: the maximum possible upper mode
%   - search_mode: the mode we are searching in
%
% Joshua Pickard jpic@umich.edu

function [T,E]=hosvd_bin_search(tensor, hosvd_error, modes, upper, lower, search_mode)
    try_mode = lower + round((upper - lower) / 2 - 0.0001);
    modes(search_mode) = try_mode;
    [T, E] = hosvd(tensor, hosvd_error, 'rank', modes);
    if upper - lower == 0
        return
    elseif E > hosvd_error && upper - 1 ~= lower
        [T,E] = hosvd_bin_search(tensor, hosvd_error, modes, upper, try_mode, search_mode);
    elseif E < hosvd_error % If the error is acceptable but we want to keep searching downwards
        [T2, E2] = hosvd_bin_search(tensor, hosvd_error, modes, try_mode, lower, search_mode);
        if E2 < hosvd_error && upper ~= lower
            T = T2;
            E = E2;
        end
    end
end
