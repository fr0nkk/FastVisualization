function x = var2gl(x,n,m)
    
    if isempty(x)
        x = 1;
    end
    
    if isinteger(x)
        x = single(x) ./ single(intmax(class(x)));
    end

    if ~isa(x,'single')
        x = single(x);
    end

    if size(x,2) == 1
        x = repmat(x,1,n);
    end

    if size(x,2) < n
        x(:,end+1:n) = 0;
    end

    if nargin >= 3 && size(x,1) < m
        x(end:m,:) = repmat(x(end,:),m-size(x,1)+1,1);
    end
    
end