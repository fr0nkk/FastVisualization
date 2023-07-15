classdef fvHud < fvLine
    %FVHUD Work in progress
    % Attaching Text or image with constant size to this primitive will
    % show them always on top in the range [0..1]
    %
    % example:
    % fvPointcloud;
    % fvhold on;
    % h = fvHud;
    % fvText(h,'SomeText').Translate([0.1 0.1 0]);
    % fvImage(h,'ConstantSize',0.5); % 1 pixel of image is 0.5 pixel of figure

    properties(Access=protected)
        resize_listener
    end

    methods
        function obj = fvHud(varargin)
            [ax,args,t] = internal.fvParse(varargin{:});
            
            c = fvCamera;
            c.viewParams.T = [0 0 -1/tand(c.projParams.F/2)];
            
            xy = ([0 0 ; 0 1 ; 1 1 ; 1 0 ; 0 0]-0.5)./1.01+0.5;
            obj@fvLine(ax,xy,[1 1 0],'Camera',c,'DepthRange',[0 0.1],'Visible',1,'Name','fvHud');
            
            
            obj.resize_listener = addlistener(obj.fvfig.Camera,'Resized',@(~,~) obj.ResizeHud);
            obj.ResizeHud();

        end

        function ZoomTo(obj)
            % do nothing
        end

        function delete(obj)
            delete(obj.resize_listener);
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


