classdef (Abstract) fvDrawable < internal.fvChild
%FVDRAWABLE base drawable class

    properties(SetObservable)
        Model = eye(4)
        Alpha = 1;
        Active = true;
        Visible = true;
        Clickable = true;

        Camera fvCamera

        ConstantSize = false;
        ConstantSizeCutoff = inf; % in world unit, when ConstantSize is set (does not work when camera is orthographic)
        ConstantSizeRot = 'Same'; % Same, None or Normal
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
        DrawFcn(obj,M);
    end

    methods(Abstract)
        d = ndims(obj);
    end
    
    methods
        function obj = fvDrawable(ax)
            obj@internal.fvChild(ax);
        end

        function c = get.Camera(obj)
            if isempty(obj.Camera)
                c = obj.fvfig.Camera;
            else
                c = obj.Camera;
            end
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

        function set.Active(obj,tf)
            obj.Active = tf;
            obj.Update;
        end

        function set.Visible(obj,tf)
            obj.Visible = tf;
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

        function set.ConstantSizeRot(obj,str)
            if ~ismember(lower(str),{'same','normal','none'})
                error('Invalid value: %s. - Must be ''same'', ''normal'' or ''none''',str)
            end
            obj.ConstantSizeRot = str;
            obj.Update;
        end

        function m = full_model(obj)
            m = obj.relative_model(obj.parent.full_model);
        end

        function m = relative_model(obj,m)
            if nargin < 2, m = eye(4); end
            m = m * obj.Model;
            if ~obj.ConstantSize(1), return, end
            C = obj.Camera;
            [mr,m] = mdecompose(m);
            p = mapply([0 0 0],m);

            switch lower(obj.ConstantSizeRot)
                case 'same'
                    R = mr;
                case 'normal'
                    R = MRot3D(-C.viewParams.R,1);
                case 'none'
                    R = eye(4);
            end
            sz = obj.ConstantSize;
            if numel(sz) == 2
                sz(3) = 1;
            end
            d = min(vecnorm(dot(C.getCamPos - p,C.getCamRay),2,2),obj.ConstantSizeCutoff);
            m = m * R * MScale3D(sz.*C.getScaleFactor(d));
        end

        function bbox = get.BoundingBox(obj)
            if isempty(obj.BoundingBox)
                obj.BoundingBox = obj.GetBBox;
            end
            bbox = obj.BoundingBox;
        end

        function [drawnPrims,j] = Draw(obj,gl,M,j,drawnPrims)
            if ~obj.Active, return, end
            
            M = obj.relative_model(M);

            if obj.Visible
                j = j+1;
                u = obj.glProg.uniforms;
                C = obj.Camera;
                u.drawid.Set(j);
                u.projection.Set(C.MProj);
                u.viewPos.Set(C.getCamPos);
                tf = obj.Clickable;
                gl.glColorMaski(2,tf,tf,tf,tf);
                gl.glColorMaski(3,tf,tf,tf,tf);
                obj.DrawFcn(M);
                drawnPrims = [drawnPrims {obj}];
            end

            C = obj.validateChilds('internal.fvDrawable');
            for i=1:numel(C)
                [drawnPrims,j] = C{i}.Draw(gl,M,j,drawnPrims);
            end
        end

        function InvalidateBBox(obj)
            obj.BoundingBox = [];
        end

    end

end

