classdef fvCamera < handle & matlab.mixin.Copyable
%FVCAMERA

    properties(Transient)
        viewParams % struct: O = origin, R = rotation, T = translation
        projParams

        ZoomSensitivity = 0.05; % zoom ratio / zoom quantity
        RotationSensitivity = [0.2 0.2]; % degrees of rotation / drag amount
        PanSensitivity = [1 -1]; % pixels of pan / drag amount

        ZoomActive = true
        RotationActive = [true true] % xy
        PanActive = [true true] % xy

        Projection = 'Perspective' % Perspective or Orthographic
        AnimateProjectionChange = false
        NearFarFcn = @(d) [d/10 d*50];
    end

    properties(Dependent)
        isPerspective
    end

    events
        Moved
    end

    properties(SetAccess=private)
        MView % 4x4 matrix
        MProj % 4x4 matrix
        isAnimatingMatrix = false;
    end

    properties(Transient,Access=private)
        viewParamsInternal = struct('O',[0 0 0],'R',[0 0 0],'T',[0 0 0]);
        projParamsInternal = struct('size',[500 500],'near',0.01,'far',100,'F',45);
        MProj_need_recalc = 1
        MView_need_recalc = 1
        buttonPressState
        cached_fov = 45
    end
    
    methods

        function tf = get.isPerspective(obj)
            tf = lower(obj.Projection(1)) == 'p';
        end

        function M = get.MProj(obj)
            if obj.MProj_need_recalc
                p = obj.projParamsInternal;
                if obj.isPerspective
                    obj.MProj = MProj3D('F2',[p.size(1)/p.size(2) p.F p.near p.far],1);
                else
                    obj.MProj = MProj3D('O',[p.size.*p.F p.near p.far]);
                end
                obj.MProj_need_recalc = 0;
            end
            M = obj.MProj;
        end

        function M = get.MView(obj)
            if obj.MView_need_recalc
                v = obj.viewParamsInternal;
                obj.MView = MTrans3D(v.T) * MRot3D(v.R,1,[1 2 3]) * MTrans3D(-v.O);
                obj.MView_need_recalc = 0;
            end
            M = obj.MView;
        end

        function ZoomBBox(obj,bbox)
            if nargin < 2 || isempty(bbox), bbox = [-0.5 -0.5 -0.5 1 1 1]; end
            obj.viewParamsInternal.O(:) = bbox(1:3)+bbox(4:6)./2;
            obj.viewParamsInternal.T(:) = [0 0 -max(max(bbox(4:6))*1.5,0.1)];
            if ~obj.isPerspective
                obj.projParamsInternal.F = -obj.viewParamsInternal.T(3) ./ mean(obj.projParamsInternal.size);
            end
            notify(obj,'Moved');
        end

        function SetOrigin(obj,coord)
            % set camera origin while keeping the same view
            if isempty(coord), return, end
            v = obj.viewParamsInternal;
            if any(isnan(coord))
                coord = mapply([0 0 0],MTrans3D([v.T(1:2) 0]) * MRot3D(v.R,1,[1 3]),1) + v.O;
            end
            M =  MTrans3D(v.T) * MRot3D(v.R,1,[1 2 3]);
            obj.viewParamsInternal.T(1:3) = mapply(coord-v.O,M);
            obj.viewParamsInternal.O(1:3) = coord;
        end

        function PressAction(obj,button,coords)
            obj.SetOrigin(coords);
            obj.buttonPressState{button} = obj.getState;
        end

        function k = getScaleFactor(obj,d)
            pp = obj.projParamsInternal;
            if obj.isPerspective
                k = d ./ max(pp.size) * (2*tand(pp.F/2));
            else
                k = pp.F;
            end
        end

        function DragAction(obj,buttonMask,dcoords)
            moved = false;
            if any(obj.PanActive) && buttonMask(1) && ~any(isnan(dcoords(1,:)))
                s = obj.buttonPressState{1};
                a = obj.PanSensitivity .* obj.PanActive;
                k = obj.getScaleFactor(-obj.viewParamsInternal.T(3)) .* a;
                obj.viewParamsInternal.T([1 2]) = s.view.T([1 2]) + dcoords(1,:) .* k;
                moved = true;
            end

            if any(obj.RotationActive) && buttonMask(3) && ~any(isnan(dcoords(3,:)))
                s = obj.buttonPressState{3};
                a = obj.RotationSensitivity .* obj.RotationActive;
                obj.viewParamsInternal.R([3 1]) = s.view.R([3 1]) + dcoords(3,:) .* a;
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
                    obj.projParamsInternal.F = obj.projParamsInternal.F .* k;
                    obj.viewParamsInternal.T(1:2) = obj.viewParamsInternal.T(1:2) .* k;
                else
                    obj.viewParamsInternal.T = obj.viewParamsInternal.T .* k;
                end
                notify(obj,'Moved');
            end
        end

        function set.viewParamsInternal(obj,s)
            obj.viewParamsInternal = s;
            obj.MView_need_recalc = 1;
        end

        function set.projParamsInternal(obj,s)
            obj.projParamsInternal = s;
            obj.MProj_need_recalc = 1;
        end

        function s = getState(obj)
            s.view = obj.viewParamsInternal;
            s.proj = obj.projParamsInternal;
        end

        function p = getCamPos(obj)
            p = mapply([0 0 0],obj.MView,1);
        end

        function x = getCamRay(obj)
            x = [0 0 1] * obj.MView(1:3,1:3);
        end

        function p = get.viewParams(obj)
            p = obj.viewParamsInternal;
        end

        function p = get.projParams(obj)
            p = obj.projParamsInternal;
        end

        function set.viewParams(obj,p)
            obj.viewParamsInternal = p;
            notify(obj,'Moved');
        end

        function set.projParams(obj,p)
            obj.projParamsInternal = p;
            notify(obj,'Moved');
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

        function AnimateParams(obj,pp0,vp0,pp1,vp1,dt)
            if nargin <= 4
                dt = pp1;
                pp1 = pp0;
                vp1 = vp0;
                pp0 = obj.projParamsInternal;
                vp0 = obj.viewParamsInternal;
            end
            if isempty(pp0), pp0 = obj.projParamsInternal; end
            if isempty(pp1), pp1 = obj.projParamsInternal; end
            if isempty(vp0), vp0 = obj.viewParamsInternal; end
            if isempty(vp1), vp1 = obj.viewParamsInternal; end

            obj.isAnimatingMatrix = true; temp = onCleanup(@() obj.EndAnimation(pp1,vp1));
            oldParam = [pp0.size pp0.near pp0.far pp0.F vp0.O vp0.R vp0.T];
            newParam = [pp1.size pp1.near pp1.far pp1.F vp1.O vp1.R vp1.T];

            t = tic;
            while toc(t) < dt
                interpParams= interp1([0 ; 1],[oldParam ; newParam],toc(t)/dt);
                obj.projParamsInternal.size = interpParams(1:2);
                obj.projParamsInternal.near = interpParams(3);
                obj.projParamsInternal.far = interpParams(4);
                obj.projParamsInternal.F = interpParams(5);
                obj.viewParamsInternal.O = interpParams(6:8);
                obj.viewParamsInternal.R = interpParams(9:11);
                obj.viewParamsInternal.T = interpParams(12:14);
                notify(obj,'Moved');
            end
        end

        function set.Projection(obj,p)
            if ~ismember(lower(p),{'perspective','orthographic'})
                error('Projection must be ''Perspective'' or ''Orthographic''')
            end
            if lower(p(1)) == lower(obj.Projection(1)), return, end

            oldM = {obj.MProj obj.MView};

            obj.Projection = char(p);
            if obj.isPerspective
                obj.viewParamsInternal.T(3) = -obj.projParamsInternal.F .* max(obj.projParamsInternal.size) / tand(obj.cached_fov);
                obj.projParamsInternal.F = obj.cached_fov;
            else
                obj.cached_fov = obj.projParamsInternal.F;
                obj.projParamsInternal.F = -obj.viewParamsInternal.T(3) ./ max(obj.projParamsInternal.size) * tand(obj.projParamsInternal.F);
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
            camDist = -obj.viewParamsInternal.T(3);
            nf = obj.NearFarFcn(camDist);
            obj.projParamsInternal.near = nf(1);
            obj.projParamsInternal.far = nf(2);
        end

        function Resize(obj,sz)
            obj.projParamsInternal.size = sz;
        end

        function EndAnimation(obj,P,V)
            if isstruct(P)
                obj.projParamsInternal = P;
                obj.viewParamsInternal = V;
            else
                obj.MProj = P;
                obj.MView = V;
            end
            obj.isAnimatingMatrix = false;
            notify(obj,'Moved');
        end

    end
end
