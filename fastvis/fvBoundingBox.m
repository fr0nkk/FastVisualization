classdef fvBoundingBox < handle & matlab.mixin.SetGet
%FVBOUNDINGBOX 
    
    properties(Transient)
        bbox
        Visible
    end
    
    properties(SetAccess = private)
        BBoxLines
    end

    properties(Dependent)
        parent
    end

    properties(Access = private)
        el
    end

    methods
        function obj = fvBoundingBox(varargin)
            [parent,args,t] = internal.fvParse(varargin{:});
            p = inputParser;
            p.addOptional('bbox',[0 0 0 1 1 1]);
            p.KeepUnmatched = true;
            p.parse(args{:});

            [xyz,~,~,~,ind] = cubemesh;

            obj.BBoxLines = fvLine(parent,xyz,[0.5 0.5 0.5],ind,'Clickable',0);
            obj.bbox = p.Results.bbox;

            addlistener(obj.BBoxLines,'ObjectBeingDestroyed',@(~,~) obj.delete);
            set(obj,p.Unmatched);
        end

        function set.bbox(obj,b)
            delete(obj.el)
            if isempty(b)
                if ~isa(obj.parent,'internal.fvDrawable')
                    error('Parent can not be fvFigure for auto set')
                end
                obj.el = [
                    addlistener(obj.BBoxLines.parent,'CoordsChanged',@(src,evt) obj.UpdateModel)
                    addlistener(obj.BBoxLines.parent,'PrimitiveIndexChanged',@(src,evt) obj.UpdateModel)
                    ];
                obj.UpdateModel;
            else
                obj.BBoxLines.Model = obj.BBoxModel(b);
            end
            obj.bbox = b;
        end

        function p = get.parent(obj)
            p = obj.BBoxLines.parent;
        end

        function UpdateModel(obj)
            obj.BBoxLines.Model = obj.BBoxModel(obj.parent.BoundingBox);
        end

        function ind = Extract(obj,prim)
            % get the bounding box model in prim's SOC
            M = prim.full_model \ obj.BBoxLines.full_model;
            ind = obj.inside(prim.Coord,M);
        end

        function set.Visible(obj,v)
            obj.BBoxLines.Visible = v;
        end

        function v = get.Visible(obj)
            v = obj.BBoxLines.Visible;
        end

        function delete(obj)
            delete(obj.el);
            delete(obj.BBoxLines);
        end
    end

    methods(Static)
        function m = BBoxModel(bbox)
            m = MTrans3D(bbox(1:3)) * MScale3D(bbox(4:6));
        end

        function bbox = catbbox(bboxes)
            if ~iscell(bboxes), bboxes = num2cell(bboxes,2); end
            [p1,p2] = cellfun(@fvBoundingBox.bbox2corners,bboxes,'uni',0);
            p1 = min(vertcat(p1{:}),[],1); p2 = max(vertcat(p2{:}),[],1);
            bbox = fvBoundingBox.corners2bbox(p1,p2);
        end

        function bbox = coords2bbox(x)
            if width(x) < 3
                x(:,3) = 0;
            end
            minx = min(x,[],1);
            maxx = max(x,[],1);
            bbox = [minx maxx-minx];
        end

        function bbox = corners2bbox(p1,p2)
            p = [p1 ; p2];
            bbox = fvBoundingBox.coords2bbox(p);
        end

        function [p1,p2] = bbox2corners(bbox)
            p1 = bbox(1:3);
            p2 = p1 + bbox(4:6);
        end

        function ind = inside(coords,bboxModel)
            coords = mapply(coords,bboxModel,1);
            ind = all(coords >= 0 & coords <= 1,2);
        end
    end
end


