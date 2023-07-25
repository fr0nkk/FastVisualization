function M = fvSurf(varargin)
%FVSURF

[parent,args,t] = internal.fvParse(varargin{:});
p = inputParser;
p.addOptional('Z',[]);
p.addOptional('col',[]);
p.addParameter('AutoCalcNormals',true);
p.KeepUnmatched = true;
p.parse(args{:});

Z = p.Results.Z;
col = p.Results.col;

if isempty(Z)
    Z = peaks(200).*16;
    if isempty(col)
        col = rescale(Z);
    end
end

[X,Y] = ndgrid(1:height(Z),1:width(Z));

xyz = [X(:) Y(:) double(Z(:))];
if ~isempty(col)
    col = reshape(col,height(xyz),[]);
end

tri = delaunay(xyz(:,1:2));

sLight = struct('Offset',[0 0 0],'Ambient',[0.5 0.5 0.5],'Diffuse',[0.5 0.5 0.5],'Specular',[0 0 0]);
M = fvMesh(parent,tri,xyz,col,'Name','fvSurf','AutoCalcNormals',p.Results.AutoCalcNormals,'Light',sLight,p.Unmatched);


end
