function [prAuc, rec, mprec, prec] = computePRCAUC(labels, scores)
% DESCRIPTION
% Function to compute area under precision-recall curve
% Based off https://towardsdatascience.com/how-to-efficiently-implement-area-under-precision-recall-curve-pr-auc-a85872fd7f14

    %scores = [0.65, 0.1, 0.15, 0.43, 0.97, 0.24, 0.82, 0.7, 0.32, 0.84];
    %labels = [0, 0, 1, 0, 1, 1, 0, 1, 1, 1];

    [scores, idx] = sort(scores, 'descend');
    labels = labels(idx);
    
    cs = cumsum(labels);
    thisRank = 1:length(cs);
    csEnd = cs(end);
    
    prec = cs ./ thisRank;
    rec = cs ./ csEnd;
    
    % Add sentinel values
    prec = [0, prec, 0];
    rec = [0, rec, 1];
    
    % Compute precision envelope
    mprec = prec;
    for i = (length(mprec) - 1):-1:2
        mprec(i - 1) = max(prec(i - 1), mprec(i));
    end
    
    prAuc = 0;
    for i = 1:(length(mprec) - 1)
        prAuc = prAuc + ((rec(i + 1) - rec(i)) * mprec(i + 1));
    end
    
    
end