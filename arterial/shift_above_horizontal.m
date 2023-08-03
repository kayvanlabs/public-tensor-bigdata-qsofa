function x = shift_above_horizontal(x)


%%
% Shift signal so it rests on x-axis (so no peak has zero amplitude)
minx = min(x);
if (minx < 0)
    x = abs(minx) + x;
end

end % eof