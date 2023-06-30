classdef fvImage < internal.fvPrimitive
%FVIMAGE 
    
    properties(Transient)
        ImageSource
    end

    properties(SetAccess = protected)
        ImageSize
    end
    
    methods
        function obj = fvImage(varargin)
            [parent,args,t] = internal.fvParse(varargin{:});

            p = inputParser;
            p.addOptional('img',[],@(x) isscalartext(x) || isnumeric(x));
            p.KeepUnmatched = true;
            p.parse(args{:});

            img = p.Results.img;
            if isempty(img)
                img = 'peppers.png';
            end

            attr = [0 0;1 0;0 1;1 1];
            mtl = fvMaterial(0);
            obj@internal.fvPrimitive(parent,'GL_TRIANGLE_STRIP',attr,attr,[],[],mtl);
            obj.ImageSource = img;
            set(obj,p.Unmatched);
            if ~obj.fvfig.isHold
                obj.ZoomTo;
            end
        end

        function src = get.ImageSource(obj)
            src = obj.Material.color;
        end

        function set.ImageSource(obj,img)
            obj.Material.color = img;
            if isscalartext(img)
                info = imfinfo(img);
                sz = [info.Height info.Width];
            else
                sz = size(img,[1 2]);
            end
            obj.ImageSize = sz;
        end
    end
    methods(Access = protected)

        function m = ModelFcn(obj,m)
            m = m * MScale3D([fliplr(obj.ImageSize) 1]);
        end
        
    end
end

