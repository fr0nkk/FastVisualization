classdef fvCamera < handle & matlab.mixin.Copyable & matlab.mixin.SetGet
%FVCAMERA

    properties(Dependent,SetObservable)
        % Origin - Point around which the rotation is applied
        Origin (3,1) double {mustBeReal,mustBeFinite}

        % LocalPlane - Local level plane, with angles in degrees
        LocalPlane (3,1) double {mustBeReal,mustBeFinite}

        % Rotation - Angles in degrees to rotate
        Rotation (3,1) double {mustBeReal,mustBeFinite}

        % Translation - Offset to apply after rotation
        Translation (3,1) double {mustBeReal,mustBeFinite}

        % Size - Dimensions of the canvas [width, height]
        Size (2,1) double {mustBePositive}

        % NearFar - Near and far clip planes distances from camera
        NearFar (2,1) double {mustBeNonnegative}

        % FOV - Field of view of camera in perspective mode
        FOV (1,1) double {mustBePositive}

        % FOV - Zoom of camera in orthographic mode
        Zoom (1,1) double {mustBePositive}

        % Perspective - Use perspective or Orthographic projection
        Perspective (1,1) logical
    end

    properties(SetObservable)
        ZoomSensitivity = 0.05; % zoom ratio / zoom quantity
        RotationSensitivity = [0.2 0.2]; % degrees of rotation / drag amount
        PanSensitivity = [1 -1]; % pixels of pan / drag amount

        ZoomActive = true
        RotationActive = [true true] % xy
        PanActive = [true true] % xy

        AnimateProjectionChange = true
        NearFarFcn = @(d) [d/10 d*50];

    end

    events
        Moved
        Resized
    end

    properties(Transient,SetAccess=private,SetObservable)
        MView % 4x4 matrix
        MProj % 4x4 matrix
    end

    properties(Access=protected)
        iOrigin = [0 0 0];
        iLocalPlane = [0 0 0];
        iRotation = [0 0 0];
        iTranslation = [0 0 -1];
        iSize = [1 1];
        iNearFar = [0 1];
        iFOV = 45;
        iZoom = 1;
        iPerspective = true;
    end

    properties(Transient,Access=protected)
        MProj_need_recalc = 1
        MView_need_recalc = 1
        buttonPressState
        isAnimating = false
    end
    
    methods

        function obj = fvCamera(varargin)
            if ~isempty(varargin)
                set(obj,varargin{:});
            end
        end

        function tf = get.Perspective(obj)
            tf = obj.iPerspective;
        end

        function M = get.MProj(obj)
            if obj.MProj_need_recalc
                sz = obj.iSize;
                if obj.Perspective
                    obj.MProj = MProj3D('F2',[sz(1)/sz(2) obj.iFOV obj.iNearFar],1);
                else
                    obj.MProj = MProj3D('O',[sz./obj.iZoom obj.iNearFar]);
                end
                obj.MProj_need_recalc = 0;
            end
            M = obj.MProj;
        end

        function M = get.MView(obj)
            if obj.MView_need_recalc
                obj.MView = MTrans3D(obj.iTranslation) * MRot3D(obj.iRotation,1,[1 2 3]) * MRot3D(obj.iLocalPlane,1,[1 2 3]) * MTrans3D(-obj.iOrigin);
                obj.MView_need_recalc = 0;
            end
            M = obj.MView;
        end

        function ZoomBBox(obj,bbox)
            if nargin < 2 || isempty(bbox), bbox = [-0.5 -0.5 -0.5 1 1 1]; end
            obj.ZoomCenterRange(bbox(1:3)+bbox(4:6)./2,bbox(4:6));
        end

        function ZoomCenterRange(obj,center,range)
            obj.iOrigin(:) = center;
            obj.iTranslation(:) = [0 0 -max(range(:)).*2];
            obj.MView_need_recalc = 1;
            if ~obj.Perspective
                obj.iZoom = -mean(obj.iSize) ./ obj.iTranslation(3);
                obj.MProj_need_recalc = 1;
            end
            notify(obj,'Moved');
        end

        function SetOrigin(obj,coord)
            % set camera origin while keeping the same view
            if isempty(coord) || any(isnan(coord)), return, end

            [~,MT] = mdecompose(obj.MView * MTrans3D(coord));
            obj.iTranslation(1:3) = MT(1:3,4)';
            obj.iOrigin(1:3) = coord;
            obj.MView_need_recalc = 1;
        end

        function PressAction(obj,button,coords)
            obj.SetOrigin(coords);
            obj.buttonPressState{button} = obj.getState;
        end

        function k = getScaleFactor(obj,d)
            if nargin < 2, d = -obj.iTranslation(3); end
            if obj.Perspective
                k = d ./ max(obj.iSize) .* (2.*tand(obj.iFOV./2));
            else
                k = 1./obj.iZoom;
            end
        end

        function DragAction(obj,buttonMask,dcoords)
            moved = false;
            if any(obj.PanActive) && buttonMask(1) && ~any(isnan(dcoords(1,:)))
                s = obj.buttonPressState{1};
                a = obj.PanSensitivity .* obj.PanActive;
                k = obj.getScaleFactor .* a;
                obj.iTranslation([1 2]) = s.Translation([1 2]) + dcoords(1,:) .* k;
                moved = true;
            end

            if any(obj.RotationActive) && buttonMask(3) && ~any(isnan(dcoords(3,:)))
                s = obj.buttonPressState{3};
                a = obj.RotationSensitivity .* obj.RotationActive;
                obj.iRotation([3 1]) = mod(s.Rotation([3 1]) + dcoords(3,:) .* a,360);
                moved = true;
            end

            if moved
                obj.MView_need_recalc = 1;
                notify(obj,'Moved');
            end
        end

        function ZoomAction(obj,qty,coords)
            if obj.ZoomActive
                obj.SetOrigin(coords);
                k = 1 + qty.*obj.ZoomSensitivity;
                if ~obj.Perspective
                    obj.iZoom = obj.iZoom ./ k;
                    obj.MProj_need_recalc = 1;
                    obj.iTranslation(1:2) = obj.iTranslation(1:2) .* k;
                else
                    obj.iTranslation = obj.iTranslation .* k;
                end
                obj.MView_need_recalc = 1;
                notify(obj,'Moved');
            end
        end

        function s = getState(obj)
            s.Origin = obj.iOrigin;
            s.LocalPlane = obj.iLocalPlane;
            s.Rotation = obj.iRotation;
            s.Translation = obj.iTranslation;
            s.Size = obj.iSize;
            s.NearFar = obj.iNearFar;
            s.FOV = obj.iFOV;
            s.Zoom = obj.iZoom;
        end

        function setState(obj,s,silent)
            if nargin < 3, silent = false; end
            obj.iOrigin = s.Origin;
            obj.iLocalPlane = s.LocalPlane;
            obj.iRotation = s.Rotation;
            obj.iTranslation = s.Translation;
            obj.iSize = s.Size;
            obj.iNearFar = s.NearFar;
            obj.iFOV = s.FOV;
            obj.iZoom = s.Zoom;
            obj.MView_need_recalc = 1;
            obj.MProj_need_recalc = 1;
            if ~silent
                notify(obj,'Moved');
            end
        end

        function p = getCamPos(obj)
            p = mapply([0 0 0],obj.MView,0);
        end

        function x = getCamRay(obj,xyNDC)
            if nargin < 2, xyNDC = [0 0]; end

            xyNDC(:,3) = 0;

            p = obj.getCamPos;

            r = mapply(xyNDC,obj.MProj * obj.MView,false);

            x = r - p;

            x = x ./ vecnorm(x,2,2);


            % x = [0 0 1] * obj.MView(1:3,1:3);
        end

        function p = get.Origin(obj)
            p = obj.iOrigin;
        end

        function p = get.Rotation(obj)
            p = obj.iRotation;
        end

        function p = get.LocalPlane(obj)
            p = obj.iLocalPlane;
        end

        function p = get.Translation(obj)
            p = obj.iTranslation;
        end

        function p = get.Size(obj)
            p = obj.iSize;
        end

        function p = get.NearFar(obj)
            p = obj.iNearFar;
        end

        function p = get.FOV(obj)
            p = obj.iFOV;
        end

        function p = get.Zoom(obj)
            p = obj.iZoom;
        end

        function set.Origin(obj,p)
            obj.iOrigin(1:3) = p;
            obj.MView_need_recalc = 1;
            notify(obj,'Moved');
        end

        function set.Rotation(obj,p)
            obj.iRotation(1:3) = mod(p,360);
            obj.MView_need_recalc = 1;
            notify(obj,'Moved');
        end

        function set.LocalPlane(obj,p)
            obj.iLocalPlane(1:3) = mod(p,360);
            obj.MView_need_recalc = 1;
            notify(obj,'Moved');
        end

        function set.Translation(obj,p)
            obj.iTranslation(1:3) = p;
            obj.MView_need_recalc = 1;
            notify(obj,'Moved');
        end

        function set.Size(obj,p)
            obj.iSize(1:2) = p;
            obj.MProj_need_recalc = 1;
            notify(obj,'Moved');
        end

        function set.NearFar(obj,p)
            obj.iNearFar(1:2) = p;
            obj.MProj_need_recalc = 1;
            notify(obj,'Moved');
        end

        function set.FOV(obj,p)
            obj.iFOV(1) = p;
            obj.MProj_need_recalc = 1;
            notify(obj,'Moved');
        end

        function set.Zoom(obj,z)
            obj.iZoom(1) = z;
            obj.MProj_need_recalc = 1;
            notify(obj,'Moved');
        end

        function AnimateMatrix(obj,MP0,MV0,MP1,MV1,dt,p)
            if nargin < 7, p = 1; end
            if nargin <= 4
                dt = MP1;
                MP1 = MP0;
                MV1 = MV0;
                MP0 = obj.MProj;
                MV0 = obj.MView;
            end
            if isempty(MP0), MP0 = obj.MProj; end
            if isempty(MP1), MP1 = obj.MProj; end
            if isempty(MV0), MV0 = obj.MView; end
            if isempty(MV1), MV1 = obj.MView; end

            obj.isAnimating = true; temp = onCleanup(@() obj.EndAnimation(MP1,MV1));
            if ~event.hasListener(obj,'Moved'), return; end
            oldM = [MP0(:)' MV0(:)'];
            newM = [MP1(:)' MV1(:)'];
            t = tic;
            while toc(t) < dt
                interpM = interp1([0 ; 1],[oldM ; newM],(toc(t)/dt).^p);
                obj.MProj = reshape(interpM(1:16),4,4);
                obj.MView = reshape(interpM(17:32),4,4);
                notify(obj,'Moved');
            end
        end

        function AnimateState(obj,state0,state1,dt)
            if nargin <= 3
                dt = state1;
                state1 = state0;
                state0 = obj.getState;
            end

            obj.isAnimating = true; temp = onCleanup(@() obj.EndAnimation(state1));
            if ~event.hasListener(obj,'Moved'), return; end
            oldParam = [state0.Origin state0.LocalPlane state0.Rotation state0.Translation state0.Size state0.NearFar state0.FOV state0.Zoom];
            newParam = [state1.Origin state1.LocalPlane state1.Rotation state1.Translation state1.Size state1.NearFar state1.FOV state1.Zoom];

            t = tic;
            while toc(t) < dt
                interpState = interp1([0 ; 1],[oldParam ; newParam],toc(t)/dt);
                obj.iOrigin = interpState(1:3);
                obj.iLocalPlane = interpState(4:6);
                obj.iRotation = interpState(7:9);
                obj.iTranslation = interpState(10:12);
                obj.iSize = interpState(13:14);
                obj.iNearFar = interpState(15:16);
                obj.iFOV = interpState(17);
                obj.iZoom = interpState(18);
                obj.MView_need_recalc = 1;
                obj.MProj_need_recalc = 1;
                notify(obj,'Moved');
            end
        end

        function set.Perspective(obj,tf)
            tf = logical(tf(1));
            if ~xor(obj.Perspective,tf), return, end

            r = -max(obj.iSize) ./ (2*tand(obj.iFOV/2));

            if tf
                obj.iTranslation(3) = r ./ obj.iZoom;
                obj.MView_need_recalc = 1;
            end
            oldM = {obj.MProj obj.MView};
            obj.iPerspective = tf;
            if ~tf
                obj.iZoom = r ./ obj.iTranslation(3);
            end
            obj.MProj_need_recalc = 1;
            newM = {obj.MProj obj.MView};
            
            if obj.AnimateProjectionChange
                p = 2;
                if ~tf, p=1/p; end
                obj.AnimateMatrix(oldM{:},newM{:},0.25,p);
            else
                notify(obj,'Moved');
            end
            
        end

    end

    methods(Hidden)

        function AdjustNearFar(obj)
            if obj.isAnimating, return, end
            camDist = -obj.iTranslation(3);
            obj.iNearFar = obj.NearFarFcn(camDist);
            obj.MProj_need_recalc = 1;
        end

        function Resize(obj,sz)
            obj.iSize = sz;
            obj.MProj_need_recalc = 1;
            notify(obj,'Resized');
        end

        function EndAnimation(obj,P,V)
            if isstruct(P)
                obj.setState(P,1);
            else
                obj.MProj = P;
                obj.MView = V;
            end
            obj.isAnimating = false;
            notify(obj,'Moved');
        end

        function ui(obj,parent)

            fvJLinkedValue(parent,mfilename);

            fcn = @(o) abs(o.Translation(3))./500;
            fvJLinkedValue(parent,'Origin',obj,{'Origin','MView'},'DragStep',fcn);
            fvJLinkedValue(parent,'LocalPlane',obj,{'LocalPlane','MView'},'DragStep',0.25);
            fvJLinkedValue(parent,'Rotation',obj,{'Rotation','MView'},'DragStep',0.25);
            fvJLinkedValue(parent,'Translation',obj,{'Translation','MView'},'DragStep',fcn);

            fvJLinkedValue(parent,'Perspective',obj,'Perspective');
            fvJLinkedValue(parent,'FOV',obj,{'FOV','MProj'},'DragStep',0.1);
            fvJLinkedValue(parent,'Zoom',obj,{'Zoom','MProj'},'DragStep',0.5);

        end
    end
end
