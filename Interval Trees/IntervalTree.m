classdef IntervalTree < handle
%--------------------------------------------------------------------------
% Class:        IntervalTree < handle
%               
% Constructor:  T = IntervalTree();
%               
% Properties:   (none)
%               
% Methods:              T.Insert(interval,value);
%                       T.Delete(x);
%               key   = T.Sort();
%               bool  = T.ContainsKey(interval);
%               x     = T.Search(interval);
%               cell  = T.SearchAll(interval)
%               x     = T.Minimum();
%               y     = T.NextSmallest(x);
%               x     = T.Maximum();
%               y     = T.NextLargest(x);
%               x     = T.Select(i);
%               r     = T.Rank(x);
%               count = T.Count();
%               bool  = T.IsEmpty();
%                       T.Clear();
%               
% Description:  This class implements an interval tree with arbitrarily 
%               typed values. The tree is based on the red-black binary 
%               search tree written by Brian Moore and published on the 
%               MATLAB File Exchange: https://www.mathworks.com/_
%               matlabcentral/fileexchange/45123-data-structures
%
%               Each node in the tree contains an interval, a structure
%               representing an interval with lower and upper endpoints
%               stored as interval.low and interval.high, respectively. 
%               The key used for the tree is interval.low.
%               
% Author:       Jonathan Gryak
%               
% Date:         20190114
%--------------------------------------------------------------------------

    %
    % Private properties
    %
    properties (Access = private)
        k;                       % current number of elements
        root;                    % tree root pointer
        nil;                     % nil element pointer
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = IntervalTree()
            %----------------------- Constructor --------------------------
            % Syntax:       T = IntervalTree();
            %               
            % Description:  Creates an empty red-black binary search tree
            %--------------------------------------------------------------
            
            % Start with an empty tree
            this.Clear();
        end
        
        %
        % Create element from key-value pair and insert into tree
        %
        function Insert(this,interval,value)
            %------------------------- Insert -----------------------------
            % Syntax:       T.Insert(interval,value);
            %               
            % Inputs:       interval is a struct with fields low, high
            %               
            %               value is an arbitrary object
            %               
            % Description:  Inserts the given key-value pair into T
            %--------------------------------------------------------------
            
            % Create element from data
            if (nargin == 2)
                z = ITElement(interval);
            else
                z = ITElement(interval,value);
            end
            z.size = 1; % Initialize element size
            this.k = this.k + 1;
            
            % Insert element
            y = this.nil;
            x = this.root;
            while x ~= this.nil
                y = x;
                %update size and max
                x.size = x.size + 1;
                x.max=max([x.max z.max]);
                if (z.key < x.key)
                    x = x.left;
                else
                    x = x.right;
                end
            end
            z.p = y;
            if y == this.nil
                this.root = z;
            elseif (z.key < y.key)
                y.left = z;
            else
                y.right = z;
            end
            z.left = this.nil;
            z.right = this.nil;
            z.color = true;
            
            % Clean-up tree colors after insertion
            this.InsertFixup(z);
        end
        
        %
        % Delete element from tree
        %
        function Delete(this,x)
            %------------------------- Delete -----------------------------
            % Syntax:       T.Delete(x);
            %               
            % Inputs:       x is a node in T (i.e., an object of type
            %               ITElement) presumably extracted via a
            %               prior operation on T
            %               
            % Description:  Deletes the node x from T
            %--------------------------------------------------------------
            
            if ~isnan(x)
                % Update number of elements
                this.k = this.k - 1;
                
                % Delete element
                orig_color = x.color;
                if x.left == this.nil
                    z = x.right;
                    this.Transplant(x,x.right);
                    this.TraverseUpwardPath(x.p); %update size and max
                elseif x.right == this.nil
                    z = x.left;
                    this.Transplant(x,x.left);
                    this.TraverseUpwardPath(x.p); %update size and max
                else
                    y = IntervalTree.TreeMinimum(x.right);
                    this.TraverseUpwardPath(y.p); %update size and max
                    orig_color = y.color;
                    z = y.right;
                    if y.p == x
                        z.p = y;
                    else
                        this.Transplant(y,y.right);
                        y.right = x.right;
                        y.right.p = y;
                    end
                    this.Transplant(x,y);
                    y.left = x.left;
                    y.left.p = y;
                    y.color = x.color;
                    %update size and max
                    y.size = y.left.size + y.right.size + 1;
                    y.max=max([y.int.high y.left.max y.right.max]);
                end
                
                % Clean-up tree colors after deletion, if necessary
                if orig_color == false
                    this.DeleteFixup(z);
                end
            end
        end
        
        %
        % Return array of sorted keys
        %
        function keys = Sort(this)
            %-------------------------- Sort ------------------------------
            % Syntax:       keys = T.Sort();
            %               
            % Outputs:      keys is a column vector containing the sorted
            %               (ascending order) keys contained in T
            %               
            % Description:  Deletes the node x from T
            %--------------------------------------------------------------
            intervals(1).low=1;
            intervals(1).high=nan;
            keys = ITElement(intervals(1),intervals);
            IntervalTree.InOrderTreeWalk(this.root,keys);
            keys = keys.value;
        end
        
        %
        % Determine if tree contains element with given key
        %
        function bool = ContainsKey(this,interval)
            %---------------------- ContainsKey ---------------------------
            % Syntax:       bool = T.ContainsKeys(interval);
            %               
            % Inputs:       interval is an interval structure
            %               
            % Outputs:      bool = {true,false}
            %               
            % Description:  Determines if T contains an element with the
            %               given key
            %--------------------------------------------------------------
            
            bool = ~isnan(this.Search(interval));
        end
        
        %
        % Return the first interval that overlaps with the given interval
        %
        function x = Search(this,interval)
            %------------------------- Search -----------------------------
            % Syntax:       x = T.Search(interval);
            %               
            % Inputs:       interval is a struct with fields low, high
            %               
            % Outputs:      x is a node from T (i.e., an object of class
            %               ITElement) with the given key, if it exists in
            %               T, and NaN otherwise
            %               
            % Description:  Returns node from T with the given key
            %--------------------------------------------------------------
            
            x = this.root;          
            while x~= this.nil && ~this.Overlap(x.int,interval)
                if x.left ~=this.nil && x.left.max >= interval.low
                    x = x.left;
                else
                    x = x.right;
                end
            end
        end
        %
        % Return all intervals that overlap with the given interval
        %
        function x = SearchAll(this,interval)
            %------------------------- Search -----------------------------
            % Syntax:       x = T.SearchAll(interval);
            %               
            % Inputs:       interval is a struct with fields low, high
            %               
            % Outputs:      x is cell array of nodes from T (i.e., objects 
            %               of class ITElement) that overlap the given 
            %               interval,if they exist in T, and NaN otherwise
            %               
            % Description:  Return all intervals that overlap with the 
            %               given interval
            %--------------------------------------------------------------
            %call recursive search routine to find all overlapping
            %intervals
            x = IntervalTree.SearchAllHelper(this.root,interval);
        end
        %
        % Return pointer to element with smallest key
        %
        function x = Minimum(this)
            %------------------------- Minimum ----------------------------
            % Syntax:       x = T.Minimum();
            %               
            % Outputs:      x is the node from T (i.e., an object of class
            %               ITElement) with the smallest key
            %               
            % Description:  Returns node from T with the smallest key
            %--------------------------------------------------------------
            
            x = IntervalTree.TreeMinimum(this.root);
        end
        
        %
        % Return element with next smallest key (predecessor) of x
        %
        function y = NextSmallest(this,x)
            %---------------------- NextSmallest --------------------------
            % Syntax:       y = T.NextSmallest(x);
            %               
            % Inputs:       x is a node from T (i.e., an object of class
            %               ITElement)
            %               
            % Outputs:      y is the node from T (i.e., an object of class
            %               ITElement) with the next smallest key than x
            %               
            % Description:  Returns node from T with the next smallest key
            %               than the input node
            %--------------------------------------------------------------
            
            if ~isnan(x)
                if x.left ~= this.nil
                    y = IntervalTree.TreeMaximum(x.left);
                else
                    y = x.p;
                    while (y ~= this.nil) && (x == y.left)
                        x = y;
                        y = y.p;
                    end
                end
            else
                y = nan;
            end
        end
        
        %
        % Return pointer to element with largest key
        %
        function x = Maximum(this)
            %------------------------- Maximum ----------------------------
            % Syntax:       x = T.Maximum();
            %               
            % Outputs:      x is the node from T (i.e., an object of class
            %               ITElement) with the largest key
            %               
            % Description:  Returns node from T with the largest key
            %--------------------------------------------------------------
            
            x = IntervalTree.TreeMaximum(this.root);
        end
        
        %
        % Return element with next largest key (successor) of x
        %
        function y = NextLargest(this,x)
            %---------------------- NextLargest ---------------------------
            % Syntax:       y = T.NextLargest(x);
            %               
            % Inputs:       x is a node from T (i.e., an object of class
            %               ITElement)
            %               
            % Outputs:      y is the node from T (i.e., an object of class
            %               ITElement) with the next largest key than x
            %               
            % Description:  Returns node from T with the next largest key
            %               than the input node
            %--------------------------------------------------------------
            
            if ~isnan(x)
                if ~isnan(x.right)
                    y = IntervalTree.TreeMinimum(x.right);
                else
                    y = x.p;
                    while (y~= this.nil) && (x == y.right)
                        x = y;
                        y = y.p;
                    end
                end
            else
                y = nan;
            end
        end
        
        %
        % Return pointer to element with ith smallest key
        %
        function x = Select(this,i)
            %-------------------------- Select ----------------------------
            % Syntax:       x = T.Select(i);
            %               
            % Inputs:       i is a positive integer
            %               
            % Outputs:      x is the node from T (i.e., an object of class
            %               ITElement) with ith smallest key
            %               
            % Description:  Returns node from T with the ith smallest key
            %--------------------------------------------------------------
            
            x = IntervalTree.TreeSelect(this.root,i);
        end
        
        %
        % Return the rank (sorted index) of given element in the tree
        %
        function r = Rank(this,x)
            %--------------------------- Rank -----------------------------
            % Syntax:       r = T.Rank(x);
            %               
            % Inputs:       x is the node from T (i.e., an object of class
            %               ITElement) with ith smallest key
            %               
            % Outputs:      r is the postivie integer such that x's key is
            %               the rth smallest in T
            %               
            % Description:  Returns the rank of node x in T
            %--------------------------------------------------------------
            
            r = x.left.size + 1;
            y = x;
            while (y ~= this.root)
                if (y == y.p.right)
                    r = r + y.p.left.size + 1;
                end
                y = y.p;
            end
        end
        
        %
        % Return number of elements in tree
        %
        function count = Count(this)
            %-------------------------- Count -----------------------------
            % Syntax:       count = T.Count();
            %               
            % Outputs:      count is the number of nodes in T
            %               
            % Description:  Returns number of elements in T
            %--------------------------------------------------------------
            
            count = this.k;
        end
        
        %
        % Check for empty tree
        %
        function bool = IsEmpty(this)
            %------------------------ IsEmpty -----------------------------
            % Syntax:       bool = T.IsEmpty();
            %               
            % Outputs:      bool = {true,false}
            %               
            % Description:  Determines if T is empty (i.e., contains zero
            %               elements)
            %--------------------------------------------------------------
            
            if this.k == 0
                bool = true;
            else
                bool = false;
            end
        end
        
        %
        % Clear the tree
        %
        function Clear(this)
            %------------------------- Clear ------------------------------
            % Syntax:       T.Clear();
            %               
            % Description:  Removes all elements from T
            %--------------------------------------------------------------
            
            this.k = 0;                     % reset length counter
            this.nil = ITElement(nan);     % reset nil pointer
            this.root = this.nil;           % reset root pointer
        end
    end
    
    %
    % Private methods
    %
    methods (Access = private)
        %
        % Replaces the subtree rooted at element u with the subtree
        % rooted at element v
        %
        function Transplant(this,u,v)
            if u.p == this.nil
                this.root = v;
            elseif u == u.p.left
                u.p.left = v;
            else
                u.p.right = v;
            end
            v.p = u.p;
        end
        
        %
        % Left rotate at element x
        %
        function LeftRotate(this,x)
            y = x.right;
            x.right = y.left;
            if y.left ~= this.nil
                y.left.p = x;
            end
            y.p = x.p;
            if x.p == this.nil
                this.root = y;
            elseif x == x.p.left
                x.p.left = y;
            else
                x.p.right = y;
            end
            y.left = x;
            x.p = y;
            %update size
            y.size = x.size;
            x.size = x.left.size + x.right.size + 1;
            %update max
            y.max=x.max;
            x.max=max([x.int.high x.left.max x.right.max]);
        end
        
        %
        % Right rotate at element y
        %
        function RightRotate(this,y)
            x = y.left;
            y.left = x.right;
            if x.right ~= this.nil
                x.right.p = y;
            end
            x.p = y.p;
            if y.p == this.nil
                this.root = x;
            elseif (y == y.p.right)
                y.p.right = x;
            else
                y.p.left = x;
            end
            x.right = y;
            y.p = x;
            %update size
            x.size = y.size;
            y.size = y.left.size + y.right.size + 1;
           %update max
            x.max=y.max;
            y.max=max([y.int.high y.left.max y.right.max]);
        end       
        %
        % Fix tree coloring after inserting element x
        %
        function InsertFixup(this,x)
            while x.p.color == true
                if x.p == x.p.p.left
                    y = x.p.p.right;
                    if y.color == true
                        x.p.color = false;
                        y.color = false;
                        x.p.p.color = true;
                        x = x.p.p;
                    else
                        if x == x.p.right
                            x = x.p;
                            this.LeftRotate(x);
                        end
                        x.p.color = false;
                        x.p.p.color = true;
                        this.RightRotate(x.p.p);
                    end
                else
                    y = x.p.p.left;
                    if y.color == true
                        x.p.color = false;
                        y.color = false;
                        x.p.p.color = true;
                        x = x.p.p;
                    else
                        if x == x.p.left
                            x = x.p;
                            this.RightRotate(x);
                        end
                        x.p.color = false;
                        x.p.p.color = true;
                        this.LeftRotate(x.p.p);
                    end
                end
            end
            this.root.color = false;
        end
        
        %
        % Fix tree coloring after deleting element x, which necessitates
        % calling this function with parameter z, as defined in Delete()
        %
        function DeleteFixup(this,z)
            while (z ~= this.root) && (z.color == false)
                if z == z.p.left
                    w = z.p.right;
                    if w.color == true
                        w.color = false;
                        z.p.color = true;
                        this.LeftRotate(z.p);
                        w = z.p.right;
                    end
                    if (w.left.color == false) && (w.right.color == false)
                        w.color = true;
                        z = z.p;
                    else
                        if w.right.color == false
                            w.left.color = false;
                            w.color = true;
                            this.RightRotate(w);
                            w = z.p.right;
                        end
                        w.color = z.p.color;
                        z.p.color = false;
                        w.right.color = false;
                        this.LeftRotate(z.p);
                        z = this.root;
                    end
                else
                    w = z.p.left;
                    if w.color == true
                        w.color = false;
                        z.p.color = true;
                        this.RightRotate(z.p);
                        w = z.p.left;
                    end
                    if (w.left.color == false) && (w.right.color == false)
                        w.color = true;
                        z = z.p;
                    else
                        if w.left.color == false
                            w.right.color = false;
                            w.color = true;
                            this.LeftRotate(w);
                            w = z.p.left;
                        end
                        w.color = z.p.color;
                        z.p.color = false;
                        w.left.color = false;
                        this.RightRotate(z.p);
                        z = this.root;
                    end
                end
            end
            z.color = false;
        end
        
        %
        % Traverse path from y towards the root, decrementing sizes along
        % the way
        %
        function TraverseUpwardPath(this,y)
            if ~isnan(y)
                %update size and max
                y.size = y.size - 1;
                y.max=max([y.int.high y.left.max y.right.max]);
                if (y ~= this.root)
                    this.TraverseUpwardPath(y.p);
                end
            end
        end
    end
    
    %
    % Private static methods
    %
    methods (Access = private, Static = true)
       %
        %Return all intervals that overlap with the given interval
        %
        function nodelist=SearchAllHelper(currnode,interval)
            %create empty cell array
            nodelist={};
            %if this node has an overlap, add it to the list
            if IntervalTree.Overlap(currnode.int,interval)
                nodelist{end+1}=currnode;
            end
            %if currnode has a left neighbor with a greater max than
            %interval.low, search the left branch
            if ~isnan(currnode.left) && currnode.left.max >= interval.low
                newnodelist=IntervalTree.SearchAllHelper(currnode.left,interval);
                nodelist = [nodelist newnodelist];
            end
            %if currnode has a right neighbor with max >=
            %interval.low and currnode's low is <= interval.high, search 
            %the right branch
            if ~isnan(currnode.right) && currnode.int.low <= interval.high...
                && currnode.right.max >= interval.low
                newnodelist=IntervalTree.SearchAllHelper(currnode.right,interval);
                nodelist = [nodelist newnodelist];
            end
        end       
        %
        % In-order tree walk from given element
        %
        function InOrderTreeWalk(x,keys)
            if ~isnan(x)
                IntervalTree.InOrderTreeWalk(x.left,keys);
                keys.value(keys.key) = x.int;
                keys.key = keys.key + 1;
                IntervalTree.InOrderTreeWalk(x.right,keys);
            end
        end
        
        %
        % Return pointer to minimum of subtree rooted at x
        %
        function x = TreeMinimum(x)
            if ~isnan(x)
                while ~isnan(x.left)
                    x = x.left;
                end
            end
        end
        
        %
        % Return pointer to maximum of subtree rooted at x
        %
        function x = TreeMaximum(x)
            if ~isnan(x)
                while ~isnan(x.right)
                    x = x.right;
                end
            end
        end
        
        %
        % Returns pointer to element with ith smallest key in the subtree
        % rooted at element x
        %
        function x = TreeSelect(x,i)
            if ~isnan(x)
                r = x.left.size + 1;
                if (i < r)
                    x = IntervalTree.TreeSelect(x.left,i);
                elseif (i > r)
                    x = IntervalTree.TreeSelect(x.right,i - r);
                end
            end
        end
        %determine if two intervals overlap
        function o=Overlap(interval1, interval2)
            if (interval1.high < interval2.low) || (interval2.high < interval1.low)
                o=0;
            else
                o=1;
            end
        end
    end
end
