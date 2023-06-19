function [P] = myML3(trainData,trainClass,classes,testData,Lambda,Theta,trainWeight)
% inputs:
%   trainData: m*n array of feauters (m # of samples and n is number odf features)
%   trainClass: m*1 cell of chars(m # of samples)
%   classes: unique calss values (char)
%   testData: m2*n array of feauters (m2 # of samples and n is number odf features)
%   Lambda: a positive number which should be found for each train Dataset
%   Theta: a positive number which should be found for each train Dataset
%   trainWeight: m*1: equal to # of samples, if there is no privelidge
%   among sample, set all of its values equal to one
% output: 
%   P:  m2*number of classes. Shows the classification probability of each test sample for
%   each class







[m,n]=size(trainData); % m training vectors, n features
[l,n]=size(testData);  % l test vectors
totalWeight=sum(trainWeight);
trainAve=sum(trainData.*(trainWeight*ones(1,n)))/totalWeight;
trainDataNorm=trainData-ones(m,1)*trainAve;
testDataNorm=testData-ones(l,1)*trainAve;
trainSTD=10^(-10)+sqrt(sum(trainDataNorm.^2.*(trainWeight*ones(1,n)))/totalWeight);
lambda=sqrt(Lambda)./trainSTD; % compute lambda parameters
trainDataNorm=trainDataNorm.*lambda(ones(m,1),:); % normalize training data
testDataNorm=testDataNorm.*lambda(ones(l,1),:); % nomalize test data
d=length(classes);
alph=zeros(1,n);
for j=1:m
    %fprintf('train: %6d\n',j);
    a=strcmp(trainClass,trainClass(j));
    if a ~=0
        disp('bingo')
    end
    aSum=sum(a.*trainWeight);
    if sum(a)>1
        %MH: here  b(j) is always set to zero
        b=(a.*trainWeight)/(aSum-trainWeight(j))-trainWeight/(totalWeight-trainWeight(j));b(j)=0;
        alph = alph + trainWeight(j)*sum(b(:,ones(n,1)).*(1+(trainDataNorm-trainDataNorm(j*ones(m,1),:)).^2).^(-Theta));
    end
end
alph=max(alph,0);
theta=alph*Theta/sum(alph)*n; % compute theta parameters
P=zeros(l,d);
for k=1:d
    classList{k}=find(strcmp(classes(k),trainClass));
end
Q=zeros(1,d);
for j=1:l
    %fprintf('classify: %6d\n',j);
    Qprod=prod((1+(trainDataNorm-testDataNorm(j*ones(m,1),:)).^2).^(-theta(ones(m,1),:)),2);
    for k=1:d
        Q(k)=sum(Qprod(classList{k}).*trainWeight(classList{k}));
    end
    P(j,:)=Q/sum(Q);
    [v,w]=max(Q);
    classification(j,1)=classes(w);    
end
end

