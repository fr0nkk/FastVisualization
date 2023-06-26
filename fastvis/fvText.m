classdef fvText < fvText3

    properties
        CutoffDist = inf
        FontSize = 14;
    end

    methods
        function obj = fvText(varargin)
            [parent,args,t] = fvFigure.ParseInit(varargin{:});
            obj = obj@fvText3(parent,args{:});
            obj.model_fcn = @obj.ModelFcn;
        end

        function set.CutoffDist(obj,v)
            obj.CutoffDist = v;
            obj.Update;
        end

        function set.FontSize(obj,sz)
            obj.FontSize = sz;
            obj.Update;
        end

        function m = ModelFcn(obj,m)
            C = obj.fvfig.Camera;
            p = mapply([0 0 0],m);
            d = min(sqrt(sum((C.getCamPos - p).^2)),obj.CutoffDist);
            s = mean(C.projParams.size);
            [~,MT] = mdecompose(m); % discard rotation and scale
            MS = MScale3D(obj.FontSize);
            m = MT * MS * MRot3D(-C.viewParams.R,1) * MScale3D(d./s);
        end
    end

end

