% input: row vector a, positive real number amp
% output: row vector b such that 
% (max(a-b)-min(a-b))/2 is at most amp
% and the l1 norm
% abs(b(1)-b(2))+abs(2*b(2)-b(1)-b(3))+abs(2*b(3)-b(2)-b(4))+...+
% +abs(2*b(n-1)-b(n)-b(n-2))+abs(b(n)-b(n-1)) is minimal,
% and a row vector c that keeps track of where b bends
% (value 1 means bend up, value -1 means bend down)
function[b,c]=taut_string(a,amp)
[m,n]=size(a);
lambda= 2*amp;
b=zeros(1,n);
c=zeros(1,n);
maxi=1;
mini=1;
for i=2:n,
    if a(i)>a(mini)
        mini=i;
        if a(i)>a(maxi)+lambda
            i=maxi;
            c(i)=-1;
            for j=1:i
                b(j)=a(maxi)+lambda;
            end
            break
        end
    elseif a(i)<a(maxi)
        maxi=i;
        if a(mini)>a(i)+lambda
            i=mini;
            c(i)=1;
            for j=1:i
                b(j)=a(mini);
            end
            break
        end
    end
end
if i<n-1
    maxslope=a(i+1)+lambda-b(i);
    minslope=a(i+1)-b(i);
    maxj=i+1;
    minj=i+1;
    j=i+2;
    while j<=n
        newmaxslope=(a(j)+lambda-b(i))/(j-i);
        newminslope=(a(j)-b(i))/(j-i);
        if newmaxslope<maxslope
            maxslope=newmaxslope;
            maxj=j;
            if maxslope<minslope
                for k=i+1:minj
                    b(k)=(b(i)*(minj-k)+a(minj)*(k-i))/(minj-i);
                end
                i=minj;
                c(i)=1;
                minj=i+1;
                maxj=i+1;
                maxslope=a(i+1)+lambda-b(i);
                minslope=a(i+1)-b(i);
                j=i+1;
            end
        end
        if j>i+1 & newminslope>minslope
            minslope=newminslope;
            minj=j;
            if minslope>maxslope
                for k=i+1:maxj
                    b(k)=(b(i)*(maxj-k)+(a(maxj)+lambda)*(k-i))/(maxj-i);
                end
                i=maxj;
                c(i)=-1;
                minj=i+1;
                maxj=i+1;
                maxslope=a(i+1)+lambda-b(i);
                minslope=a(i+1)-b(i);
                j=i+1;
            end
        end
        j=j+1;
    if j==n+1
        if maxslope <0
            for k=i+1:maxj
                b(k)=(b(i)*(maxj-k)+(a(maxj)+lambda)*(k-i))/(maxj-i);
            end
            i=maxj;
            c(i)=-1;
            if maxj<n
                minj=i+1;
                maxj=i+1;
                maxslope=a(i+1)+lambda-b(i);
                minslope=a(i+1)-b(i);
            j=i+1;
            end
        elseif minslope>0
            for k=i+1:minj
                b(k)=(b(i)*(minj-k)+a(minj)*(k-i))/(minj-i);
            end
            i=minj;
            c(i)=1;
            if minj<n
                minj=i+1;
                maxj=i+1;
                maxslope=a(i+1)+lambda-b(i);
                minslope=a(i+1)-b(i);
                j=i+1;
            end
        else
            for k=i+1:n
               b(k)=b(i);
            end
            j=n+1;
        end
    end
    end
end

% Final adjustment: vertical shift
if (is_constant(b) && b(1) == 0)
    % Case: Taut-String is constant (Happens when 'amp' too large)
    db = (min(a+amp) + max(a-amp)) / 2;
    b = b + db;
else
    % Case: Taut-String has inflections
    b = b - amp;
end

end
