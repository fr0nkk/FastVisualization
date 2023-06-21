classdef fvMarker < fvLine

    properties
        pos = [0 0 0]
        sz = 1
    end

    methods
        function obj = fvMarker(varargin)
            [parent,args,t] = fvFigure.ParseInit(varargin{:});
            p = inputParser;
            p.addOptional('pos',[0 0 0]);
            p.addOptional('col',[1 1 0]);
            p.parse(args{:});

            pos = p.Results.pos;
            col = p.Results.col;

            xyz = [-1 0 0; 1 0 0 ; 0 -1 0 ; 0 1 0 ; 0 0 -1 ; 0 0 1];

            obj@fvLine(parent,xyz,col,[1 2 nan 3 4 nan 5 6]');
            obj.pos = pos;
            obj.clickable = 0;
            obj.model_fcn = @obj.ModelFcn;
        end

        function set.pos(obj,v)
            obj.pos = v;
            obj.Update;
        end

        function set.sz(obj,v)
            obj.sz = v;
            obj.Update;
        end

        function m = ModelFcn(obj,m)
            m = MTrans3D(obj.pos) * m * MScale3D(abs(obj.sz));
            if obj.sz > 0, return, end

            C = obj.gla.Camera;
            d = sqrt(sum((C.getCamPos - obj.pos).^2));
            s = mean(C.projParams.size);
            m = m * MScale3D(d./s) ;
        end
    end
end

