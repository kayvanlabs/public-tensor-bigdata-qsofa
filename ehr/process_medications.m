function medications = process_medications(filename,params)
% DESCRIPTION Function that process the medications_administered file
% 
% INPUTS
%   filename    character array: full file name of the CSV file
%               containing administered medications. N.B. The CSV must be 
%               sorted by DoD_ID,DoD_Enc_ID,Dose Start, in that sequence 
%               in ascending order.
%
%   params      structure containing additional parameters:
%               savefile  - if set, save the results to filename savefile
%
% OUTPUTS
%   medications structure contaning processed medications: 
%               .CVI - this contains data related to the inotropes/
%               vasopressors associated with outcomes in this study. .CVI 
%               is a Map whose keys correspond to the values in 
%               cviNames; the values are a second map container whose keys 
%               are patient_id+enc_id and whose values are IntervalTrees
%               .nonCVI - medications that not infusions
%
%
% Language: MATLAB R2018b
% Author: Jonathan Gryak
% Date: 20190204
%%
%MedicationTermIDs of cardiovascular infusions
cviCode_keys={183761,80090,191386,154289,191726,192894,80727,192350,...
    79376,193110,154811,191697,183677,183524,191851,80136,191875,...
    80178,154722,80130,190939,79763,154361,154637,81425,191026,154770,...
    79688,191193,80123};
%Names of cardiovascular infusions
cviCode_values={'Dobutamine','Dobutamine','Dobutamine','Dopamine',...
    'Dopamine','Dopamine','Dopamine','Dopamine','Dopamine',...
    'Epinephrine','Epinephrine','Epinephrine','Epinephrine',...
    'Epinephrine','Epinephrine','Epinephrine','Epinephrine',...
    'Isoproterenol','Milrinone','Milrinone','Milrinone','Milrinone'...
    ,'Norepinephrine','Norepinephrine','Norepinephrine',...
    'Norepinephrine','Vasopressin','Vasopressin','Vasopressin'...
    ,'Vasopressin'};
cviCodes=containers.Map(cviCode_keys,cviCode_values);
%Names of cardiovascular infusions
cviNames={'Dobutamine','Dopamine','Epinephrine',...
    'Isoproterenol','Milrinone','Norepinephrine','Vasopressin'};
%threshold values above which to consider a cardiovascular infusion
%escalated
cviEscalation_values={2.0,2.5,.02,2.0,.25,.1,2};
numCVIs=length(cviNames);
cviIndex=containers.Map(cviNames,1:numCVIs);
cviEscalations=containers.Map(cviNames,cviEscalation_values);

%mapping used to determine if the dosage needs to be converted
doseconvert_keys={'183761MCG/KG/MIN','191386MCG/KG/MIN',...
    '154289MCG/KG/MIN','191726MCG/KG/MIN','192894MCG/KG/MIN',...
    '192350MCG/KG/MIN','193110MG','154811MG','191697MG','183677MG',...
    '183524MCG/KG/MIN','183524MCG/MIN','191851MCG/KG/MIN',...
    '191875MCG/KG/MIN','154722MCG/KG/MIN','190939MCG/KG/MIN',...
    '154361MCG/KG/MIN','154637MCG/KG/MIN','191026MCG/KG/MIN',...
    '154770UNITS/HR','191193UNITS/HR','191193UNITS/MIN'};
doseconvert_values={0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0};
doseConvert=containers.Map(doseconvert_keys,doseconvert_values);
fluidconvert_keys={'80090microgram/kg/hour','80090microgram/kg/min',...
    '80727microgram/kg/min','80727microgram/kg/hour',...
    '79376microgram/kg/min','80136microgram/kg/min','80136mL/hour',...
    '80136nanograms/kg/min','80136microgram/kg/hour','80136units/hour',...
    '80136microgram/min','80178microgram/min','80130microgram/kg/min',...
    '80130mL/hour','80130microgram/kg/hour','80130microgram/min',...
    '80130nanograms/kg/min','79763microgram/kg/min','79763mL/hour',...
    '81425microgram/kg/min','81425mL/hour','81425nanograms/kg/min',...
    '81425microgram/min','79688units/hour','79688nanograms/kg/min',...
    '79688mL/hour','79688microgram/kg/min','80123units/hour',...
    '80123mL/hour'};
fluidconvert_values={0,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,1,0,1,0,0,...
    0,0,0,0,0,0};
fluidConvert=containers.Map(fluidconvert_keys,fluidconvert_values);

