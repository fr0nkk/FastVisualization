function xyz = mapply(xyz,m,fwdFlag)

if nargin < 3, fwdFlag = 1; end

xyz(:,4) = 1;
% to avoid needing to transpose xyz twice, (B*A')' == A*B'
if fwdFlag
    xyz = xyz * m';
else
    xyz = xyz / m';
end
xyz = xyz(:,1:3) ./ xyz(:,4);

end

