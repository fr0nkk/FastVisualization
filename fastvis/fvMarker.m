function M = fvMarker(varargin)
%FVMARKER view a marker in fast vis

[parent,args,t] = internal.fvParse(varargin{:});
p = inputParser;
p.addOptional('pos',[0 0 0]);
p.addOptional('sz',20);
p.KeepUnmatched = true;
p.parse(args{:});

xyz = [-1 0 0; 1 0 0 ; 0 -1 0 ; 0 1 0 ; 0 0 -1 ; 0 0 1]./2;
col = [1 1 0];
sz = p.Results.sz;
mdl = MTrans3D(p.Results.pos);

M = fvLine(parent,xyz,col,'LineStrip',false,'Clickable',false, ...
    'ConstantSize',sz,'Model',mdl,'ConstantSizeRot','none',p.Unmatched);

end
