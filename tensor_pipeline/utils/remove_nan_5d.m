function tensor=remove_nan_5d(tensor)
    sizes = size(tensor);
    for a=1:sizes(1)
        for b=1:sizes(2)
            for c=1:sizes(3)
                for d=1:sizes(4)
                    for e=1:sizes(5)
                        if isnan(tensor(a,b,c,d,e))
                            tensor(a,b,c,d,e) = 0;
                        end
                    end
                end
            end
        end
    end
end
