function fvclear(fvfig)
if nargin < 1, fvfig = gcfv; end
%FVCLEAR Shortcut to the current fvFigure's clear function
fvfig.fvclear();
end
