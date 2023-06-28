function fvfig = gcfv
%GCFV Get the current fvFigure

fvfig = fvFigure.Instances('latest');

if isempty(fvfig)
    fvfig = fvFigure;
end

end

