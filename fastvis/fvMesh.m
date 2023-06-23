classdef fvMesh < fvPrimitive
    
    methods
        function obj = fvMesh(varargin)
            [ax,args,t] = fvFigure.ParseInit(varargin{:});

            p = inputParser;
            p.addOptional('tri',[]);
            p.addOptional('xyz',[]);
            p.addOptional('col',[]);gitu
            p.addOptional('norm',[]);
            p.addOptional('mtl',[]);
            p.addOptional('mtl_idx',[]);
            p.addParameter('AutoCalcNormals',true);
            p.parse(args{:});

            tri = p.Results.tri;
            col = p.Results.col;
            xyz = p.Results.xyz;
            mtl = p.Results.mtl;
            mtl_idx = p.Results.mtl_idx;

            if isempty(tri)
                s = wobj2struct('teapot.obj');
                tri = s.f.v;
                xyz = s.v;
                if isempty(col)
                    col = rescale(xyz(:,3));
                end
            end

            if width(tri) < 3
                error('faces must be made of at least 3 points')
            end

            if width(tri) > 3
                tri = trifan(tri);
                warning('faces were assumed to be convex and were converted to triangles');
            end

            n = p.Results.norm;
            if isempty(n) && p.Results.AutoCalcNormals
                T = triangulation(double(tri),double(xyz));
                n = T.vertexNormal;
            end

            obj@fvPrimitive(ax,'GL_TRIANGLES',xyz,col,n,tri,mtl,mtl_idx);
            % glObjectBase(parent,prim_type,coords,color,normals,prim_index,material,material_index)
        end
    end
end

