classdef (Abstract) fvDrawable < internal.fvChild
%FVDRAWABLE base drawable class

    properties(SetObservable)
        model = eye(4)
        alpha = 1;
        visible = true;
        clickable = true;

        ConstantSize = false;
        CutoffDist = inf; % in world unit, when ConstantSize is set
        ConstantSizeIsNormal = false;
    end

    properties(Abstract,Hidden,SetAccess=protected)
        glProg glmu.Program
    end

    properties(Transient)
        CallbackFcn
        BoundingBox
    end

    methods(Abstract,Access=protected)
        bbox = GetBBox(obj) % bbox = [minXyz rangeXyz] (= [-0.5 -0.5 -0.5 1 1 1] for a centered unit cube)
        DrawFcn(obj,V,M);
    end
    
    methods
        function obj = fvDrawable(ax)
            obj@internal.fvChild(ax);
        end

        function set.model(obj,m)
            if ~isnumeric(m) || ~ismatrix(m) || ~all(size(m) == 4) || ~isfloat(m)
                error('model must be 4x4 single or double matrix')
            end
            obj.model = double(m);
            obj.Update;
        end

        function set.clickable(obj,v)
            obj.clickable = v;
            obj.Update;
        end

        function set.visible(obj,v)
            obj.visible = v;
            obj.Update;
        end

        function set.alpha(obj,v)
            obj.alpha = v;
            obj.Update;
        end

        function set.ConstantSize(obj,sz)
            obj.ConstantSize = sz;
            obj.Update;
        end

        function set.CutoffDist(obj,d)
            obj.CutoffDist = d;
            obj.Update;
        end

        function m = full_model(obj)
            m = obj.relative_model(obj.parent.full_model);
        end

        function m = relative_model(obj,m)
            if nargin < 1, m = eye(4); end
            m = obj.ModelFcn(m * obj.model);
            if ~obj.ConstantSize(1), return, end
            C = obj.fvfig.Camera;
            [~,m] = mdecompose(m); % discard rotation and scale
            p = mapply([0 0 0],m);
            d = min(sqrt(sum((C.getCamPos - p).^2)),obj.CutoffDist);
            s = mean(C.projParams.size);
            if obj.ConstantSizeIsNormal
                R = MRot3D(-C.viewParams.R,1);
            else
                R = eye(4);
            end
            c = obj.ConstantSize;
            if numel(c) == 2
                c(3) = 1;
            end
            m = m * R * MScale3D(d./s.*c);
        end

        function bbox = get.BoundingBox(obj)
            if isempty(obj.BoundingBox)
                obj.BoundingBox = obj.GetBBox;
            end
            bbox = obj.BoundingBox;
        end

        function [drawnPrims,j] = Draw(obj,gl,V,M,j,drawnPrims)
            if ~obj.visible, return, end
            j = j+1;
            obj.glProg.uniforms.drawid.Set(j);
            tf = obj.clickable;
            gl.glColorMaski(2,tf,tf,tf,tf);
            gl.glColorMaski(3,tf,tf,tf,tf);
            M = obj.relative_model(M);
            obj.DrawFcn(V,M);
            drawnPrims = [drawnPrims {obj}];

            C = obj.validateChilds('internal.fvDrawable');
            for i=1:numel(C)
                [drawnPrims,j] = C{i}.Draw(gl,V,M,j,drawnPrims);
            end
        end

        function InvalidateBBox(obj)
            obj.BoundingBox = [];
        end

    end

    methods(Access=protected)
        function m = ModelFcn(obj,m)
        end
    end
end

