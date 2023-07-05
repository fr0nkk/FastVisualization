classdef fvBoundingBox < handle
%FVBOUNDINGBOX 

    properties(Access = private)
        el
        L
    end

    methods
        function obj = fvBoundingBox(varargin)
            [parent,args,t] = internal.fvParse(varargin{:});
            p = inputParser;
            p.addOptional('bbox',[]);
            p.addOptional('col',[]);
            p.parse(args{:});

            [xyz,~,~,~,ind] = cubemesh;

            col = p.Results.col;
            if isempty(col)
                col = [1 1 0];
            end

            bbox = p.Results.bbox;

            obj.L = fvLine(parent,xyz,col,ind,'Clickable',0);
            
            if isa(parent,'internal.fvDrawable')
                obj.el = [
                    addlistener(parent,'CoordsChanged',@(src,evt) obj.UpdateModel)
                    addlistener(parent,'PrimitiveIndexChanged',@(src,evt) obj.UpdateModel)
                    ];
                obj.UpdateModel;
            elseif ~isempty(bbox)
                obj.L.Model = obj.BBoxModel(bbox);
            end
        end

        function UpdateModel(obj)
            obj.L.Model = obj.BBoxModel(obj.L.parent.BoundingBox);
        end

        function delete(obj)
            delete(obj.el);
            delete(obj.L);
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
    end
end


