function xyz = mapply(xyz,m,invflag)
if nargin < 3, invflag = 0; end

xyz(:,4) = 1;
if invflag
    xyz = xyz / m';
else
    xyz = xyz * m';
end
xyz = xyz(:,1:3) ./ xyz(:,4);

end

