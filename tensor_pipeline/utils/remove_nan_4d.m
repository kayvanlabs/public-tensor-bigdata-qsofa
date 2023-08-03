function [tensor, r, t]=remove_nan_4d(tensor)
    t = 0;
    r = 0;
    sizes = size(tensor);
    s_1 = sizes(1);
    s_2 = sizes(2);
    s_3 = sizes(3);
    s_4 = sizes(4);
    for a=1:s_1
        for b=1:s_2
            for c=1:s_3
                for d=1:s_4
                    t = t + 1;
                    if isnan(tensor(a,b,c,d)) || isinf(tensor(a,b,c,d))
                        tensor(a,b,c,d) = 0;
                        r = r + 1;
                    end
                end
            end
        end
    end
    disp(string(r) + "/" + string(t));
end
