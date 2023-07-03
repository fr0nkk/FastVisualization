classdef (Abstract) fvDrawable < internal.fvChild
%FVDRAWABLE base drawable class

    properties(SetObservable)
        Model = eye(4)
        Alpha = 1;
        Visible = true;
        Clickable = true;

        Camera

        ConstantSize = false;
        ConstantSizeCutoff = inf; % in world unit, when ConstantSize is set
        ConstantSizeNormal = false;
        CallbackFcn
    end

    properties(Abstract,Access=protected)
        glProg glmu.Program
    end

    properties(SetAccess = protected)
        BoundingBox
    end

    methods(Abstract,Access=protected)
        bbox = GetBBox(obj) % bbox = [minXyz rangeXyz] (= [-0.5 -0.5 -0.5 1 1 1] for a centered unit cube)
        DrawFcn(obj,V,M);
    end
    
    methods
        function obj = fvDrawable(ax)
            obj@internal.fvChild(ax);
            obj.Camera = obj.fvfig.Camera;
        end

        function set.Model(obj,m)
            if ~isnumeric(m) || ~ismatrix(m) || ~all(size(m) == 4) || ~isfloat(m)
                error('model must be 4x4 single or double matrix')
            end
            obj.Model = double(m);
            obj.Update;
        end

        function set.Clickable(obj,v)
            obj.Clickable = v;
            obj.Update;
        end

        function set.Visible(obj,v)
            obj.Visible = v;
            obj.Update;
        end

        function set.Alpha(obj,v)
            obj.Alpha = v;
            obj.Update;
        end

        function set.ConstantSize(obj,sz)
            obj.ConstantSize = sz;
            obj.Update;
        end

        function set.ConstantSizeCutoff(obj,d)
            obj.ConstantSizeCutoff = d;
            obj.Update;
        end

        function m = full_model(obj)
            m = obj.relative_model(obj.parent.full_model);
        end

        function m = relative_model(obj,m)
            if nargin < 2, m = eye(4); end
            m = obj.ModelFcn(m * obj.Model);
            if ~obj.ConstantSize(1), return, end
            C = obj.Camera;
            [~,m] = mdecompose(m); % discard rotation and scale
            p = mapply([0 0 0],m);

            d = min(vecnorm(dot(C.getCamPos - p,C.getCamRay),2,2),obj.ConstantSizeCutoff);
            s = mean(C.projParams.size);
            if obj.ConstantSizeNormal
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

        function [drawnPrims,j] = Draw(obj,gl,M,j,drawnPrims)
            if ~obj.Visible, return, end
            j = j+1;
            u = obj.glProg.uniforms;
            u.drawid.Set(j);
            u.projection.Set(obj.Camera.MProj);
            u.viewPos.Set(obj.Camera.getCamPos);
            tf = obj.Clickable;
            gl.glColorMaski(2,tf,tf,tf,tf);
            gl.glColorMaski(3,tf,tf,tf,tf);
            M = obj.relative_model(M);
            obj.DrawFcn(M);
            drawnPrims = [drawnPrims {obj}];

            C = obj.validateChilds('internal.fvDrawable');
            for i=1:numel(C)
                [drawnPrims,j] = C{i}.Draw(gl,M,j,drawnPrims);
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

