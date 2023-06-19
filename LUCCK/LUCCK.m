classdef LUCCK
% Class version of Harm Derksen's myML3/learning using concave/convex
% kernels
%
% Written by Olivia Pifer Alge
% September 2021
% Matlab 2020b Windows 10
% For BCIL

%% INPUTS for constructor
%   trainData: m*n array of feauters (m # of samples and n is number odf features)
%   trainClass: m*1 cell of chars(m # of samples)
%   classes: unique calss values (char)
%   Lambda: a positive number which should be found for each train Dataset
%   Theta: a positive number which should be found for each train Dataset
%   trainWeight: m*1: equal to # of samples, if there is no privelidge
%                among sample, set all of its values equal to one

    properties
        % Provided by user in constructor
        classes
        trainClass
        trainData {mustBeNumeric}
        Lambda {mustBeNumeric}
        Theta {mustBeNumeric}
        trainWeight {mustBeNumeric}
                
        % Created internally
        classList
        lambda {mustBeNumeric}  % Lambda customized for train data
        theta {mustBeNumeric}  % Theta customized for train data
        trainAve {mustBeNumeric}
        trainDataNorm {mustBeNumeric}
    end
    
    methods
        %% Constructor
        function obj = LUCCK(trainData, trainClass, classes, Lambda, Theta, trainWeight)
            if nargin < 5
                error('Not enough input arguments provided')
            end 
            
            % assign properties
            obj.trainData = trainData;
            obj.trainClass = trainClass;
            obj.classes = classes;
            obj.Lambda = Lambda;
            obj.Theta = Theta;
            
            if nargin == 6
                obj.trainWeight = trainWeight;
            else  % if weights not provided, assume equal weights
                obj.trainWeight = ones(size(trainData, 1), 1);
            end
            
            % Build the model
            obj = build_lucck(obj);
        end
        
        % Building the LUCCK model
        function obj = build_lucck(obj)
            [m, n] = size(obj.trainData); % m training observations, n features
            nOnes = ones(1, n);
            mOnes = ones(1, m);
            totalWeight = sum(obj.trainWeight);
            obj.trainAve = sum(obj.trainData .* (obj.trainWeight * nOnes)) / totalWeight;
            trainNorm = obj.trainData - mOnes' * obj.trainAve;  % Remove mean
            trainSTD = 10^(-10) + sqrt(sum(trainNorm.^2 .* (obj.trainWeight * nOnes)) / totalWeight);
            % Compute lambda parameters
            obj.lambda = sqrt(obj.Lambda) ./ trainSTD;
            % Normalize train data
            obj.trainDataNorm = trainNorm .* obj.lambda(mOnes, :);
            d = length(obj.classes);
            alph = zeros(1, n);

            for j = 1:m
                a = strcmp(obj.trainClass, obj.trainClass(j));
                if a ~= 0
                    %disp('bingo');
                end
                aSum = sum(a .* obj.trainWeight);
                if sum(a) > 1
                    % MH: here b(j) is always set to zero
                    b = (a .* obj.trainWeight) / (aSum - obj.trainWeight(j)) - obj.trainWeight / (totalWeight - obj.trainWeight(j));
                    b(j) = 0;
                    alph = alph + obj.trainWeight(j) * sum(b(:, nOnes) .* (1 + (obj.trainDataNorm - obj.trainDataNorm(j * mOnes, :)).^2).^(-obj.Theta));
                end
            end

            alph = max(alph, 0);
            obj.theta = alph * obj.Theta / sum(alph) * n;  % compute theta parameters
            if all(isnan(obj.theta))
                obj.theta = zeros(1, length(obj.theta));
            end

            for k = 1:d
                obj.classList{k} = find(strcmp(obj.classes(k), obj.trainClass));
            end
        end
        
        %% Test set prediction
        function P = predict(obj, testData)
        % INPUT
        %   testData: m2*n array of feauters (m2 # of samples and n is number of features)
        % OUTPUT
        %   P: m2*number of classes. Shows the classification probability of each test sample for
        %      each class
            [lTest, n] = size(testData);
            [m, ~] = size(obj.trainData); % m training observations, n features
            d = length(obj.classes);
            mOnes = ones(1, m);
            testDataNorm = testData - ones(lTest, 1) * obj.trainAve;
            % Normalize test data
            testDataNorm = testDataNorm .* obj.lambda(ones(lTest, 1), :);
            P = zeros(lTest, d);
            Q = zeros(1, d);
            for j = 1:lTest
                Qprod = prod((1 + (obj.trainDataNorm - testDataNorm(j * mOnes, :)).^2).^(-obj.theta(mOnes, :)), 2);
                for k = 1:d
                    Q(k) = sum(Qprod(obj.classList{k}) .* obj.trainWeight(obj.classList{k}));
                end
                P(j, :) = Q / sum(Q);
                [v, w] = max(Q);
                classification(j, 1) = obj.classes(w);
            end
        end
    end

end