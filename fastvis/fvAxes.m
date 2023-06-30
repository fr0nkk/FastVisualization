function A = fvAxes(varargin)
%FVAXES view axes in fast vis

[parent,args,t] = internal.fvParse(varargin{:});
p = inputParser;
p.addOptional('pos',[0 0 0]);
p.addOptional('sz',100);
p.KeepUnmatched = true;
p.parse(args{:});

xyz = [0 0 0; 1 0 0 ; 0 0 0 ; 0 1 0 ; 0 0 0 ; 0 0 1];
col = [1 0 0 ; 1 0 0 ; 0 1 0 ; 0 1 0 ; 0 0 1; 0 0 1];
ind = [1 2 nan 3 4 nan 5 6]';
sz = p.Results.sz;
mdl = MTrans3D(p.Results.pos);

A = fvLine(parent,xyz,col,ind,'Clickable',false,'ConstantSize',sz,'Model',mdl,p.Unmatched);

end
