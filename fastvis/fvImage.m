classdef fvImage < fvPrimitive
    %GLPOINTCLOUD Summary of this class goes here
    %   Detailed explanation goes here
    properties
        ImageSource
    end
    
    methods
        function obj = fvImage(varargin)
            [ax,args,t] = fvFigure.ParseInit(varargin{:});

            p = inputParser;
            p.addOptional('img',[]);
            p.parse(args{:});

            img = p.Results.img;
            if isempty(img)
                img = 'peppers.png';
            end

            attr = [0 0;1 0;0 1;1 1];
            mtl = fvMaterial(img);
            obj@fvPrimitive(ax,'GL_TRIANGLE_STRIP',attr,attr,[],[],mtl);
        end

        function src = get.ImageSource(obj)
            src = obj.Material.color;
        end

        function set.ImageSource(obj,img)
            obj.Material.color = img;
        end
        
    end
end

