classdef fvBoundingBox < internal.fvChild
%FVBOUNDINGBOX 
    
    properties(Transient,SetObservable)
        bbox
        Visible
    end
    
    properties(Transient,SetAccess = private)
        BBoxLines
    end

    properties(Transient,Access = private)
        el
    end

    methods
        function obj = fvBoundingBox(varargin)
            [parent,args,t] = internal.fvParse(varargin{:});
            obj@internal.fvChild(parent)
            p = inputParser;
            p.addOptional('bbox',[0 0 0 1 1 1]);
            p.KeepUnmatched = true;
            p.parse(args{:});

            [xyz,~,~,~,ind] = cubemesh;
            if isa(parent,'fvFigure')
                h = parent.fvhold(1);
            end
            obj.BBoxLines = fvLine(parent,xyz,[0.5 0.5 0.5],ind,'Clickable',0,'Name','fvBoundingBox','fvSave',0);
            if exist('h','var')
                parent.fvhold(h);
            end
            obj.bbox = p.Results.bbox;

            addlistener(obj.BBoxLines,'ObjectBeingDestroyed',@(~,~) obj.delete);
            set(obj,p.Unmatched);
        end

        function set.bbox(obj,b)
            delete(obj.el)
            if isempty(b)
                if isa(obj.parent,'internal.fvDrawable')
                    obj.el = [
                        addlistener(obj.BBoxLines.parent,'CoordsChanged',@(src,evt) obj.UpdateModel)
                        addlistener(obj.BBoxLines.parent,'PrimitiveIndexChanged',@(src,evt) obj.UpdateModel)
                        ];
                    obj.UpdateModel;
                else
                    obj.BBoxLines.Model = obj.BBoxModel([0 0 0 1 1 1]);
                end
            else
                obj.BBoxLines.Model = obj.BBoxModel(b);
            end
            obj.bbox = b;
        end

        function UpdateModel(obj)
            obj.BBoxLines.Model = obj.BBoxModel(obj.parent.BoundingBox);
        end

        function ind = Extract(obj,prim)
            M = prim.full_model \ obj.BBoxLines.full_model; % get the bounding box model in prim's SOC
            ind = obj.inside(prim.Coord,M);
        end

        function set.Visible(obj,v)
            obj.BBoxLines.Visible = v;
        end

        function v = get.Visible(obj)
            v = obj.BBoxLines.Visible;
        end

        function bb = worldBBox(obj)
            bb = obj.BBoxLines.worldBBox;
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
            xyz = cellfun(@fvBoundingBox.bbox2corners,bboxes,'uni',0);
            bbox = fvBoundingBox.coords2bbox(vertcat(xyz{:}));
        end

        function bbox = coords2bbox(x)
            if width(x) < 3
                x(:,3) = 0;
            end
            minx = min(x,[],1);
            maxx = max(x,[],1);
            bbox = [minx maxx-minx];
        end

        function xyz = bbox2corners(bbox)
            p = [bbox(1:3) bbox(1:3) + bbox(4:6)];
            [X,Y,Z] = ndgrid(p([1 4]),p([2 5]),p([3 6]));
            xyz = [X(:) Y(:) Z(:)];
        end

        function ind = inside(coords,bboxModel)
            coords = mapply(coords,bboxModel,0);
            ind = all(coords >= 0 & coords <= 1,2);
        end
    end
end


