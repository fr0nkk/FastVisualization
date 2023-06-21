function ax = gcfv

ax = fvFigure.Instances('latest');

if isempty(ax)
    ax = fvFigure;
end

end

