function [parent,args,temp] = fvParse(varargin)
    if nargin > 0
        parent = varargin{1};
        if isa(parent,'fvFigure')
            ax = parent;
            i = 2;
        elseif isa(parent,'internal.fvDrawable')
            ax = parent.fvfig;
            i = 2;
        else
            ax = gcfv;
            parent = ax;
            i = 1;
        end
    else
        ax = gcfv;
        parent = ax;
        i = 1;
    end
    args = varargin(i:end);
    if nargout >= 3
        temp = ax.PauseUpdates;
    end
end