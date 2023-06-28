function fvclose(arg)
%FVCLOSE Close the current fvFigure or all

if nargin < 1
    arg = fvFigure.Instances('latest');
end

if isa(arg,'fvFigure')
    % ok
elseif ischar(arg) && strcmp(arg,'all')
    arg = fvFigure.Instances;
else
    error('invalid argument')
end

delete(arg)

end
