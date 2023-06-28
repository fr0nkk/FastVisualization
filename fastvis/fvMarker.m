function M = fvMarker(varargin)
%FVMARKER view a marker in fast vis

[parent,args,t] = internal.fvParse(varargin{:});
p = inputParser;
p.addOptional('pos',[0 0 0]);
p.addOptional('sz',20);
p.parse(args{:});

xyz = [-1 0 0; 1 0 0 ; 0 -1 0 ; 0 1 0 ; 0 0 -1 ; 0 0 1]./2;
col = [1 1 0];

M = fvLine(parent,xyz,col);
M.primitive_type = 'GL_LINES';
M.ConstantSize = p.Results.sz;
M.clickable = 0;
M.model = MTrans3D(p.Results.pos);
if ~M.fvfig.isHold
    M.ZoomTo;
end

end