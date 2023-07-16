classdef fvFigure < JChildParent
    
    properties(Transient,SetObservable)
        % BackgroundColor - Color of the fvFigure's background
        BackgroundColor = [0 0 0];

        % Light - Struct containing information about lighting
        % The struct must contain Position, Ambient, Diffuse, Specular
        Light = struct('Position',[0 0 1e5],'Ambient',[1 1 1],'Diffuse',[1 1 1],'Specular',[1 1 1]);

        % isHold - State of hold of the fvFigure
        isHold matlab.lang.OnOffSwitchState = false;

        % edl - Eye Dome Lighting normalized strength
        % set to 0 to deactivate
        edl = 0.1;

        % edlWithBackground - Use EDL to shade objects with background
        edlWithBackground logical = false

        % ColorOrder - Colormap for object's color when they have no color specified
        ColorOrder = lines(7);

        % Camera - fvCamera used for viewing the scene - see fvCamera
        Camera

        % Type - Type of axes, determining camera constraints
        % Can be auto, 2D, or 3D
        CameraConstraints = 'auto'; % auto, 2D or 3D

        % Model - Base transformation model of the fvFigure
        Model = eye(4);

        
        RightClickActive = 1;
    end

    properties(Transient)
        % Title - Title of the fvFigure
        Title

        % Size - Size of the canvas
        Size
    end

    properties(Hidden)
        ctrl internal.fvController
        lastFocus
        mtlCache internal.fvMaterialCache
        lastMousePress
        DepthRange = [0 1];
    end

    events
        MouseClicked
        MouseHover
        MouseMoved
        KeyTyped
    end

    properties(Access = protected)
        MouseEvents
        mousePressOrigin = nan(0,2);
        camStateOrigin = cell(0,1);
        pauseStack = 0
        camMouseListeners
        camListener
        cameraNeedsReset = 0
        popup
    end

    properties(Dependent,Access=protected)
        validCamConstraints
    end

    % %#ok<*INUSD>
    % %#ok<*ASGLU>
    % %#ok<*NASGU>
    
    methods
        function obj = fvFigure(camera,msaaSamples,canvas)
            if nargin < 1 || isempty(camera), camera = fvCamera; end
            if nargin < 2 || isempty(msaaSamples), msaaSamples = 4; end
            
            obj.Camera = camera;
            obj.ctrl = internal.fvController;
            if nargin < 3 || isempty(canvas)
                canvas = GLCanvas('GL4',0);
                parent = JFrame(mfilename);
                parent.add(canvas);
            end
            
            canvas.addChild(obj);
            obj.ctrl.setGLCanvas(obj.parent);
            obj.parent.Init(obj,msaaSamples);
            obj.mtlCache = internal.fvMaterialCache(obj);
            obj.MouseEvents = JMouseEvents(obj.parent);
            obj.camMouseListeners = [
                addlistener(obj.MouseEvents,'Pressed',@obj.MousePressedCallback)
                skippablelistener(obj.MouseEvents,'Dragged',@obj.MouseDraggedCallback)
                skippablelistener(obj.MouseEvents,'Clicked',@obj.MouseClickedCallback)
                skippablelistener(obj.MouseEvents,'WheelMoved',@obj.MouseWheelMovedCallback)
                skippablelistener(obj.MouseEvents,'Moved',@obj.MouseMovedCallback)
                ];
            obj.parent.setCallback('KeyPressed',@(src,evt) notify(obj,'KeyTyped',javaevent(evt)));
            obj.parent.parent.setCallback('FocusGained',@obj.FocusGainedCallback);
            obj.FocusGainedCallback;
            internal.fvInstances('add',obj);

            obj.popup = internal.fvPopup;
            
        end

        function id = NextColorId(obj)
            id = numel(obj.child)*obj.isHold + 1;
        end

        function set.Camera(obj,fvcam)
            if ~isa(fvcam,'fvCamera')
                error('Camera must be a fvCamera');
            end
            delete(obj.camListener)
            obj.camListener = skippablelistener(fvcam,'Moved',@(src,evt) obj.Update);
            obj.Camera = fvcam;
            if ~isempty(obj.ctrl)
                obj.Camera.Resize(obj.ctrl.figSize);
                obj.Update;
            end
        end

        function MousePressedCallback(obj,src,evt)
            [xyz,info] = obj.ctrl.coord2closest(jevt2coords(evt.java,0),5);
            obj.Camera.PressAction(evt.java.getButton,xyz)
            obj.lastMousePress = info;
        end

        function MouseDraggedCallback(obj,src,evt)
            obj.Camera.DragAction(evt.data.buttonMask,evt.data.dxy);
        end

        function MouseClickedCallback(obj,src,evt)
            t = obj.UpdateOnCleanup;
            evt.data = obj.lastMousePress;
            notify(obj,'MouseClicked',evt);
            if isempty(obj.lastMousePress), return, end
            o = obj.lastMousePress.object;
            evt.data.xyz_local = mapply(evt.data.xyz,o.full_model,1);
            if obj.RightClickActive && evt.java.isPopupTrigger
                obj.popup.show(evt)
            end
            if ~isempty(o.CallbackFcn)
                o.CallbackFcn(obj,evt);
            end
        end

        function MouseWheelMovedCallback(obj,src,evt)
            p = obj.ctrl.coord2closest(jevt2coords(evt.java,0),5);
            obj.Camera.ZoomAction(evt.java.getUnitsToScroll,p);
        end

        function MouseMovedCallback(obj,src,evt)
            if ~event.hasListener(obj,'MouseHover') && ~event.hasListener(obj,'MouseMoved'), return, end
            t = obj.UpdateOnCleanup;

            notify(obj,'MouseMoved',evt);
            
            [~,info] = obj.ctrl.coord2closest(jevt2coords(evt,0),5);
            if ~isempty(info)
                evt.data = info;
                notify(obj,'MouseHover',evt);
            end
        end

        function FocusGainedCallback(obj,src,evt)
            obj.lastFocus = datetime('now');
        end

        function Update(obj)
            if ~isvalid(obj) || ~isvalid(obj.parent) || obj.pauseStack > 0, return, end
            if obj.cameraNeedsReset
                obj.UpdateOnCleanup;
                obj.UpdateCameraConstraints;
                obj.ResetCamera;
                obj.cameraNeedsReset = 0;
            else
                obj.Camera.AdjustNearFar;
                obj.parent.Update;
            end
        end

        function temp = UpdateOnCleanup(obj)
            obj.pauseStack = obj.pauseStack + 1;
            temp = onCleanup(@obj.EndPauseUpdate);
        end

        function out = fvhold(obj,state)
            curState = obj.isHold;
            if nargin >= 2
                obj.isHold = state;
            end
            if nargout || nargin < 2
                out = curState;
            end
        end

        function varargout = hold(obj,varargin)
            [varargout{1:nargout}] = obj.fvhold(varargin{:});
        end

        function fvclear(obj)
            t = obj.UpdateOnCleanup;
            obj.Model = eye(4);
            cellfun(@delete,obj.child);
            obj.child = {};
            obj.fvhold(0);
            obj.BackgroundColor = [0 0 0];
        end

        function clear(obj)
            obj.fvclear;
        end

        function set.BackgroundColor(obj,col)
            if numel(col) > 3 || ~isnumeric(col)
                error('Background color must be numerical with a maximum of 3 values')
            end
            col = internal.var2gl(col(:)',3,1);
            obj.ctrl.clearColor = num2cell(col);
            obj.Update;
        end

        function set.edlWithBackground(obj,tf)
            tf = logical(tf(1));
            [gl,temp] = obj.getContext;
            obj.ctrl.screen.program.uniforms.edlWithBackground.Set(tf);
            obj.Update;
        end

        function addChild(obj,c)
            if ~obj.isHold
                obj.fvclear;
                obj.cameraNeedsReset = 1;
            end
            obj.addChild@JChildParent(c);
        end

        function ResetCameraZoom(obj)
            bboxes = cellfun(@(c) c.worldBBox,obj.child,'uni',0);
            bbox = fvBoundingBox.catbbox(bboxes);
            obj.Camera.ZoomBBox(bbox);
        end

        function UpdateCameraConstraints(obj)
            if strcmpi(obj.validCamConstraints,'2D')
                % 2d mode
                obj.Camera.RotationActive(2) = 0;
                obj.Camera.viewParams.R(1) = 0;
            else
                % 3d mode
                obj.Camera.RotationActive(2) = 1;
            end
        end

        function set.CameraConstraints(obj,t)
            obj.CameraConstraints = t;
            obj.UpdateCameraConstraints
        end

        function t = get.validCamConstraints(obj)
            t = obj.CameraConstraints;
            if strcmpi(t,'auto')
                d = max(cellfun(@ndims,obj.child));
                if isempty(d) || d >= 3
                    t = '3D';
                else
                    t = '2D';
                end
            end
        end

        function [img,depth] = Snapshot(obj)
            [img,depth] = obj.ctrl.Snapshot;
            if nargout == 0
                figure('Name','fvFigure Snapshot','NumberTitle','off');
                imshow(img);
                clear img depth
            end
        end

        function ResetCamera(obj)
            t = obj.UpdateOnCleanup;
            obj.Camera.viewParams.R = strcmpi(obj.validCamConstraints,'3D') .* [-45 0 -45];
            obj.ResetCameraZoom;
        end

        function set.Light(obj,s)
            obj.Light = s;
            obj.Update;
        end

        function set.edl(obj,value)
            obj.edl = value;
            obj.Update;
        end

        function set.ColorOrder(obj,cmap)
            obj.ColorOrder = cmap;
            temp = obj.UpdateOnCleanup;
            for i=1:numel(obj.child)
                C = obj.child{i};
                if isempty(C.Color)
                    C.UpdateColor;
                end
            end
        end

        function set.Model(obj,m)
            if ~isnumeric(m) || ~ismatrix(m) || ~all(size(m) == 4) || ~isfloat(m)
                error('model must be 4x4 single or double matrix')
            end
            obj.Model = double(m);
            obj.Update;
        end

        function m = full_model(obj)
            m = obj.Model;
        end

        function t = get.Title(obj)
            t = obj.parent.parent.title;
        end

        function set.Title(obj,t)
            obj.parent.parent.title = t;
        end

        function sz = get.Size(obj)
            sz = obj.parent.size;
        end

        function set.Size(obj,sz)
            t = obj.UpdateOnCleanup;
            obj.parent.size = sz;
            obj.parent.parent.java.pack;
            obj.Update;
        end

        function C = validateChilds(obj,desiredClass)
            C = obj.validateChilds@JChildParent;
            if nargin >= 2
                C = C(cellfun(@(c) isa(c,desiredClass),C));
            end
        end

        function fvclose(obj)
            obj.delete;
        end

        function close(obj)
            obj.fvclose;
        end

        function Focus(obj)
            obj.parent.parent.java.requestFocus;
        end

        function delete(obj)
            internal.fvInstances('rm',obj);
            jf = obj.parent.parent;
            if isvalid(jf) && isa(jf,'JFrame')
                delete(jf);
            end
        end
        
    end

    methods(Hidden)
        function [gl,temp] = getContext(obj)
            [gl,temp] = obj.parent.getContext;
        end

        function EndPauseUpdate(obj)
            obj.pauseStack = max(0,obj.pauseStack - 1);
            obj.Update;
        end

        function c = validCamera(obj)
            c = obj.Camera;
        end

        function r = validDepthRange(obj)
            r = obj.DepthRange;
        end

        function s = saveobj(obj)
            s = struct('a',1);
        end

    end

    methods(Static,Hidden)

        function o = loadobj(s)
            o = fvFigure;
        end
    end
end
