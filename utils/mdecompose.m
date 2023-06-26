function [MR,MT,MS] = mdecompose(M)

S = M'*M;
MS = eye(4);
i = [1 6 11];
MS(i) = sqrt(S(i));
MT = eye(4);
i = 13:15;
MT(i) = M(i);
MR = (MT*MS)\M;

end

