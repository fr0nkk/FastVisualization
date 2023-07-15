function A = fvAxes(varargin)
%FVAXES view axes in fast vis

[parent,args,t] = internal.fvParse(varargin{:});
p = inputParser;
p.addOptional('pos',[0 0 0]);
p.KeepUnmatched = true;
p.parse(args{:});

xyz = [0 0 0; 1 0 0 ; 0 0 0 ; 0 1 0 ; 0 0 0 ; 0 0 1];
col = [1 0 0 ; 1 0 0 ; 0 1 0 ; 0 1 0 ; 0 0 1; 0 0 1];
ind = [1 2 nan 3 4 nan 5 6]';
mdl = MTrans3D(p.Results.pos);

A = fvLine(parent,xyz,col,ind,'Clickable',false,'Model',mdl,'Name','fvAxes');
A.ConstantSize = 100;
set(A,p.Unmatched);

end
