function [X, Y, AUC] = ...
    PRC_AUC(labels, scores, varargin)
% Olivia Alge for BCIL 2021
% Modified from Alex Wood's ROC_AUC function.
% Reviewed before creation of this code:
% MathWorks Quant Team (2021). Fraud Detection using Machine Learning (https://www.mathworks.com/matlabcentral/fileexchange/68627-fraud-detection-using-machine-learning), MATLAB Central File Exchange. Retrieved May 14, 2021.
%
% SYNTAX
% ------
% [X, Y, T, AUC] = PRC_AUC(labels,scores)
% [X, Y, T, AUC] = PRC_AUC(__,Name,Value)
%
% DESCRIPTION
% -----------
% Fast method of computing area under the precision-recall curve.
% Splits into n different thresholds and
% computes for those thresholds. Works for binary classification.
%
% Input scores and classes can be scalars or vectors.
% 
% EXAMPLES
% --------
% S = sort(rand(250),1);
% L = sort(logical(mod(im2uint8(rand(250)),2));
% [X,Y,T,AUC] = PRC_AUC(S, L)
% 
% Compute AUC using the maximal value of sensitivity + specificity.
% [X,Y,T,auc] = PRC_AUC (S, L, 'method', 2);
% 
% Compute AUC without displaying any charts.
% [X,Y,T,auc] = PRC_AUC(S,L,'DISPLAY_PRC',0);
% 
% Compute AUC and display charts of sensitivity, specificity, etc.
% [X,Y,T,auc] = PRC_AUC(S,L,'DISPLAY_ALL',1);
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
%               for choosing a point on the PR curve for which we compute 
%               the F1 scores, sensitivity,specificity and accuracy.
%               The methods choose the point on the PR curve where...
%                  * 1: ... the F1-score is maximal.
%                  * 2: ... sensitivity+specificity is maximal.
%                  * 3: ... the PRC curve closest to (0,1).
%                  * 4: ... the sens. and specificity are about the same.
%                  * 5: ... the accuracy is maximal.
%                  * 6: ... the ppv and npv are about the same
% DISPLAY_PRC...[logical, OPTIONAL, DEFAULT=true] Display the PRC plot
% DISPLAY_ALL...[logical, OPTIONAL, DEFAULT=false] Display other plots
%               (sens, spec, TPR, FPR, NPV, PPV, DICE/F1, etc)
%
% OUTPUT ARGUMENTS
% ----------------
% X..............X-coordinates of PR curve points
% Y..............Y-coordinates of PR curve points
% AUC............AUC for PR curve
%
% EXAMPLE 1
% ---------
% load ionosphere
% resp = strcmp(Y,'b'); % resp = 1, if Y = 'b', or 0 if Y = 'g'
% pred = X(:,3:34);
% mdlNB = fitcnb(pred,resp);
% [~,score_nb] = resubPredict(mdlNB);
% PRC_AUC(resp, score_nb(:,mdlNB.ClassNames));
% 
% EXAMPLE 2 : String class names
% ------------------------------
% load fisheriris
% pred = meas(51:end,1:2);
% resp = (1:100)'>50;  % Versicolor = 0, virginica = 1
% mdl = fitglm(pred,resp,'Distribution','binomial','Link','logit');
% scores = mdl.Fitted.Probability;
% PRC_AUC(species(51:end), scores, 'posclass', 'virginica');
%%

% Input parsing
[scores, labels, method, n, DISPLAY_PRC, DISPLAY_ALL] = ...
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
PPV  = TP./(TP+FP);  PPV(isnan(PPV))=0;
NPV  = TN./(TN+FN);  NPV(isnan(NPV))=0;

%% Compute AUC, optional plot PRC

% Compute (X,Y)
X = sens; Y = PPV;

% sort data (based on accending order of X)
[X, idx] = sort(X);
Y = Y(idx);

% If X doesn't start at zero, connect Y using a horizontal line
if X(1) ~= 0
    Y = [Y(1); Y];
    X = [0; X];
end

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
%AUPRC = trapz(X,Y);

% Plot it.
if DISPLAY_PRC
    figure;
    plot(X, Y, 'LineWidth',1.5)
    ylabel('Precision')
    xlabel('Recall')
    legend('Precision-Recall Curve','location','best')
    hold off;
    legend('Precision-Recall Curve','location','best');
    xlabel('Recall (Sensitivity)')
    ylabel('Precision (PPV)')
    title('PR Curve')
    text(0.6, 0.3, ['AUC: ' string(AUC)])
end

end


function [scores, labels, method, n, DISPLAY_PRC, DISPLAY_ALL] = ...
    parse_inputs(scores, labels, varargin)
% INPUT VALIDATION
% Alexander Wood for BCIL 2019.
%%

% Default values
method = 1;
n = length(unique(labels));
posclass = 1;
DISPLAY_PRC = 1;
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
    
    var_strings = {'posclass', 'method', 'DISPLAY_PRC', 'DISPLAY_ALL'};
    
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
                
            case 'DISPLAY_PRC'
                DISPLAY_PRC = args{i+1};
                
                % DISPLAY_PRC should be 1 or 0
                validateattributes(DISPLAY_PRC, {'numeric'},{'scalar', ...
                    'binary'}, mfilename,'DISPLAY_PRC');
                
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