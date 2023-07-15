function M = fvMarker(varargin)
%FVMARKER view a marker in fast vis

[parent,args,t] = internal.fvParse(varargin{:});
p = inputParser;
p.addOptional('pos',[0 0 0]);
p.KeepUnmatched = true;
p.parse(args{:});

xyz = [-1 0 0; 1 0 0 ; 0 -1 0 ; 0 1 0 ; 0 0 -1 ; 0 0 1]./2;
col = [1 1 0];

mdl = MTrans3D(p.Results.pos);

M = fvLine(parent,xyz,col,'Name','fvMarker','LineStrip',false,'Clickable',false,'Model',mdl,'ConstantSizeRot','none');
M.ConstantSize = 20;
set(M,p.Unmatched);

end
