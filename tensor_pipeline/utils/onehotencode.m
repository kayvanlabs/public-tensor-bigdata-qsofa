function B = onehotencode(A,varargin)
% ONEHOTENCODE Encode class labels into one-hot vectors.
%
%   B = ONEHOTENCODE(A,FEATDIM) expands a categorical array of labels into
%   a one-hot encoded vector representation. Input A is an n-dimensional
%   categorical array. FEATDIM is a positive integer that specifies the
%   dimension to expand to encode the labels. FEATDIM must specify a
%   singleton dimension of A, or be larger than n, where n is the number of
%   dimensions of A. Output B contains only ones and zeros, where each
%   entry in A is expanded along the dimension specified by FEATDIM into a
%   vector with as many elements as the number of elements of
%   categories(A). For a given entry of A, the corresponding
%   one-hot-encoded vector in B contains 1 in the position corresponding to
%   the index of that label in categories(A), and 0 everywhere else.
%   Undefined labels in A are encoded into a vector of all NaNs.
% 
%   B = ONEHOTENCODE(A) encodes a table of categorical labels. Input A is a
%   table with as many rows as the number of observations and a single
%   variable containing a scalar categorical value per row. Output B is a
%   table with as many rows as A and as many variables as the number of
%   categories represented in A. The variables are named with the
%   categories of A. For each observation, the value of the variable that
%   corresponds to the given categorical label is 1. All other variables
%   have value 0.
% 
%   B = ONEHOTENCODE(...,TYPENAME) specifies the data type of the encoded
%   labels. If input A is an array, output B is an array with data type
%   TYPENAME. If input A is a table, output B is a table where each entry
%   has data type TYPENAME. Valid values are floating point, signed and
%   unsigned integer, and logical types. If A contains undefined labels,
%   TYPENAME must be 'double' or 'single'. The default value is 'double'.
% 
%   B = ONEHOTENCODE(...,'ClassNames',CLASSES) also specifies the classes
%   to use for encoding. A can be a categorical, numeric, or string array
%   or a single-column table with a scalar categorical, numeric, or string
%   value per row. CLASSES must be a cell array of char vectors, a string
%   or numeric vector, or a 2-dimensional char array. You can use this
%   syntax to encode classes in a specific order or select a subset of
%   classes to encode. Labels with undefined value or a value not present
%   in CLASSES are encoded into a vector of all NaNs. If CLASSES is a
%   subset of the class labels in A, TYPENAME must be 'double' or 'single'.
% 
%   Example 1: One-hot encode a column categorical vector
% 
%       % Create a column categorical array
%       A = categorical([5;6;3]);
%       B = onehotencode(A,2);
% 
%   Example 2: One-hot encode a matrix of integers
% 
%       B = onehotencode(magic(3),3,'single','ClassNames',1:9);
% 
%   Example 3: One-hot encode a table with multiple columns
%       
%       A = table(categorical(["dog";"cat";"dog"]), categorical(["white";"black";"black"]));
%       B = table();
%       for i = 1:size(A,2)
%           B = [B, onehotencode(A(:,i))];
%       end
% 
%   See also ONEHOTDECODE.

%   Copyright 2020 The MathWorks, Inc.

narginchk(1,inf);
AisTable=isa(A,'table');

if AisTable
    % featdim is allowed if A is not a table.
    narginchk(1,4);
else
    % Compulsory input featdim has to be provided if A is not a table.
    narginchk(2,5);
end

try
    [A,featdim,typename,classes]=iParseAndValidateInputArguments(A,AisTable,varargin{:});
catch e
    throw( e );
end

integerLabelsA=mlearnlib.internal.data.LabelIntConverter.encodeLabelsToIntegers(A,classes);

if ~iIsTypenameFloatingPoint(typename) && any( integerLabelsA==0 )
    % We error in the case of missing or disregarded variables when the
    % target output type is not floating point because NaNs can't be of
    % integer and logical types.
    error(message('mlearnlib:onehot:ohEncodeUndefinedAndNotFloatingTypename'));
end

nClasses=length(classes);
B=mlearnlib.internal.data.OneHotConverter.encodeIntegersToVectors(integerLabelsA,featdim,...
    typename,nClasses);

