classdef fvFigure < JChildParent
    
    properties(Transient,SetObservable)
        BackgroundColor = [0 0 0];
        Light = struct('Position',[0 0 1e5],'Ambient',[1 1 1],'Diffuse',[1 1 1],'Specular',[1 1 1]);
        isHold matlab.lang.OnOffSwitchState = false;
        edl = 0.1;
        edlWithBackground logical = false
        ColorOrder = lines(7);
        Camera
        type = 'auto'; % auto, 2D or 3D
        Model = eye(4)
    end

    properties(Transient)
        Title
    end

    properties(Hidden)
        ctrl internal.fvController
        lastFocus
        mtlCache internal.fvMaterialCache
    end

    events
        MouseClicked
        MouseHover
        MouseMoved
        KeyTyped
    end

    properties(Access = protected)
        MouseEvents
        lastMousePress
        mousePressOrigin = nan(0,2);
        camStateOrigin = cell(0,1);
        pauseStack = 0
        % holdStack = 0
        camMouseListeners
        camListener
    end

    properties(Dependent,Access=protected)
        validType
    end
    
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
                % obj.Camera.projParams.size(1:2) = obj.ctrl.figSize;
                % obj.Update;
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
            if ~isempty(o.CallbackFcn), o.CallbackFcn(obj,evt); end
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
            obj.Camera.AdjustNearFar;
            obj.parent.Update;
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
            cellfun(@delete,obj.child);
            obj.child = {};
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

        function addprimitive(obj,prim)
            if prim.isInit, return, end
            if ~obj.isHold %&& ~obj.holdStack
                obj.fvclear;
            end
            obj.addChild(prim);
            
            if ~obj.isHold
                obj.ResetCamera;
            end
            obj.UpdateCameraConstraints;
        end

        function ResetCameraZoom(obj)
            bboxes = cellfun(@(c) c.worldBBox,obj.child,'uni',0);
            bbox = fvBoundingBox.catbbox(bboxes);
            obj.Camera.ZoomBBox(bbox);
        end

        function UpdateCameraConstraints(obj)
            if strcmpi(obj.validType,'2D')
                % 2d mode
                obj.Camera.RotationActive(2) = 0;
                obj.Camera.viewParams.R(1) = 0;
            else
                % 3d mode
                obj.Camera.RotationActive(2) = 1;
            end
        end

        function set.type(obj,t)
            obj.type = t;
            obj.UpdateCameraConstraints
        end

        function t = get.validType(obj)
            t = obj.type;
            if strcmpi(t,'auto')
                d = max(cellfun(@ndims,obj.child));
                if isempty(d) || d >= 3
                    t = '3D';
                else
                    t = '2D';
                end
            end
        end

        function img = Snapshot(obj)
            img = obj.ctrl.Snapshot;
            if nargout == 0
                figure('Name','fvFigure Snapshot','NumberTitle','off');
                imshow(img);
                clear img
            end
        end

        function ResetCamera(obj)
            t = obj.UpdateOnCleanup;
            obj.Camera.viewParams.R = strcmpi(obj.validType,'3D') .* [-45 0 -45];
            obj.ResetCameraZoom;
        end

        % function t = TempHold(obj)
        %     obj.holdStack = obj.holdStack+1;
        %     t = onCleanup(@obj.EndTempHold);
        % end

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

        % function EndTempHold(obj)
        %     obj.holdStack = max(0,obj.holdStack - 1);
        % end

        function t = get.Title(obj)
            t = obj.parent.parent.title;
        end

        function set.Title(obj,t)
            obj.parent.parent.title = t;
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
    end
end
