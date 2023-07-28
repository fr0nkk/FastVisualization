classdef fvHud < fvLine
    %FVHUD Work in progress - experimental
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
        hud_listeners
    end

    methods
        function obj = fvHud(varargin)
            [ax,args,t] = internal.fvParse(varargin{:});
            c = fvCamera;
            c.Translation = [0 0 -1/tand(c.FOV/2)];
            
            xy = [0 0 ; 0 1 ; 1 1 ; 1 0 ; 0 0];
            obj@fvLine(ax,xy,[1 1 0],'Camera',c,'DepthRange',[0 0.1],'Visible',0,'Name','fvHud');
            
            
            obj.hud_listeners = [
                addlistener(obj.fvfig,'Resized',@(~,~) obj.ResizeHud);
                addlistener(obj.fvfig,'Model','PostSet',@(~,~) obj.ResizeHud);
                ];
            obj.ResizeHud();

            if ~isa(ax,'fvFigure')
                warning('attaching fvHud to something else than fvFigure may give unexpected results')
            end

        end

        function ZoomTo(obj)
            % do nothing
        end

        function delete(obj)
            delete(obj.hud_listeners);
        end
    end
    methods(Access=protected)
        function ResizeHud(obj)
            sz = obj.fvfig.Camera.Size;
            obj.Camera.Resize(sz);
            obj.Model = obj.parent.Model \ MScale3D([sz./max(sz) 1]) * MTrans3D([-1 -1 0]) * MScale3D([2 2 1]);
        end
    end
end


