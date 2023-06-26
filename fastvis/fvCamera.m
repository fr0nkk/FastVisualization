classdef fvCamera < handle

    properties(Transient)
        viewParams % struct: O = origin, R = rotation, T = translation
        projParams

        ZoomSensitivity = 0.05; % zoom ratio / zoom quantity
        RotationSensitivity = [0.2 0.2]; % degrees of rotation / drag amount
        PanSensitivity = [1 -1]; % pixels of pan / drag amount

        ZoomActive = true
        RotationActive = [true true] % xy
        PanActive = [true true] % xy
    end

    events
        Moved
    end

    properties(SetAccess=private)
        MView % 4x4 matrix
        MProj % 4x4 matrix
    end

    properties(Transient,Access=private)
        viewParamsInternal = struct('O',[0 0 0],'R',[-45 0 -45],'T',[0 0 -1]);
        projParamsInternal = struct('size',[500 500],'near',0.01,'far',100,'F',1);
        MProj_need_recalc = 1
        MView_need_recalc = 1
        buttonPressState
    end
    
    methods

        function M = get.MProj(obj)
            if obj.MProj_need_recalc
                p = obj.projParamsInternal;
                obj.MProj = MProj3D('P',[[p.size./mean(p.size) p.F].*p.near p.far]);
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
            obj.viewParamsInternal.T(:) = [0 0 -max(max(bbox(4:6))*1.5,0.01)];
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

        function DragAction(obj,buttonMask,dcoords)
            moved = false;
            if any(obj.PanActive) && buttonMask(1) && ~any(isnan(dcoords(1,:)))
                s = obj.buttonPressState{1};
                a = obj.PanSensitivity .* obj.PanActive;
                k = -s.view.T(3) ./ (mean(s.proj.size).*s.proj.F) .* a;
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
                obj.viewParamsInternal.T = obj.viewParamsInternal.T .* (1 + (qty.*obj.ZoomSensitivity));
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

    end

    methods(Hidden)
        
        function [MP,MV] = PrepareDraw(obj)
            camDist = -obj.viewParamsInternal.T(3);
            obj.projParamsInternal.near = camDist/10;
            obj.projParamsInternal.far = camDist*100;
            MP = obj.MProj;
            MV = obj.MView;
        end

        function Resize(obj,sz)
            obj.projParamsInternal.size = sz;
        end

    end
end