%VAClass codes for non-cardiovascular infusions
noncvi_keys={'AD','AH','AM','AU','BL','CN','DE','DX','GA','GU','HA'...
    ,'CV100','CV150','CV200','CV250','CV300','CV350','CV400'...
    ,'CV490','CV500','CV600','CV700','CV701','CV702','CV703','CV704'...
    ,'CV709','CV800','CV805','CV806','CV900'...
    ,'HS','IR','MS','NT','OP','OR','OT','PH','RE','RS','TN','VT','XX'};
numNonCVIs=length(noncvi_keys);
noncviIndex=containers.Map(noncvi_keys,1:numNonCVIs);

%end of time, for representing infinity
EOT=datenum(datetime("31-Dec-9999 12:00:00"));
%%
idCol = 'SepsisID';
encCol = 'EncID';
dateCol = 'DoseStartTime';
termIdCol = 'MedicationTermID';
fluidRateCol = 'FluidRate';
doseCol = 'Dose';
fluidUMCol = 'FluidRateUofMOriginal';
doseUMcol = 'DoseUofMOriginal';
doseStartCol = 'DoseStartTime';
vaCodeCol = 'VaClassCode';
%read table
meds=readtable(filename);
meds=sortrows(meds, {idCol, encCol, dateCol});
[numRows,~]=size(meds);
%create result data structure
medications=struct;
medications.CVI=containers.Map;
medications.nonCVI=containers.Map;
%save nonCVI feature names
nonCVINames=noncvi_keys;
nonCVINames{numNonCVIs+1}='MedOverlap';
medications.nonCVINames=nonCVINames;

%create  map for each CVI
for i=1:numCVIs
    %map patients to interval trees for each feature
    medications.CVI(cviNames{i})=containers.Map;
end
interval=struct;
%state for CVIs
prevKey=NaN;
allIntervals=cell(1,numCVIs);
numIntervals=zeros(1,numCVIs);

