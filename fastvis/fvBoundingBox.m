classdef fvBoundingBox < fvLine
    %GLPOINTCLOUD Summary of this class goes here
    %   Detailed explanation goes here

    properties(Access = private)
        el
    end

    methods
        function obj = fvBoundingBox(varargin)
            [parent,args,t] = fvFigure.ParseInit(varargin{:});
            p = inputParser;
            p.addOptional('bbox',[]);
            p.addOptional('col',[]);
            p.parse(args{:});

            [xyz,~,~,ind] = cubemesh;

            col = p.Results.col;
            if isempty(col)
                col = [1 1 0];
            end
            bbox = p.Results.bbox;

            obj@fvLine(parent,xyz,col,ind,1);
            obj.primitive_type = 'GL_LINES';
            obj.clickable = 0;
            
            if isa(parent,'fvPrimitive')
                obj.el = [
                    addlistener(parent,'CoordsChanged',@(src,evt) obj.UpdateModel)
                    addlistener(parent,'PrimitiveIndexChanged',@(src,evt) obj.UpdateModel)
                    ];
                obj.UpdateModel;
            elseif ~isempty(bbox)
                obj.model = obj.BBoxModel(bbox);
            end
        end

        function UpdateModel(obj)
            obj.model = obj.BBoxModel(obj.parent.BoundingBox);
        end

        function delete(obj)
            delete(obj.el);
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


