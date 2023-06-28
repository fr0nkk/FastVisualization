classdef(Abstract) fvConstantSize < handle

    properties
        ConstantSize = true;
        CutoffDist = inf; % in world unit
    end

    properties(Abstract,Hidden)
        ConstSizeIsNormal
    end

    methods(Abstract)
        Update
    end

    methods
        function obj = fvConstantSize(ConstantSize,CutoffDist)
            if nargin < 1, ConstantSize = 20; end
            if nargin < 2, CutoffDist = inf; end
            obj.ConstantSize = ConstantSize;
            obj.CutoffDist = CutoffDist;
        end

        function set.ConstantSize(obj,sz)
            obj.ConstantSize = sz;
            obj.Update;
        end

        function set.CutoffDist(obj,d)
            obj.CutoffDist = d;
            obj.Update;
        end
    end

    methods(Access=protected)
        function m = ConstSizeModelFcn(obj,m)
            if ~obj.ConstantSize(1), return, end
            C = obj.fvfig.Camera;
            [~,m] = mdecompose(m); % discard rotation and scale
            p = mapply([0 0 0],m);
            d = min(sqrt(sum((C.getCamPos - p).^2)),obj.CutoffDist);
            s = mean(C.projParams.size);
            m = m * MRot3D(-C.viewParams.R.*obj.ConstSizeIsNormal,1) * MScale3D(d./s.*obj.ConstantSize);
        end
    end
end

