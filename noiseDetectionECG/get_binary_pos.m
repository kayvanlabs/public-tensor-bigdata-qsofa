function pos = get_binary_pos(v, type)

    if isempty(v)
        pos = [];
        return
    end
    if size(v,1) > size(v,2)
        v = v';
    end

    d = [true; diff(v(:)) ~= 0];
    k = find([d', true]);
    
    i1 = k(1:end-1);
    i2 = k(2:end)-1;
    vals = v(i1);
    
    val_pos = [vals' i1' i2'];
    
    if nargin < 2
        type = -1;
    end
    
    if type == -1
        % return all pos
        pos = val_pos;
    else
        pos = val_pos(val_pos(:,1) == type,2:3);
    end
    

end