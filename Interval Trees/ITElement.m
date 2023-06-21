classdef ITElement < handle
%--------------------------------------------------------------------------
% Class:        IntervalTree < handle
%               
% Constructor:  I = ITElement(interval,value);
%               
% Properties:   (none)
%               
% Methods:              bool = I.isnan()
%               
% Description:  A class that implements pass by reference elements for 
%               instances of the IntervalTree class. The class is based on 
%               the red-black tree element class written by Brian Moore 
%               and published on the MATLAB File Exchange: 
%               https://www.mathworks.com/_
%               matlabcentral/fileexchange/45123-data-structures
%
%               Each element contains an interval, a structure
%               representing an interval with lower and upper endpoints
%               stored as interval.low and interval.high, respectively. 
%               The key property is set to interval.low. The max property
%               is the value of the maximum interval endpoint of any 
%               subtree.
%               
% Author:       Jonathan Gryak
%               
% Date:         20190114
%--------------------------------------------------------------------------

% A class that implements pass by reference elements with numeric keys for
% instances of the IntervalTree class
%
% NOTE: This class is used internally by the IntervalTree class
%

    %
    % Public properties
    %
	properties (Access = public)
		key;            % key, equal to the value of int.low
        left = nan      % left child
        right = nan;    % right child
        p = nan;        % parent
        color = false;  % color (true = red,false = black)
        size = 0;       % size of subtree rooted at this element
        value = [];     % miscellaneous data
        int;            %a structure representing the interval
        max=0;          %the maximum value of any interval in the subtree
                        %of this interval
   end
    
    %
    % Public methods
    %
	methods (Access = public)
        %
        % Constructor
        %
		function this = ITElement(interval,value)
 			%create empty interval if necessary
            if ~isstruct(interval)
                interval=struct;
                interval.low=nan;
                interval.high=nan;
            end
            %Initialize key
            this.key = interval.low;
            %Set Interval
            this.int=interval;
            % Set value data, if specified
            if (nargin == 2)
                this.value = value;
            end
            %set max
            this.max = interval.high;
        end
        
        %
        % Element is nan if its key is nan
        %
        function bool = isnan(this)
            bool = isnan(this.key);
        end
    end
end
