classdef (Abstract) fvDrawable < internal.fvChild
%FVDRAWABLE base drawable class

    properties(Transient,SetObservable)
        % Model - Transformation matrix (4x4) to apply to the primitive
        Model (4,4) double {mustBeReal,mustBeFinite}

        % Translation
        Translation (1,3) double {mustBeReal,mustBeFinite}

        % Rotation - degrees
        Rotation (1,3) double {mustBeReal,mustBeFinite}

        % Scale
        Scaling (1,3) double {mustBeReal,mustBeFinite}

        % Alpha - Transparency of the primitive, from 0 to 1
        Alpha (1,1) double {mustBeInRange(Alpha,0,1)} = 1;

        % Visible - Enable or disable only the primitive for drawing
        Visible (1,1) logical = true;

        % Active - Enable or disable the primitive AND its children for drawing
        Active (1,1) logical = true;

        % Clickable - Enable or disable the ability to click the primitive
        Clickable (1,1) logical = true;

        % LineWidth - Width of the lines to display
        % Applies when the rendered object is a line
        LineWidth (1,1) double {mustBeFinite,mustBeNonnegative} = 1

        % Camera  - Camera to use for rendering
        % If not set, it defaults to the parent's camera
        % Setting a Camera for a drawable makes it unclickable
        Camera fvCamera {mustBeScalarOrEmpty}

        % ConstantSize - Render the primitive to have always the same final size
        % If not equal to zero, the primitive is rendered so 1 unit of the
        % primitive is [ConstantSize] pixels on the screen
        ConstantSize (1,1) double {mustBeFinite,mustBeNonnegative} = 0;

        % ConstantSizeCutoff - Max distance before reducing the primitive size
        % When ConstantSize is not 0, after this distance, the primitive
        % will start to shrink so it does not take the whole scene
        % (Does not work when camera projection is set to Orthographic)
        ConstantSizeCutoff (1,1) double {mustBeNonnegative} = inf;

        % ConstantSizeRot - Rotation modification to apply when ConstantSize is set
        % Same: Keep the primitive's rotation
        % Normal: Align the primitive's Z axis with the camera's Z axis
        % None: Remove the primitive's rotation
        ConstantSizeRot char {mustBeMember(ConstantSizeRot,{'Same','Normal','None'})} = 'Same';

        % DepthRange - DepthRange to use for drawing
        % To draw a primitive always on top, use [0 0.1]
        % To draw a primitive always behind, use [0.9 1]
        % If not set, it defaults to the parent's DepthRange
        DepthRange (1,2) double {mustBeReal} = [nan nan];

        % DepthOffset - Offset to depth
        % The value is scaled to the smallest change to avoid Z fighting
        % Useful for drawing a primitive on top of another when they have
        % the same depth.
        DepthOffset (1,1) double {mustBeInteger} = 0;

        % FillPolygons - Flag to fill primitives
        % When disabled, triangle primitves will display as wireframe
        FillPolygons (1,1) logical = true;

        % Cull - Skip draw of back faces (1) or front faces (-1)
        Cull (1,1) double {mustBeInRange(Cull,-1,1),mustBeInteger} = 0;

        % CallbackFcn - function_handle to call when the primitive is clicked
        % Event contains the data property which contains the clicked
        % index, material and world coordinate
        CallbackFcn function_handle

        % Name - Name to display
        Name char = 'fvDrawable';

        % UserData - any user data attached to this object
        UserData

        % UserData - hide this object from the tree view
        UIHidden (1,1) logical = false;
    end

    properties(Transient,SetAccess = protected)
        % BoundingBox - Bounding box of this primitive
        BoundingBox
        iModel = eye(4);
        iRotation = [0 0 0];
        iTranslation = [0 0 0];
        iScaling = [1 1 1];
    end

    methods(Abstract,Access=protected)
        bbox = GetBBox(obj) % bbox = [minXyz rangeXyz] (= [-0.5 -0.5 -0.5 1 1 1] for a centered unit cube)
        DrawFcn(obj,M,j);
    end

    methods(Abstract)
        d = ndims(obj);
    end
    
    methods

        function obj = fvDrawable(varargin)
            obj@internal.fvChild(varargin{:});
            addlistener(obj,{'Visible','Active','Clickable','Alpha','LineWidth','ConstantSize', ...
                'ConstantSizeCutoff','ConstantSizeRot','Cull','FillPolygons','DepthOffset',...
                'Translation','Rotation','Scaling','Model','DepthRange'},'PostSet',@(~,~) obj.Update);
        end

        function set.Model(obj,m)
            obj.iModel = m;

            % Model = MR*MT*MS
            [MR,MT,MS] = mdecompose(m);
            obj.iRotation = [atan2(MR(3,2),MR(3,3)) atan2(-MR(3,1),norm(MR(3,2:3))) atan2(MR(2,1),MR(1,1))].*180./pi;
            obj.iTranslation = MT(1:3,4)';
            obj.iScaling = MS(1:5:12);
        end

        function m = get.Model(obj)
            m = obj.iModel;
        end

        function T = get.Translation(obj)
            T = obj.iTranslation;
        end

        function set.Translation(obj,T)
            obj.iTranslation = T;
            obj.UpdateInternalModel;
        end

        function R = get.Rotation(obj)
            R = obj.iRotation;
        end

        function set.Rotation(obj,R)
            obj.iRotation = R;
            obj.UpdateInternalModel;
        end

        function S = get.Scaling(obj)
            S = obj.iScaling;
        end

        function set.Scaling(obj,S)
            obj.iScaling = S;
            obj.UpdateInternalModel;
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

            switch obj.ConstantSizeRot
                case 'Same'
                    R = mr;
                case 'Normal'
                    R = MRot3D(-C.Rotation,1);
                case 'None'
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

        function bb = worldBBox(obj)
            bb = fvBoundingBox.coords2bbox(mapply(cubemesh,obj.full_model));
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

    methods(Hidden)
        function c = validCamera(obj)
            if isempty(obj.Camera)
                c = obj.parent.validCamera;
            else
                c = obj.Camera;
            end
        end

        function r = validDepthRange(obj)
            r = obj.DepthRange;
            tf = isnan(r);
            if any(tf)
                p = obj.parent.validDepthRange;
                r(tf) = p(tf);
            end
        end

        function ui(obj,parent)
            
            fvJLinkedValue(parent,mfilename);

            fvJLinkedValue(parent,'Name',obj,'Name');

            fvJLinkedValue(parent,'Alpha',obj,'Alpha','DragStep',0.01);

            fvJLinkedValue(parent,'Visible',obj,'Visible');

            fvJLinkedValue(parent,'Active',obj,'Active');

            fvJLinkedValue(parent,'Clickable',obj,'Clickable');

            fvJLinkedValue(parent,'Scaling',obj,{'Scaling','Model'},'DragStep',0.01);

            % Drag magnitude depending on distance from obj
            fcn = @(o) norm(o.validCamera.getCamPos - mapply((o.BoundingBox(1:3)+o.BoundingBox(4:6)./2),o.full_model))./1000;
            fvJLinkedValue(parent,'Translation',obj,{'Translation','Model'},'DragStep',fcn);

            fvJLinkedValue(parent,'Rotation',obj,{'Rotation','Model'},'DragStep',0.25);

            fvJLinkedValue(parent,'FillPolygons',obj,'FillPolygons');

            fvJLinkedValue(parent,'Cull',obj,'Cull','DragStep',0.05);

            fvJLinkedValue(parent,'LineWidth',obj,'LineWidth','DragStep',0.01);

            fvJLinkedValue(parent,'ConstSize',obj,'ConstantSize');
            fvJLinkedValue(parent,'ConstSzCut',obj,'ConstantSizeCutoff');
            fvJLinkedValue(parent,'ConstSzRot',obj,'ConstantSizeRot');



        end
    end

    methods(Access=private)
        function UpdateInternalModel(obj)
            obj.iModel = MRot3D(obj.iRotation,1) * MTrans3D(obj.iTranslation) * MScale3D(obj.iScaling);
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
                if obj.FillPolygons
                    polyMode = gl.GL_FILL;
                else
                    polyMode = gl.GL_LINE;
                end
                gl.glPolygonMode(gl.GL_FRONT_AND_BACK,polyMode);
                gl.glPolygonOffset(0,single(obj.DepthOffset));
                gl.glLineWidth(max(obj.LineWidth,0.001));
                if obj.Cull
                    gl.glEnable(gl.GL_CULL_FACE);
                    if obj.Cull > 0
                        gl.glFrontFace(gl.GL_CCW);
                    else
                        gl.glFrontFace(gl.GL_CW);
                    end
                else
                    gl.glDisable(gl.GL_CULL_FACE);
                end
                obj.DrawFcn(M,j);
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

