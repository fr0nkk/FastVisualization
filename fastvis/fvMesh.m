function M = fvMesh(varargin)
%FVMESH
% fvMesh(tri,xyz,color,normals,materials,material_index,'Property',Value,...)

[parent,args,t] = internal.fvParse(varargin{:});
p = inputParser;
p.addOptional('tri',[]);
p.addOptional('xyz',[]);
p.addOptional('col',[]);
p.addOptional('norm',[]);
p.addOptional('mtl',[]);
p.addOptional('mtl_idx',[]);
p.addParameter('AutoCalcNormals',true);
p.KeepUnmatched = true;
p.parse(args{:});

tri = p.Results.tri;
col = p.Results.col;
xyz = p.Results.xyz;
mtl = p.Results.mtl;
mtl_idx = p.Results.mtl_idx;

if isempty(tri)
    wo = wobj('teapot.obj');
    tri = wo.faces.vertices;
    xyz = wo.vertices;
    if isempty(col)
        col = rescale(xyz(:,3));
    end
end

if size(tri,2) < 3
    error('faces must be made of at least 3 points')
end

if size(tri,2) > 3
    tri = trifan(tri);
    warning('faces were assumed to be convex and were converted to triangles');
end

tf = any(tri == 0,2);
if any(tf)
    tri = tri(~tf,:);
    warning('removed faces with index 0')
end

n = p.Results.norm;

M = internal.fvPrimitive(parent,'GL_TRIANGLES',xyz,col,n,tri,mtl,mtl_idx,'Name','fvMesh',p.Unmatched);

if isempty(n) && p.Results.AutoCalcNormals
    M.AutoCalcNormals;
end

end
