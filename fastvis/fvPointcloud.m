classdef fvPointcloud < fvPrimitive

    properties(Transient)
        minPointSize = 1;
        pointSize = -1 % negative: in pixels -- positive: in world units
        pointShape = '.' %% '.' 'o' or alpha matrix [m x n]
    end

    methods
        function obj = fvPointcloud(varargin)
            [ax,args,t] = fvFigure.ParseInit(varargin{:});

            p = inputParser;
            p.addOptional('xyz',[]);
            p.addOptional('col',[]);
            p.addOptional('ind',[]);
            p.parse(args{:});

            xyz = p.Results.xyz;
            col = p.Results.col;
            if isempty(xyz)
                [X,Y,Z] = peaks(200);
                xyz = [X(:) Y(:) Z(:)];
                if isempty(col)
                    col = rescale(xyz(:,3));
                end
            end

            obj@fvPrimitive(ax,'GL_POINTS',xyz,col);
        end

        function set.pointSize(obj,v)
            obj.pointSize = v;
            obj.Update;
        end

        function set.pointShape(obj,val)
            if ischar(val)
                switch val
                    case '.'
                        pointMask = 0;
                    case 'o'
                        pointMask = 1;
                    otherwise
                        error('invalid value: %s',val)
                end
            else
                [gl,temp] = obj.getContext;
                if isinteger(val)
                    val = val./intmax(class(val));
                end
                if size(val,3) ~= 1
                    val = mean(val,3);
                end
                tex = glmu.Texture(7,'GL_TEXTURE_2D',flipud(val),'GL_RED',1);
                obj.glDrawable.uni.pointMask_tex = tex;
                pointMask = 2;
            end
            obj.glDrawable.uni.pointMask = pointMask;
            obj.Update;
        end
    end
    
    methods(Access=protected)
        function DrawFcn(obj,V)
            obj.glDrawable.program.uniforms.pointSize.Set(obj.pointSize);
            obj.glDrawable.program.uniforms.minPointSize.Set(obj.minPointSize);
            obj.DrawFcn@fvPrimitive(V);
        end
    end
end
