classdef fvHud < fvLine
    properties(Access=protected)
        el
    end
    methods
        function obj = fvHud(varargin)
            [ax,args,t] = internal.fvParse(varargin{:});
            
            c = fvCamera;
            c.viewParams.T = [0 0 -1/tand(c.projParams.F/2)];
            
            xy = ([0 0 ; 0 1 ; 1 1 ; 1 0 ; 0 0]-0.5)./1.01+0.5;
            obj@fvLine(ax,xy,[1 1 0],'Camera',c,'DepthRange',[0 0.1],'Visible',1);
            
            
            obj.el = addlistener(obj.fvfig.Camera,'Resized',@(~,~) obj.ResizeHud);
            obj.ResizeHud();

        end

        function ZoomTo(obj)
            % do nothing
        end

        function delete(obj)
            delete(obj.el);
        end
    end
    methods(Access=protected)
        function ResizeHud(obj)
            sz = obj.fvfig.Camera.projParams.size;
            obj.Camera.Resize(sz);
            obj.Model = MScale3D([sz./max(sz) 1]) * MTrans3D([-1 -1 0]) * MScale3D([2 2 1]);
        end
    end
end


