function A = fvAxes(varargin)
%FVAXES view axes in fast vis

[parent,args,t] = internal.fvParse(varargin{:});
p = inputParser;
p.addOptional('pos',[0 0 0]);
p.addOptional('sz',100);
p.parse(args{:});

xyz = [0 0 0; 1 0 0 ; 0 0 0 ; 0 1 0 ; 0 0 0 ; 0 0 1];
col = [1 0 0 ; 1 0 0 ; 0 1 0 ; 0 1 0 ; 0 0 1; 0 0 1];

A = fvLine(parent,xyz,col);
A.primitive_type = 'GL_LINES';
A.ConstantSize = p.Results.sz;
A.clickable = 0;
A.model = MTrans3D(p.Results.pos);
if ~A.fvfig.isHold
    A.ZoomTo;
end

end

