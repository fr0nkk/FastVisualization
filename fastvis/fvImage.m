classdef fvImage < internal.fvPrimitive
%FVIMAGE 
% 1 pixel of image is 1 unit of world
    
    properties(Transient,SetObservable)
        ImageSource
    end

    properties(SetAccess = protected)
        ImageSize
    end
    
    methods
        function obj = fvImage(varargin)
            [parent,args,t] = internal.fvParse(varargin{:});

            p = inputParser;
            p.addRequired('img',@(x) isscalartext(x) || isnumeric(x));
            p.KeepUnmatched = true;

            if ~mod(numel(args),2)
                % if number of arguments is even, assume no img given
                args = [{'peppers.png'} args];
            end

            p.parse(args{:});

            attr = [0 0;1 0;0 1;1 1];
            mtl = fvMaterial(0);
            obj@internal.fvPrimitive(parent,'GL_TRIANGLE_STRIP',attr,attr,[],[],mtl,1,'Name','fvImage');
            obj.ImageSource = p.Results.img;
            set(obj,p.Unmatched);
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
            obj.Coord = [0 0;1 0;0 1;1 1] .* fliplr(sz);
            obj.ImageSize = sz;
        end
    end
end

