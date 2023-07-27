classdef fvLine < internal.fvPrimitive
%FVLINE view lines in fast vis

    properties(Transient,SetObservable)
        % LineWidth - Width of the lines to display
        LineWidth = 1
    end

    properties(Dependent)
        % LineStrip - If set to true, the coordinates will make one
        % continuous line. Otherwise, lines are reset for each pair
        LineStrip
    end
    
    methods
        function obj = fvLine(varargin)
            [ax,args,t] = internal.fvParse(varargin{:});

            p = inputParser;
            p.addOptional('xyz',nan);
            p.addOptional('col',[]);
            p.addOptional('ind',[]);
            p.KeepUnmatched = true;
            p.parse(args{:});

            xyz = p.Results.xyz;
            col = p.Results.col;

            if isscalar(xyz) && isnan(xyz)
                Z = linspace(0,10*pi,200)';
                X = sin(Z);
                Y = cos(Z);
                xyz = [X Y Z./20];
                if isempty(col)
                    col = rescale(xyz(:,3));
                end
            end

            obj@internal.fvPrimitive(ax,'GL_LINE_STRIP',xyz,col,[],p.Results.ind,[],[],'Name','fvLine',p.Unmatched);
        end

        function set.LineWidth(obj,w)
            obj.LineWidth = w;
            obj.Update;
        end

        function set.LineStrip(obj,tf)
            tf = logical(tf);
            if tf(1)
                prim = 'GL_LINE_STRIP';
            else
                prim = 'GL_LINES';
            end
            obj.PrimitiveType = prim;
        end

        function tf = get.LineStrip(obj)
            tf = strcmp(obj.PrimitiveType,'GL_LINE_STRIP');
        end
    end
    methods(Access=protected)
        
        function DrawFcn(obj,varargin)
            obj.glDrawable.gl.glLineWidth(obj.LineWidth);
            obj.DrawFcn@internal.fvPrimitive(varargin{:});
        end
        
    end
end

