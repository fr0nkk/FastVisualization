function fvfig = gcfv
%GCFV Get the current fvFigure

fvfig = internal.fvInstances('latest');

if isempty(fvfig)
    fvfig = fvFigure;
end

end

