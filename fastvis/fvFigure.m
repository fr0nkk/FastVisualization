classdef fvFigure < JChildParent & matlab.mixin.SetGet
    
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
        EDL = 0.1;

        % edlWithBackground - Use EDL to shade objects with background
        EDLWithBackground logical = false

        % ColorOrder - Colormap for object's color when they have no color specified
        ColorOrder = lines(7);

        % Camera - fvCamera used for viewing the scene - see fvCamera
        Camera

        % Type - Type of axes, determining camera constraints
        % Can be auto, 2D, or 3D
        CameraConstraints = 'auto'; % auto, 2D or 3D

        % Model - Base scene model
        Model = eye(4);

        % PopupMenuActive - Display the menu on right click in fvFigure
        PopupMenuActive = true;

        % Title - Title of the fvFigure
        Title

        % Size - Size of the canvas
        Size
        
        % MSAA - Number of samples for multisample anti-aliasing
        MSAA = 4

        % DepthRange - Range of depth to use for depth writes
        % Values must be from 0 to 1
        % Used by childrens if they have no DepthRange set
        DepthRange = [0 1];
    end

    properties(Hidden)
        popup
        
        % for debug
        PauseUpdatesActive = true;
        ShowFramerate = false;
        FrametimeSmoothing = 0.5;
    end

    properties(Hidden,SetAccess=protected)
        ctrl internal.fvController
        lastFocus
        mtlCache internal.fvMaterialCache
        lastMousePress
    end

    events
        Resized
        MouseClicked
        MouseHover
        MouseMoved
        KeyTyped
    end

    properties(Access = protected)
        MouseEvents
        pauseStack = 0
        camMouseListeners
        camListener
        cameraNeedsReset = 0
        UpdateNeeded = true
        frametime = 1/60; % initial estimate
    end

    properties(Dependent,Access=protected)
        validCamConstraints
    end

    % suppress warning for onCleanup variables
    %#ok<*NASGU>
    %#ok<*ASGLU>
    
    methods
        function obj = fvFigure(varargin)
            p = inputParser;
            p.addOptional('canvas',[]);
            p.KeepUnmatched = true;
            p.parse(varargin{:});

            canvas = p.Results.canvas;
            obj.Camera = fvCamera;
            obj.ctrl = internal.fvController;
            if isempty(canvas)
                canvas = GLCanvas('GL4',0);
                parent = JFrame(mfilename);
                parent.add(canvas);
            end
            
            canvas.addChild(obj);
            obj.ctrl.setGLCanvas(obj.parent);
            obj.parent.Init(obj,obj.MSAA);
            obj.mtlCache = internal.fvMaterialCache(obj);
            obj.MouseEvents = JMouseEvents(obj.parent);
            obj.camMouseListeners = [
                skippablelistener(obj.MouseEvents,'Pressed',@obj.MousePressedCallback)
                skippablelistener(obj.MouseEvents,'Dragged',@obj.MouseDraggedCallback)
                skippablelistener(obj.MouseEvents,'Clicked',@obj.MouseClickedCallback)
                skippablelistener(obj.MouseEvents,'WheelMoved',@obj.MouseWheelMovedCallback)
                skippablelistener(obj.MouseEvents,'Moved',@obj.MouseMovedCallback)
                ];
            obj.parent.setCallback('KeyPressed',@(src,evt) notify(obj,'KeyTyped',javaevent(evt)));
            obj.parent.setCallback('FocusGained',@obj.FocusGainedCallback);
            obj.FocusGainedCallback;
            internal.fvInstances('add',obj);

            obj.popup = internal.fvPopup(obj);

            set(obj,p.Unmatched);
        end

        function id = NextColorId(obj)
            id = numel(obj.child)*obj.isHold + 1;
        end

        function set.Camera(obj,cam)
            if ~isa(cam,'fvCamera')
                error('Camera must be a fvCamera');
            end
            delete(obj.camListener)
            obj.camListener = skippablelistener(cam,'Moved',@(src,evt) obj.Update);
            obj.Camera = cam;
            if ~isempty(obj.ctrl)
                obj.ResizeCallback(obj.Size);
                obj.Update;
            end
        end

        function Update(obj)
            if ~isvalid(obj) || ~isvalid(obj.parent), return, end
            obj.UpdateNeeded = true;
            if obj.PauseUpdatesActive && obj.pauseStack > 0, return, end
            if obj.cameraNeedsReset
                obj.cameraNeedsReset = 0;
                t = obj.PauseUpdates;
                obj.UpdateCameraConstraints;
                obj.ResetCamera;
            else
                obj.Camera.AdjustNearFar;
                obj.parent.Update;
                obj.frametime = (obj.frametime * obj.FrametimeSmoothing) + (obj.ctrl.lastFrameTime * (1.0-obj.FrametimeSmoothing));
                if obj.ShowFramerate
                    fprintf('fvFigure framerate: %.2f\n',1./obj.frametime)
                end
                obj.UpdateNeeded = false;
            end
        end

        function temp = PauseUpdates(obj)
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
            t = obj.PauseUpdates;
            obj.Model = eye(4);
            cellfun(@delete,obj.child);
            obj.child = {};
            obj.fvhold(0);
            obj.BackgroundColor = [0 0 0];
            obj.CameraConstraints = 'auto';
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

        function set.EDLWithBackground(obj,tf)
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
            bboxes = cellfun(@worldBBox,obj.validateChilds('internal.fvDrawable'),'uni',0);
            xyz = cellfun(@fvBoundingBox.bbox2corners,bboxes,'uni',0);
            xyz = vertcat(xyz{:});
            xyz = mapply(xyz,obj.Model);
            bbox = fvBoundingBox.coords2bbox(xyz);
            obj.Camera.ZoomBBox(bbox);
        end

        function UpdateCameraConstraints(obj)
            if strcmpi(obj.validCamConstraints,'2D')
                % 2d mode
                obj.Camera.RotationActive(2) = 0;
                obj.Camera.Rotation(1) = 0;
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
            t = obj.PauseUpdates;
            obj.Camera.Rotation = strcmpi(obj.validCamConstraints,'3D') .* [-45 0 -45];
            obj.ResetCameraZoom;
        end

        function set.Light(obj,s)
            obj.Light = s;
            obj.Update;
        end

        function set.EDL(obj,value)
            obj.EDL = value;
            obj.Update;
        end

        function set.DepthRange(obj,value)
            obj.DepthRange = value;
            obj.Update;
        end

        function set.ColorOrder(obj,cmap)
            obj.ColorOrder = cmap;
            temp = obj.PauseUpdates;
            C = obj.validateChilds('internal.fvPrimitive');
            for i=1:numel(C)
                if isempty(C{i}.Color)
                    C{i}.UpdateColor;
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

        function m = full_model(~)
            m = eye(4);
            % m = obj.Model;
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
            t = obj.PauseUpdates;
            obj.parent.size = sz;
            obj.parent.parent.java.pack;
            obj.Update;
        end

        function set.MSAA(obj,n)
            obj.MSAA = obj.ctrl.SetMSAA(n);
            obj.Update;
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

    methods(Access=private)
        function EndPauseUpdate(obj)
            obj.pauseStack = max(0,obj.pauseStack - 1);
            if obj.UpdateNeeded, obj.Update; end
        end
    end

    methods(Hidden)

        function ResizeCallback(obj,sz)
            obj.Camera.Resize(sz);
            notify(obj,'Resized');
        end

        function MousePressedCallback(obj,~,evt)
            info = obj.ctrl.coord2closest(jevt2coords(evt.java,0),5);
            obj.Camera.PressAction(evt.java.getButton,info.xyz_gl)
            obj.lastMousePress = info;
        end

        function MouseDraggedCallback(obj,~,evt)
            obj.Camera.DragAction(evt.data.buttonMask,evt.data.dxy);
        end

        function MouseClickedCallback(obj,~,evt)
            t = obj.PauseUpdates; 
            evt.data = obj.lastMousePress;
            notify(obj,'MouseClicked',evt);
            if obj.PopupMenuActive && evt.java.isPopupTrigger
                obj.popup.show(evt)
            end
            o = evt.data.object;
            if ~isempty(o) && ~isempty(o.CallbackFcn)
                o.CallbackFcn(obj,evt);
            end
        end

        function MouseWheelMovedCallback(obj,~,evt)
            info = obj.ctrl.coord2closest(jevt2coords(evt.java,0),5);
            obj.Camera.ZoomAction(evt.java.getUnitsToScroll,info.xyz_gl);
        end

        function MouseMovedCallback(obj,~,evt)
            if ~event.hasListener(obj,'MouseHover') && ~event.hasListener(obj,'MouseMoved'), return, end
            t = obj.PauseUpdates;

            evt.data = obj.ctrl.coord2closest(jevt2coords(evt,0),5);

            notify(obj,'MouseMoved',evt);

            if ~isempty(evt.data.object)
                notify(obj,'MouseHover',evt);
            end
        end

        function FocusGainedCallback(obj,~,~)
            obj.lastFocus = datetime('now');
        end

        function [gl,temp] = getContext(obj)
            [gl,temp] = obj.parent.getContext;
        end

        function c = validCamera(obj)
            c = obj.Camera;
        end

        function r = validDepthRange(obj)
            r = obj.DepthRange;
        end

        function C = validateChilds(obj,desiredClass)
            C = obj.validateChilds@JChildParent;
            if nargin >= 2
                C = C(cellfun(@(c) isa(c,desiredClass),C));
            end
        end

        function s = saveobj(obj)
            s = obj.fv2struct;
        end

        function s = fv2struct(obj)
            m = metaclass(obj);
            tf = [m.PropertyList.Transient] & [m.PropertyList.SetObservable];
            props = {m.PropertyList(tf).Name};
            vals = cellfun(@(p) {obj.(p)},props,'uni',0);
            args = [props ; vals];
            s = struct('props',struct(args{:}));
            tf = cellfun(@(c) c.fvSave,obj.child);
            s.child = cellfun(@saveobj,obj.child(tf),'uni',0);
        end

    end

    methods(Static,Hidden)
        function obj = struct2fv(s)
            obj = fvFigure;
            t = obj.PauseUpdates;
            fvhold(obj,'on');
            cellfun(@(c) internal.fvChild.struct2fv(c,obj),s.child,'uni',0);
            set(obj,s.props);
        end

        function obj = loadobj(s)
            obj = fvFigure.struct2fv(s);
        end
    end
end
