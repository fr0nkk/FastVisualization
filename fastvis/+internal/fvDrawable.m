classdef (Abstract) fvDrawable < internal.fvChild
%FVDRAWABLE base drawable class

    properties(Transient,SetObservable)
        % Model - Transformation matrix (4x4) to apply to the primitive
        Model = eye(4)

        % Alpha - Transparency of the primitive, from 0 to 1
        Alpha = 1;

        % Visible - Enable or disable only the primitive for drawing
        Visible logical = true;

        % Active - Enable or disable the primitive AND its children for drawing
        Active logical = true;

        % Clickable - Enable or disable the ability to click the primitive
        Clickable logical = true;

        % Camera  - Camera to use for rendering
        % If not set, it defaults to the parent's camera
        Camera

        % ConstantSize - Render the primitive to have always the same final size
        % If not equal to zero, the primitive is rendered so 1 unit the
        % primitive is [ConstantSize] pixels on the screen
        ConstantSize = 0;

        % ConstantSizeCutoff - Max distance before reducing the primitive size
        % When ConstantSize is not 0, after this distance, the primitive
        % will start to shrink so it does not take the whole scene
        % (Does not work when camera projection is set to Orthographic)
        ConstantSizeCutoff = inf;

        % ConstantSizeRot - Rotation modification to apply when ConstantSize is set
        % Same: Keep the primitive's rotation
        % Normal: Make the primitive normal to the camera's Z axis
        % None: Remove the primitive's rotation
        ConstantSizeRot char = 'Same';

        % DepthRange - DepthRange to use for drawing
        % To draw a primitive always on top, use [0 0.1]
        % To draw a primitive always behind, use [0.9 1]
        DepthRange

        % CallbackFcn - function_handle to call when the primitive is clicked
        % Event contains the data property which contains the clicked
        % index, material and world coordinate
        CallbackFcn function_handle

        Name = 'fvDrawable';
    end

    properties(SetAccess = protected)
        % BoundingBox - Bounding box of this primitive
        BoundingBox
    end

    methods(Abstract,Access=protected)
        bbox = GetBBox(obj) % bbox = [minXyz rangeXyz] (= [-0.5 -0.5 -0.5 1 1 1] for a centered unit cube)
        DrawFcn(obj,M,j);
    end

    methods(Abstract)
        d = ndims(obj);
    end
    
    methods

        function c = validCamera(obj)
            if isempty(obj.Camera)
                c = obj.parent.validCamera;
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

        function set.DepthRange(obj,r)
            if ~isempty(r) && (numel(r) ~= 2 || any(r > 1) || any(r < 0))
                error('DepthRange must be composed of two elements from 0 to 1')
            end
            obj.DepthRange = r;
            obj.Update;
        end

        function r = validDepthRange(obj)
            if isempty(obj.DepthRange)
                r = obj.parent.validDepthRange;
            else
                r = obj.DepthRange;
            end
        end

        function m = full_model(obj)
            m = obj.relative_model(obj.parent.full_model);
        end

        function m = relative_model(obj,m)
            if nargin < 2, m = eye(4); end
            m = m * obj.Model;
            if ~obj.ConstantSize(1), return, end
            C = obj.validCamera;
            [mr,m] = mdecompose(m);
            p = mapply([0 0 0],m);

            switch lower(obj.ConstantSizeRot)
                case 'same'
                    R = mr;
                case 'normal'
                    R = MRot3D(-C.Rotation,1);
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

        function obj = Translate(obj,xyz)
            obj.Model =  MTrans3D(xyz) * obj.Model;
        end

        function obj = Rotate(obj,xyz,degFlag,order)
            if nargin < 3, degFlag = 0; end
            if nargin < 4, order = [3 2 1]; end
            obj.Model =  MRot3D(xyz,degFlag,order) * obj.Model;
        end

        function obj = Scale(obj,xyz)
            obj.Model =  MScale3D(xyz) * obj.Model;
        end

        function obj = ResetModel(obj)
            obj.Model = eye(4);
        end
    end

    methods(Access = {?internal.fvController,?internal.fvDrawable})

        function [drawnPrims,j] = Draw(obj,gl,M,j,drawnPrims)
            if ~obj.Active, return, end
            
            M = obj.relative_model(M);

            if obj.Visible
                j = j+1;
                tf = obj.Clickable && obj.validCamera == obj.fvfig.Camera;
                gl.glColorMaski(2,tf,tf,tf,tf);
                gl.glColorMaski(3,tf,tf,tf,tf);
                r = obj.validDepthRange;
                gl.glDepthRange(r(1),r(2));
                obj.DrawFcn(M,j);
                drawnPrims = [drawnPrims {obj}];
            end

            C = obj.validateChilds();
            for i=1:numel(C)
                [drawnPrims,j] = C{i}.Draw(gl,M,j,drawnPrims);
            end
        end

        function InvalidateBBox(obj)
            obj.BoundingBox = [];
        end

    end

end

