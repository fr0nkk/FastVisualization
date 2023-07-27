function fvfig = gcfv
%GCFV Get the current fvFigure
% A new one is created if none exist

fvfig = internal.fvInstances('latest');

if isempty(fvfig)
    fvfig = fvFigure;
end

end
