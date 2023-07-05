function ax = fvInstances(action,ax)
    if nargin < 1, action = 'all'; end
    persistent p
    if isempty(p)
        p = fvFigure.empty;
    end
    switch action
        case 'add'
            p(end+1) = ax;
        case 'rm'
            p(p==ax) = [];
        case 'latest'
            [~,i] = max([p.lastFocus]);
            ax = p(i);
        case 'all'
            ax = p;
        otherwise
            error('invalid action')
    end
    if isempty(p)
        munlock;
    else
        mlock;
    end
end