classdef (Abstract) fvDrawable < fvChild
    %FVDRAWABLE base drawable class

    properties(SetObservable)
        model = eye(4)
        alpha = 1;
        visible = true;
        clickable = true;
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
        DrawFcn(obj,V);
    end
    
    methods
        function obj = fvDrawable(ax)
            obj@fvChild(ax);
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

        function m = full_model(obj)
            m = obj.ModelFcn(obj.parent.full_model * obj.model);
        end

        function bbox = get.BoundingBox(obj)
            if isempty(obj.BoundingBox)
                obj.BoundingBox = obj.GetBBox;
            end
            bbox = obj.BoundingBox;
        end

        function [drawnPrims,j] = Draw(obj,gl,V,j,drawnPrims)
            if ~obj.visible, return, end
            j = j+1;
            obj.glProg.uniforms.drawid.Set(j);
            tf = obj.clickable;
            gl.glColorMaski(2,tf,tf,tf,tf);
            gl.glColorMaski(3,tf,tf,tf,tf);
            obj.DrawFcn(V);
            drawnPrims = [drawnPrims {obj}];

            C = obj.validateChilds;
            for i=1:numel(C)
                [drawnPrims,j] = C{i}.Draw(gl,V,j,drawnPrims);
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

