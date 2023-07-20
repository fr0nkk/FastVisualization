classdef fvCamera < handle & matlab.mixin.Copyable & matlab.mixin.SetGet
%FVCAMERA

    properties(Dependent,SetObservable)
        Origin
        Rotation
        Translation
        Size
        NearFar
        FOV
        Projection
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

    properties(Dependent)
        isPerspective
    end

    events
        Moved
        Resized
    end

    properties(Transient,SetAccess=private)
        MView % 4x4 matrix
        MProj % 4x4 matrix
        isAnimatingMatrix = false;
    end

    properties(Access=private)
        iOrigin = [0 0 0];
        iRotation = [0 0 0];
        iTranslation = [0 0 -1];
        iSize = [1 1];
        iNearFar = [0 1];
        iFOV = 45;
        iProjection = 'Perspective'
    end

    properties(Transient,Access=private)
        MProj_need_recalc = 1
        MView_need_recalc = 1
        buttonPressState
        cached_fov = 45
    end
    
    methods

        function obj = fvCamera(varargin)
            if ~isempty(varargin)
                set(obj,varargin{:});
            end
        end

        function tf = get.isPerspective(obj)
            tf = lower(obj.iProjection(1)) == 'p';
        end

        function M = get.MProj(obj)
            if obj.MProj_need_recalc
                sz = obj.iSize;
                if obj.isPerspective
                    obj.MProj = MProj3D('F2',[sz(1)/sz(2) obj.iFOV obj.iNearFar],1);
                else
                    obj.MProj = MProj3D('O',[sz.*obj.iFOV obj.iNearFar]);
                end
                obj.MProj_need_recalc = 0;
            end
            M = obj.MProj;
        end

        function M = get.MView(obj)
            if obj.MView_need_recalc
                obj.MView = MTrans3D(obj.iTranslation) * MRot3D(obj.iRotation,1,[1 2 3]) * MTrans3D(-obj.iOrigin);
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
            if ~obj.isPerspective
                obj.iFOV = -obj.iTranslation(3) ./ mean(obj.iSize);
            end
            notify(obj,'Moved');
        end

        function SetOrigin(obj,coord)
            % set camera origin while keeping the same view
            if isempty(coord), return, end
            if any(isnan(coord))
                coord = mapply([0 0 0],MTrans3D([obj.iTranslation(1:2) 0]) * MRot3D(obj.iRotation,1,[1 3]),0) + obj.iOrigin;
            end
            M =  MTrans3D(obj.iTranslation) * MRot3D(obj.iRotation,1,[1 2 3]);
            obj.iTranslation(1:3) = mapply(coord-obj.iOrigin,M);
            obj.iOrigin(1:3) = coord;
        end

        function PressAction(obj,button,coords)
            obj.SetOrigin(coords);
            obj.buttonPressState{button} = obj.getState;
        end

        function k = getScaleFactor(obj,d)
            if nargin < 2, d = -obj.iTranslation(3); end
            if obj.isPerspective
                k = d ./ max(obj.iSize) * (2*tand(obj.iFOV/2));
            else
                k = obj.iFOV;
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
                obj.iRotation([3 1]) = s.Rotation([3 1]) + dcoords(3,:) .* a;
                moved = true;
            end

            if moved
                notify(obj,'Moved');
            end
        end

        function ZoomAction(obj,qty,coords)
            if obj.ZoomActive
                obj.SetOrigin(coords);
                k = (1 + (qty.*obj.ZoomSensitivity));
                if ~obj.isPerspective
                    obj.iFOV = obj.iFOV .* k;
                    obj.iTranslation(1:2) = obj.iTranslation(1:2) .* k;
                else
                    obj.iTranslation = obj.iTranslation .* k;
                end
                notify(obj,'Moved');
            end
        end

        function s = getState(obj)
            s.Origin = obj.iOrigin;
            s.Rotation = obj.iRotation;
            s.Translation = obj.iTranslation;
            s.Size = obj.iSize;
            s.NearFar = obj.iNearFar;
            s.FOV = obj.iFOV;
        end

        function setState(obj,s,silent)
            if nargin < 3, silent = false; end
            obj.iOrigin = s.Origin;
            obj.iRotation = s.Rotation;
            obj.iTranslation = s.Translation;
            obj.iSize = s.Size;
            obj.iNearFar = s.NearFar;
            obj.iFOV = s.FOV;
            if ~silent
                notify(obj,'Moved');
            end
        end

        function p = getCamPos(obj)
            p = mapply([0 0 0],obj.MView,0);
        end

        function x = getCamRay(obj)
            x = [0 0 1] * obj.MView(1:3,1:3);
        end


        function p = get.Origin(obj)
            p = obj.iOrigin;
        end

        function p = get.Rotation(obj)
            p = obj.iRotation;
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

        function p = get.Projection(obj)
            p = obj.iProjection;
        end

        function set.Origin(obj,p)
            obj.iOrigin = p;
            notify(obj,'Moved');
        end

        function set.Rotation(obj,p)
            obj.iRotation = p;
            notify(obj,'Moved');
        end

        function set.Translation(obj,p)
            obj.iTranslation = p;
            notify(obj,'Moved');
        end

        function set.Size(obj,p)
            obj.iSize = p;
            notify(obj,'Moved');
        end

        function set.NearFar(obj,p)
            obj.iNearFar = p;
            notify(obj,'Moved');
        end

        function set.FOV(obj,p)
            obj.iFOV = p;
            notify(obj,'Moved');
        end

        function set.iOrigin(obj,p)
            obj.iOrigin = p;
            obj.MView_need_recalc = 1;
        end

        function set.iRotation(obj,p)
            obj.iRotation = p;
            obj.MView_need_recalc = 1;
        end

        function set.iTranslation(obj,p)
            obj.iTranslation = p;
            obj.MView_need_recalc = 1;
        end

        function set.iSize(obj,p)
            obj.iSize = p;
            obj.MProj_need_recalc = 1;
        end

        function set.iNearFar(obj,p)
            obj.iNearFar = p;
            obj.MProj_need_recalc = 1;
        end

        function set.iFOV(obj,p)
            obj.iFOV = p;
            obj.MProj_need_recalc = 1;
        end


        function AnimateMatrix(obj,MP0,MV0,MP1,MV1,dt)
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

            obj.isAnimatingMatrix = true; temp = onCleanup(@() obj.EndAnimation(MP1,MV1));
            if ~event.hasListener(obj,'Moved'), return; end
            oldM = [MP0(:)' MV0(:)'];
            newM = [MP1(:)' MV1(:)'];
            t = tic;
            while toc(t) < dt
                interpM = interp1([0 ; 1],[oldM ; newM],toc(t)/dt);
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

            obj.isAnimatingMatrix = true; temp = onCleanup(@() obj.EndAnimation(state1));
            if ~event.hasListener(obj,'Moved'), return; end
            oldParam = [state0.Origin state0.Rotation state0.Translation state0.Size state0.NearFar state0.FOV];
            newParam = [state1.Origin state1.Rotation state1.Translation state1.Size state1.NearFar state1.FOV];

            t = tic;
            while toc(t) < dt
                interpState = interp1([0 ; 1],[oldParam ; newParam],toc(t)/dt);
                obj.iOrigin = interpState(1:3);
                obj.iRotation = interpState(4:6);
                obj.iTranslation = interpState(7:9);
                obj.iSize = interpState(10:11);
                obj.iNearFar = interpState(12:13);
                obj.iFOV = interpState(14);
                notify(obj,'Moved');
            end
        end

        function set.Projection(obj,p)
            if ~ismember(lower(p),{'perspective','orthographic'})
                error('Projection must be ''Perspective'' or ''Orthographic''')
            end
            if lower(p(1)) == lower(obj.iProjection(1)), return, end

            oldM = {obj.MProj obj.MView};

            obj.iProjection = char(p);
            if obj.isPerspective
                obj.iTranslation(3) = -obj.iFOV .* max(obj.iSize) / 2/tand(obj.cached_fov/2);
                obj.iFOV = obj.cached_fov;
            else
                obj.cached_fov = obj.iFOV;
                obj.iFOV = -obj.iTranslation(3) ./ max(obj.iSize) * 2*tand(obj.iFOV/2);
            end
            newM = {obj.MProj obj.MView};
            
            if obj.AnimateProjectionChange
                obj.AnimateMatrix(oldM{:},newM{:},0.5);
            else
                notify(obj,'Moved');
            end
            
        end

    end

    methods(Hidden)

        function AdjustNearFar(obj)
            if obj.isAnimatingMatrix, return, end
            camDist = -obj.iTranslation(3);
            obj.iNearFar = obj.NearFarFcn(camDist);
        end

        function Resize(obj,sz)
            obj.iSize = sz;
            notify(obj,'Resized');
        end

        function EndAnimation(obj,P,V)
            if isstruct(P)
                obj.setState(P,1);
            else
                obj.MProj = P;
                obj.MView = V;
            end
            obj.isAnimatingMatrix = false;
            notify(obj,'Moved');
        end
    end
end
