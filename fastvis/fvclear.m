function fvclear(fv)
if nargin < 1, fv = gcfv; end
%FVCLEAR Shortcut to the current fvFigure or fvChild's clear function
fv.fvclear();
end