%state for nonCVIs
prevNonCVITime=datetime('tomorrow');
currNonCVIs=zeros(1,numNonCVIs+1);
%%
%process each row
for row=1:numRows
    currID=meds{row,idCol};
    currEnc=meds{row,encCol};
    %create key
    currKey= string(currID)+currEnc;
    %check for new id/encounter pair
    if ~strcmp(prevKey,currKey)
        %process CVI intervals
        for i=1:numCVIs
            %check if not first interval
            if numIntervals(i)~=0
                %get interval tree for this result code and patient
                cviMap=medications.CVI(cviNames{i});
                it=cviMap(prevKey);
                %add all intervals to the tree                
                for j=1:(numIntervals(i)-1)                    
                    interval.low=datenum(allIntervals{i}{j}{1});
                    interval.high=datenum(dateshift(allIntervals{i}{j+1}{1},'start','second','previous'));
                    it.Insert(interval,allIntervals{i}{j}{2});
                end
                %add final interval
                interval.low=datenum(allIntervals{i}{numIntervals(i)}{1});
                interval.high=EOT;
                it.Insert(interval,allIntervals{i}{numIntervals(i)}{2});
            end
        end
       
        %check if not first interval for non-CVI
        if prevNonCVITime~=datetime('tomorrow')
            %process last nonCVI interval
            interval.low=datenum(prevNonCVITime);
            interval.high=datenum(dateshift(prevNonCVITime,'start','second',86399));
            it=medications.nonCVI(prevKey);
            it.Insert(interval,currNonCVIs);
        end
        
        %save key
        prevKey=currKey;
        %create new tree for the patient for each CVI
        for i=1:numCVIs
            cviMap=medications.CVI(cviNames{i});
            cviMap(currKey)=IntervalTree();
        end
        allIntervals=cell(1,numCVIs);
        numIntervals=zeros(1,numCVIs);
        %create new tree for the patient for non-CVIs and non-CV
        medications.nonCVI(currKey)=IntervalTree();       
        
        %reset state for non-CVIs
        prevNonCVITime=datetime('tomorrow');
        currNonCVIs=zeros(1,numNonCVIs+1);
    end
    %process CVIs
    if isKey(cviCodes,meds{row,termIdCol})
        %get CVI name
        cviName=cviCodes(meds{row,termIdCol});
        %get CVI index
        index=cviIndex(cviName);
        %get dose
        currDose=meds{row,doseCol};
        if currDose == 0
            %get fluid rate
            currDose=str2double(meds{row,fluidRateCol});
            conversionMap=fluidConvert;
            conversionkey=strcat(string(meds{row,termIdCol}),meds{row,fluidUMCol});
        else
            conversionMap=doseConvert;
            conversionkey=strcat(string(meds{row,termIdCol}),meds{row,doseUMcol});
        end
        %determine if the dosage would need to be converted
        if currDose==0
            %don't need to convert a dosage/fluid rate of 0
            requiresConversion=0;
        elseif isKey(conversionMap,conversionkey)
            %check if the dosage/fluid rate needs to be converted
            requiresConversion=conversionMap(conversionkey);
        else
            %unknown unit, so skip
            requiresConversion=1;
        end
        %skip if currDose isn't defined or requires conversion      
        if ~isnan(currDose) && ~requiresConversion
           %encode CVI level
           if currDose == 0
               %not on CVI
               encodedValue=1;
           elseif currDose <= cviEscalations(cviName)
               %normal CVI
               encodedValue=2;
           else
               %elevated CVI
               encodedValue=3;
           end
            %convert date to datetime
            newTime=datetime(meds{row,doseStartCol},'InputFormat','yyyy-MM-dd HH:mm:ss.SSSSSSS');
            %ignore duplicate times for the same feature
            if numIntervals(index) < 1 || allIntervals{index}{numIntervals(index)}{1}~=newTime 
                %increment numIntervals
                numIntervals(index)=numIntervals(index)+1;        
                %add new interval and encoded value to the cell array  
                allIntervals{index}{numIntervals(index)}={newTime,encodedValue};
            end
        end
    %process non-CVIs
    elseif ~isempty(meds{row,vaCodeCol}{1}) && (isKey(noncviIndex,meds{row,vaCodeCol}{1}) || isKey(noncviIndex,extractBefore(meds{row,vaCodeCol}{1},3)))
        %convert date to datetime, extract date
        newTime=datetime(meds{row,doseStartCol},'InputFormat','yyyy-MM-dd HH:mm:ss.SSSSSSS');
        %if new date and not the first date, add interval and value to tree
        if newTime~=prevNonCVITime && prevNonCVITime ~= datetime('tomorrow')
            interval.low=datenum(prevNonCVITime);
            interval.high=datenum(dateshift(prevNonCVITime,'start','second',86399));
            it=medications.nonCVI(currKey);
            it.Insert(interval,currNonCVIs);
            currNonCVIs=zeros(1,numNonCVIs+1);
        end
        %process medication
        currMed=meds{row,termIdCol};
        currClass=extractBefore(meds{row,vaCodeCol}{1},3);
        %get full code for CVs
        if strcmp(currClass,'CV')
            currClass=meds{row,vaCodeCol}{1};
        end
        index=noncviIndex(currClass);
        if newTime==prevNonCVITime && currMed==prevNonCVIMed         
                %ignore same class
                if ~strcmp(currClass,prevNonCVIClass)
                    %increment class counter
                    currNonCVIs(index)=currNonCVIs(index)+1;
                    %and redundancy counter
                    currNonCVIs(numNonCVIs+1)=currNonCVIs(numNonCVIs+1)+1;
                end
        %if time, medication not the same
        else         
            %increment class counter
            currNonCVIs(index)=currNonCVIs(index)+1;
        end
        prevNonCVIMed=currMed;
        prevNonCVIClass=currClass;
        prevNonCVITime=newTime;
    end
end
%%
%finalize last patient
for i=1:numCVIs
    %check if not first interval
    if numIntervals(i)~=0
        %get interval tree for this result code and patient
        cviMap=medications.CVI(cviNames{i});
        it=cviMap(currKey);
        %add all intervals to the tree                
        for j=1:(numIntervals(i)-1)                    
            interval.low=datenum(allIntervals{i}{j}{1});
            interval.high=datenum(dateshift(allIntervals{i}{j+1}{1},'start','second','previous'));
            it.Insert(interval,allIntervals{i}{j}{2});
        end
        %add final interval
        interval.low=datenum(allIntervals{i}{numIntervals(i)}{1});
        interval.high=EOT;
        it.Insert(interval,allIntervals{i}{numIntervals(i)}{2});
    end
end

%process last nonCVI interval
interval.low=datenum(prevNonCVITime);
interval.high=datenum(dateshift(prevNonCVITime,'start','second',86399));
it=medications.nonCVI(prevKey);
it.Insert(interval,currNonCVIs);
%%
%save
if nargin==2 && isfield(params,'savefile')
    save(params.savefile,'medications');
end
end
