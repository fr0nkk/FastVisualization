classdef fvText2D < fvText

    properties
        maxDist = inf
    end

    methods
        function obj = fvText2D(varargin)
            [ax,args,t] = fvFigure.ParseInit(varargin{:});
            obj = obj@fvText(ax,args{:});
            if numel(args) < 3
                obj.sz = 25;
            end
            obj.model_fcn = @obj.ModelFcn;
        end

        function set.maxDist(obj,v)
            obj.maxDist = v;
            obj.Update;
        end

        function m = ModelFcn(obj,m)
            C = obj.fvfig.Camera;
            p = mapply([0 0 0],m);
            d = min(sqrt(sum((C.getCamPos - p).^2)),obj.maxDist);
            s = mean(C.projParams.size);
            m = m * MRot3D(-C.viewParams.R,1) * MScale3D(d./s);
        end
    end

end

