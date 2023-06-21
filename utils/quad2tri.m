function tri = quad2tri(quad,reverseFlag)
if nargin < 2, reverseFlag = 0; end

if isempty(quad) || width(quad) == 3, tri=quad; return, end

tri = reshape(quad(:,[1 2 3 1 3 4])',3,[])';

if reverseFlag
    tri = fliplr(tri);
end

end