if AisTable
    B=iMakeOutputTable(B,classes);
end
end

function [A,featdim,typename,classes]=iParseAndValidateInputArguments(A,AisTable,varargin)

% Create parser.
parser=inputParser();
defaultTypename='double';
defaultClasses=[];

parser.addOptional('typename',defaultTypename, @(x) any(iValidateTypename(x)));
parser.addParameter('ClassNames',defaultClasses, ...
    @(x)mlearnlib.internal.data.LabelIntConverter.assertValidClasses(x));

if ~AisTable
    parser.addRequired('featdim', ...
        @(x)validateattributes(x,"numeric", ["integer", "positive", "scalar"], ...
        'onehotencode', 'featdim'))
end

% Parse inputs.
parser.parse(varargin{:});
results=parser.Results;

if AisTable
    A=iValidateTableInputAndReturnArray(A);
    % If A is table, featdim is 2.
    featdim=2;
else
    featdim=results.featdim;
end

% Check if A is of valid types. If A is table, the underlying data have
% been already extracted and stored by reassigning A.
if ~(isa(A,'numeric') || isa(A,'categorical') || isa(A,'string'))
    error(message('mlearnlib:onehot:ohEncodeSupportedTypes'));
end

% Make sure typename is a supported value.
typename=iValidateTypename(results.typename);

iAssertFeatureDimensionIsSingleton(A,featdim);
[A,classes]=iAssertValidAandClasses(A,results.ClassNames);
end

function A= iValidateTableInputAndReturnArray(A)
% Validate that A has one column and each row contains a scalar value.
if width(A)~=1
    % Verify A is single-column.
    error(message('mlearnlib:onehot:ohEncodeSingleColTable'));
end
A=table2array(A);
if ~iscolumn(A)
    % Verify each row contained a scalar value.
    error(message('mlearnlib:onehot:ohEncodeColWithSingleLabels'));
end
end

function B=iMakeOutputTable(B,classes)
% Convert the names of classes to be string array to comply with table
% constructor.
if isnumeric(classes)
    BvarNames=string(classes);
    isClassesNan=isnan(classes);
    if any(isClassesNan,'all')
        BvarNames(isClassesNan) = "NaN";
    end
else
    BvarNames=classes;
end
B=num2cell(B, 1);
B=table(B{:}, 'VariableNames',BvarNames);
end

function iAssertFeatureDimensionIsSingleton(A,featdim)
% Verify that the dimension featdim is singleton.
if size(A,featdim)~=1
    error(message('mlearnlib:onehot:ohEncodeFeatureDimension', featdim));
end
end

function typename=iValidateTypename(typename)
supportedTypes = {'double', 'single', 'logical', ...
    'int8', 'int16', 'int32', 'int64', 'uint8', 'uint16', 'uint32', 'uint64'};

typename=validatestring(typename, supportedTypes, ...
    'onehotencode', 'typename');
end

function [A,classes]=iAssertValidAandClasses(A,classes)
% Define classes either as the one provided by user or as categories(a).
if ~isempty(classes)
    classes=mlearnlib.internal.data.LabelIntConverter.assertAndReturnValidClasses(classes);
elseif iscategorical(A)
    % No validation if classes is extracted as categories(A).
    classes=categories(A);
else
    error(message('mlearnlib:onehot:ohEncodeNotCategoricalClassnames'));
end

isAnumeric = isnumeric(A);
isClassesNumeric = isnumeric(classes);

% Ensure that A and classes are either both numeric or none of them is.
if isAnumeric && ~isClassesNumeric
    error(message('mlearnlib:onehot:ohEncodeANumericClassesNotNumeric'));
elseif ~isAnumeric && isClassesNumeric
    error(message('mlearnlib:onehot:ohEncodeANotNumericClassesNumeric'));
end

% Ensure classes is double if A and classes are both numeric but of
% different types.
if isAnumeric && isClassesNumeric && ~isa(A,'double') && ~isa(classes,'double') && ~isequal(class(A),class(classes))
    classes = double(classes);
end
end

function tf = iIsTypenameFloatingPoint(typename)
tf = ismember(typename, {'double', 'single'});
end