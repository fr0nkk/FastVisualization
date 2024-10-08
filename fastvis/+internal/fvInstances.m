function ax = fvInstances(action,ax)
    if nargin < 1, action = 'all'; end
    persistent p
    if isempty(p)
        p = {};
    end
    switch action
        case 'add'
            if ~isa(ax,'fvFigure')
                error('must be a fvFigure')
            end
            p{end+1} = ax;
        case 'rm'
            tf = cellfun(@(c) isequal(ax,c),p);
            p(tf) = [];
        case 'latest'
            if isempty(p)
                ax = {};
            else
                lastFocus = cellfun(@(c) c.lastFocus,p);
                [~,i] = max(lastFocus);
                ax = p{i};
            end
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