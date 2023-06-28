classdef fvLine < internal.fvPrimitive
%FVLINE view lines in fast vis

    properties
        LineWidth
    end
    
    methods
        function obj = fvLine(varargin)
            [ax,args,t] = fvFigure.ParseInit(varargin{:});

            p = inputParser;
            p.addOptional('xyz',[]);
            p.addOptional('col',[]);
            p.addOptional('ind',[]);
            p.addOptional('width',1);
            p.parse(args{:});

            xyz = p.Results.xyz;
            col = p.Results.col;

            if isempty(xyz)
                Z = linspace(0,10*pi,200)';
                X = sin(Z);
                Y = cos(Z);
                xyz = [X Y Z./20];
                if isempty(col)
                    col = rescale(xyz(:,3));
                end
            end
            
            obj@internal.fvPrimitive(ax,'GL_LINE_STRIP',xyz,col,[],p.Results.ind);
            obj.LineWidth = p.Results.width;
        end

        function set.LineWidth(obj,w)
            obj.LineWidth = w;
            obj.Update;
        end
    end
    methods(Access=protected)
        
        function DrawFcn(obj,V,M)
            obj.glDrawable.gl.glLineWidth(obj.LineWidth);
            obj.DrawFcn@internal.fvPrimitive(V,M);
        end
        
    end
end

