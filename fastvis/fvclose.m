function fvclose(arg)
%FVCLOSE Close the current fvFigure or all

if nargin < 1
    arg = internal.fvInstances('latest');
end

if isa(arg,'fvFigure')
    % ok
elseif ischar(arg) && strcmp(arg,'all')
    arg = internal.fvInstances;
else
    error('invalid argument')
end

delete(arg)

end
