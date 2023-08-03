function [X, Y, T, AUC, thresh, F1, sens, spec, acc, TP, TN, FP, FN] = ...
    ROC_AUC(labels, scores, varargin)
% Alexander Wood for BCIL 2019
%
% SYNTAX
% ------
% [X, Y, T, AUC] = ROC_AUC(labels,scores)
% [X, Y, T, AUC] = ROC_AUC(__,Name,Value)
%
% DESCRIPTION
% -----------
% Fast method of computing AUC, ROC. Splits into n different thresholds and
% computes for those thresholds. Works for binary classification. 
%
% Input scores and classes can be scalars or vectors.
% 
% EXAMPLES
% --------
% S = sort(rand(250),1);
% L = sort(logical(mod(im2uint8(rand(250)),2));
% [X,Y,T,AUC] = ROC_AUC(S, L)
% 
% Compute AUC using the maximal value of sensitivity + specificity.
% [X,Y,T,auc] = ROC_AUC (S, L, 'method', 2);
% 
% Compute AUC without displaying any charts.
% [X,Y,T,auc] = ROC_AUC(S,L,'DISPLAY_ROC',0);
% 
% Compute AUC and display charts of sensitivity, specificity, etc.
% [X,Y,T,auc] = ROC_AUC(S,L,'DISPLAY_ALL',1);
% 
% INPUT ARGUMENTS
% ---------------
% scores........[numeric,vector] The scores you assigned each point.
% labels........[numeric,logical,cell] The classes you assigned each point. 
%               (Ground truth). If the positive class is not 1, then please
%               provide a 'posclass' argument to get results. 
%
% NAME-VALUE PAIRS
% ----------------
% posclass......[DEFAULT=1] The positive class label.
% method........[numeric, >=1, <=5, OPTIONAL, DEFAULT=1] Different methods 
%               for choosing a point on the ROC curve for which we compute 
%               the F1 scores, sensitivity,specificity and accuracy.
%               The methods choose the point on the ROC curve where...
%                  * 1: ... the F1-score is maximal.
%                  * 2: ... sensitivity+specificity is maximal.
%                  * 3: ... the ROC curve closest to (0,1).
%                  * 4: ... the sens. and specificity are about the same.
%                  * 5: ... the accuracy is maximal.
%                  * 6: ... the ppv and npv are about the same
% DISPLAY_ROC...[logical, OPTIONAL, DEFAULT=true] Display the ROC plot
% DISPLAY_ALL...[logical, OPTIONAL, DEFAULT=false] Display other plots
%               (sens, spec, TPR, FPR, NPV, PPV, DICE/F1, etc)
%
% OUTPUT ARGUMENTS
% ----------------
% X..............X-coordinates of ROC curve points
% Y..............Y-coordinates of ROC curve points
% T..............Threshold values used
% AUC............AUC for ROC curve
% thresh.........Optimal threshold based on 'method'
% F1.............Optimal F1 score
% sens...........Optimal sensitivity
% spec...........Optimal specificity
% acc............Optimal accuracy
%
% EXAMPLE 1
% ---------
% load ionosphere
% resp = strcmp(Y,'b'); % resp = 1, if Y = 'b', or 0 if Y = 'g'
% pred = X(:,3:34);
% mdlNB = fitcnb(pred,resp);
% [~,score_nb] = resubPredict(mdlNB);
% ROC_AUC(resp, score_nb(:,mdlNB.ClassNames));
% 
% EXAMPLE 2 : String class names
% ------------------------------
% load fisheriris
% pred = meas(51:end,1:2);
% resp = (1:100)'>50;  % Versicolor = 0, virginica = 1
% mdl = fitglm(pred,resp,'Distribution','binomial','Link','logit');
% scores = mdl.Fitted.Probability;
% ROC_AUC(species(51:end), scores, 'posclass', 'virginica');
%%

% Input parsing
[scores, labels, method, n, DISPLAY_ROC, DISPLAY_ALL] = ...
    parse_inputs(scores, labels, varargin);

% Format scores and classes as scalars. 
scores  = scores(:);
labels = labels(:);

%% Compute the TP, FP, TN, FN for each threshold.

% % Normalize thresholds for ranges which appear in input scores.
score_min = min(scores(:));
score_max = max(scores(:));
% T = (score_max-score_min)*T + score_min;

% Sort scores by ascending.
[scores, perm] = sort(scores,'descend');

% Sort classes by the same permutation.
labels = labels(perm);

% Indexes of unique scores
[T, ~] = unique(scores);
T = [score_min-0.1; T];

% Concatenate the scores into two columns: Column 1, boolean 1 for each
% positive classification; column 2, boolean 1 for each negative
% classification. 
labels = cat(2,labels,~labels);
cum_labels = cumsum([0,0; labels(:,1:2);0,0],1); % Cumulative sum of counts of GT pos and GT neg.

% Indexes of which labels to look at based on unique scores.
[~,idx]=unique([scores;score_min-.1]);

% Get the cumulative label sums for each unique score.
cum_labels=cum_labels(idx,:);

% True positive vector.
TP = cum_labels(:,1);
FP = cum_labels(:,2);
TN = sum(labels(:,2))-FP; % #negative = TN + FP
FN = sum(labels(:,1))-TP; % #positive = TP + FN

% Calculate the metrics for each threshold.
F1 = (2*TP)./(FN + 2*TP + FP); F1(isnan(F1))=0; % Only TN -> 0 F1-score
sens = TP./(TP + FN); %sens(isnan(sens)) = 0; % Only TN or FP -> 0 sens
spec = TN./(TN + FP);
acc  = (TP+TN)./(TP+TN+FP+FN); % As long as there is a datapoint this won't divide by zero
PPV  = TP./(TP+FP);  PPV(isnan(PPV))=1;
NPV  = TN./(TN+FN);  NPV(isnan(NPV))=1;

%% Compute AUC, optional plot ROC

% Compute (X,Y) = (TPR,FPR)
X = 1-spec; Y = sens;

% Sort, ascending.
f = sortrows([X, Y], [1 2]);
X = f(:,1);
Y = f(:,2);
% [X,perm] = sort(X,'ascend');
% Y = Y(perm);

% Compute dX operator for the right and left Riemann sum.
dX = X(2:end)-X(1:end-1);

% Compute the left and right Riemann sums.
reimann_r = Y(2:end).*dX;
reimann_l = Y(1:end-1).*dX;

% Strictly increasing piecewise linear function (discrete case). So we
% add the area of the triangles between line and Riemann rectangles to get
% AUC.
AUC = sum(reimann_l + 0.5*(reimann_r-reimann_l));

% Compute the optimum threshold value. 
switch method
    case 1
        [~,I] = max(F1);
        idx = find(F1>=F1(I));
        t = idx(end);
    case 2
        G = sens+spec;
        [~,I] = max(sens + spec);
        idx = find(G>=G(I));
        t = idx(end);
    case 3
        G = (1-sens).^2 + (1-spec).^2;
        [~,I] = min(G);
        idx = find(G<=G(I));
        t = idx(end);
    case 4
        t = find(sens>spec, 1, 'last');
    case 5
        [~,I] = max(acc);
        idx= find(acc>=acc(I));
        t = idx(end);
    case 6
        t = find(NPV>PPV, 1, 'last');
end
thresh = T(t);

% Plot it.
if DISPLAY_ROC
    figure(1); hold off; clf; hold on
    xlim([-0.02,1.02]); ylim([-0.02,1.02]);
    plot(X,Y,'LineWidth',1.5);
    line([0 1], [0 1], 'Color','red','LineStyle','--')
    plot([X(t) X(t)],[0 1],'g:')
    legend('ROC','Random Guess','Threshold','location','best');
    xlabel('False positive rate')
    ylabel('True positive rate')
    title('ROC Curve')
    text(0.6, 0.3, ['AUC: ' string(AUC)])
    text(0.6, 0.2, ['Threshold:' string(thresh)])
    
    hold off
end

% Optional Displays
if DISPLAY_ALL
    % Display sensitivity, specificity, F1-score
    hold off; figure(2); clf; hold on;
    xlim([score_min-0.02,score_max+.02]); ylim([-0.02,1.02]);
    plot(T,F1,'LineWidth',1.5)
    plot(T,sens,'g--','Color',[.66 .33 0],'LineWidth',1.5)
    plot(T,spec,'m--','Color',[.45 0 .55],'LineWidth',1.5);
    plot([thresh thresh], [0 1], 'g:');
    xlabel('Threshold')
    ylabel('Percent')
    legend('F1/Dice', 'Sens/TPR', 'Spec/FPR','Threshold','location','best');
    hold off;
    
    % Display PPV, NPV, accuracy
    figure(3); hold off; clf; hold on;
    xlim([score_min-0.02,score_max+.02]); ylim([-0.02,1.02]);
    plot(T,acc,'LineWidth',1.5)
    plot(T,PPV,'--','Color',[.66 .33 0],'LineWidth',1.5)
    plot(T,NPV,'--','Color',[.45 0 .55],'LineWidth',1.5)
    plot([thresh thresh], [0 1], 'g:');
    xlabel('Threshold')
    ylabel('Percent')
    legend('Accuracy', 'PPV', 'NPV','Threshold','location','best');
    hold off;
    
    % Display TP, TN, FP, FN counts
    figure(4); hold off; clf; hold on;
    
    if length(T)>100
        M = 3*max([TP(:);FN(:);FP(:);TN(:)]);
        set(gca,'Yscale','log')
    else
        M = max([TP(:);FN(:);FP(:);TN(:)])+1;
    end
    xlim([min(T(:))-.02, max(T(:))+.02]); ylim([0,M+.02]);
    plot(T,TP,T,TN,T,FP,T,FN,'LineWidth',1.5);
    plot([thresh thresh thresh], [0 1 M], 'g:');
    xlabel('Threshold')
    ylabel('Count, Logaritihmic Scale')
    legend('TP', 'TN', 'FP', 'FN','Threshold','location','best');
    hold off;
    
    % Display Precision-Recall Curve
    figure(5); hold off; clf; hold on;
    xlim([score_min-0.02,score_max+.02]); ylim([-0.02,1.02]);
    plot(PPV, sens,'LineWidth',1.5)
    xlabel('Precision')
    ylabel('Recall')
    legend('Precision-Recall Curve','location','best')
    hold off;
end

% Set outputs based on thresh.
F1 = F1(t);
sens = sens(t);
spec = spec(t);
acc = acc(t);

end


function [scores, labels, method, n, DISPLAY_ROC, DISPLAY_ALL] = ...
    parse_inputs(scores, labels, varargin)
% INPUT VALIDATION
% Alexander Wood for BCIL 2019.
%%

% Default values
method = 1;
n = length(unique(labels));
posclass = 1;
DISPLAY_ROC = 1;
DISPLAY_ALL = 0;

% Error if n < 2 as there are not enough classes to evaluate AUC.
if n < 2
    error(message('Less than two input scores provided.'));
end

% Parse any optional arguments.
args = varargin{1};
if ~isempty(args)
    % Too many inputs!
    if length(args)>10
        error(message('images:validate:tooManyInputs', mfilename))
    end
    
    var_strings = {'posclass', 'method', 'DISPLAY_ROC', 'DISPLAY_ALL'};
    
    % Validate.
    for i = 1:2:length(args)
        param = validatestring(args{i},var_strings,mfilename);
        
        % Error if corresponding value is missing.
        if i+1>length(args)
            error(message('images:validate:missingValue',param));
        end
        
        switch param
            case 'posclass'
                posclass = args{i+1};
                
            case 'method'
                method = args{i+1};
                % Method should be integer 1, 2, 3, 4, or 5
                validateattributes(method,{'numeric'},{'scalar', ...
                    'integer', '<=', 6, '>=', 1}, mfilename, 'method');
                
            case 'DISPLAY_ROC'
                DISPLAY_ROC = args{i+1};
                
                % DISPLAY_ROC should be 1 or 0
                validateattributes(DISPLAY_ROC, {'numeric'},{'scalar', ...
                    'binary'}, mfilename,'DISPLAY_ROC');
                
            case 'DISPLAY_ALL'
                DISPLAY_ALL = args{i+1};
                % DISPLAY_ALL should be 1 or 0
                validateattributes(DISPLAY_ALL, {'numeric'},{'scalar', ...
                    'binary'}, mfilename,'DISPLAY_ALL');
        end
    end
end

% Set up labels as a vector the same size as the scores, where labels = 1
% for the positive class and 0 otherwise. 
labels = labels(:); % Set up as column, regardless of input size.
if isa(labels, 'cell')
    if isa(posclass, 'string')
        posclass = convertStringToChar(posclass);
    end
    if isa(labels{1}, 'string') || isa(labels{1}, 'char')
        labels = convertStringsToChars(labels);
        labels = contains(labels, posclass);
    elseif isa(labels{1}, 'numeric')
        labels = cell2mat(labels);
        labels = (labels == posclass);
    else
        error(message('Unsupported data type for input labels.'));
    end   
    posclass = 1;
end

labels = (labels == posclass);
validateattributes(labels,{'numeric','logical'},{'nonnan','nonempty',...
    'vector', 'binary'}, mfilename, 'labels');


% Input scores must be same size as input classes and range from 0 to 1.
N = size(labels,1);
scores = scores(:); % Set up as column, regardless of input size.
validateattributes(scores, {'single','double'}, {'nonnan' 'nonempty', ...
    'vector', 'size', [N 1]}, mfilename, 'scores');
end

