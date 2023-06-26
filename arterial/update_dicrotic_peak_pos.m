function [idxF,idxS,idxD] = update_dicrotic_peak_pos(x,idxF,idxS,idxD)
% DESCRIPTION   Given a blood pressure waveform and indices of systolic & 
%               dicrotic peaks, finds and updates incorrect dicrotic peak
%               indices
%
% INPUTS
%   x       vector: signal
%   idxF    vector: indices of foot at end of each cycle
%   idxS    vector: indices of systolic peaks
%   idxD    vector: indices of dicrotic peaks
% 
% OUTPUTS
%   idxS    vector: indices of systolic peaks
%   idxD    vector: indices of dicrotic peaks
%
% Language: MATLAB R2017b
% OS: Windows 10
% Author: Larry Hernandez
% Date: Dec 20, 2018
%% [1] Make sure that the length of all the indices is equal. If
% not, then find a way to make them so.
[idxF,idxS,idxD] = bp_starting_pos(idxF,idxS,idxD);

return;

%% [2] Check if the relative positions of the indices is accurate. If so,
% perform feature extraction. If not, then re-organize in a smarter way.

n = length(footIndex);
mylabels = zeros(3,n);
mylabels(1,:) = footIndex(1:n);
mylabels(2,:) = idxS(1:n);
mylabels(3,:) = idxD(1:n);

mybools = zeros(size(mylabels));
for j=1:n
    mybools(2,j) = mylabels(2,j) > mylabels(1,j);
    mybools(3,j) = 2*(mylabels(3,j) > mylabels(2,j));
end

srow2 = sum(mybools(2,:));
srow3 = sum(mybools(3,:));

idxs2 = find(mybools(2,:) == 0);
idxs3 = find(mybools(3,:) == 0);

if ( (srow2 == n) && not(srow3 == 2*srow2) )
%     disp('Inconsistency in rel. position of systolic & dicrotic peaks');
    for j=1:length(idxs3)
        col = idxs3(j);
        if (length(footIndex) > col)
            % Find a peak residing between current Systole and next Foot
            z = x(idxS(col):footIndex(col+1));
            [Lmax,~] = GetFSABP(z);
            if not(isempty(Lmax))
                idxD(col) = Lmax(1) + idxS(col) - 1;
            else
                idxD(col) = mean(idxS(col),footIndex(col+1));
            end
        else
            idxS(col) = [];
            idxD(col) = [];
            footIndex(col) = [];
        end
    end
end


if ( not(srow2 == n) && not(srow3 == 2*srow2) )
    disp('Need to resolve this case');
    for j=1:length(idxs2)
        
    end
end

end % eof