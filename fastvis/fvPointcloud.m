classdef fvPointcloud < fvPrimitive
%FVPOINTCLOUD view a pointcloud in fast vis

    properties(Transient)
        pointSizeType = 'pixel' % 'pixel' or 'unit'
        pointSize = 2
        minPointSize = 1; % in pixels, minimum size when in unit type
        pointShape = '.' % '.' 'o' or alpha matrix [m x n]
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

        function set.pointSizeType(obj,t)
            if ~ismember(t,{'pixel','unit'})
                error('pointSizeType must be ''pixel'' or ''unit''');
            end
            obj.pointSizeType = t;
            obj.Update;
        end

        function set.pointSize(obj,v)
            obj.pointSize = v;
            obj.Update;
        end

        function set.pointShape(obj,val)
            if isscalartext(val)
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
                if size(val,3) > 1
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
            ptsz = obj.pointSize;
            u = obj.glDrawable.program.uniforms;
            if strcmp(obj.pointSizeType,'pixel')
                ptsz = -ptsz;
            else
                u.minPointSize.Set(obj.minPointSize);
            end
            u.pointSize.Set(ptsz);
            
            obj.DrawFcn@fvPrimitive(V);
        end
    end
end
