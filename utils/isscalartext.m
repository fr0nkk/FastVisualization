function tf = isscalartext(x)

tf = ischar(x) || (isstring(x) && isscalar(x));

end

