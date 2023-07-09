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

    if width(x) == 1
        % gray tones
        x = repmat(x,1,n);
    end

    if width(x) < n
        x(:,end+1:n) = 0;
    end

    if nargin >= 3 && height(x) < m
        x(end:m,:) = repmat(x(end,:),m-height(x)+1,1);
    end
    
end