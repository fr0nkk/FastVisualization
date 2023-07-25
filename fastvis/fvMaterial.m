classdef fvMaterial < handle
    
    properties(SetObservable)
        Color
        Alpha
        Specular
        Shininess
    end

    events
        PropChanged
    end

    properties(Dependent)
        isTex
        texture
    end
    
    methods
        function obj = fvMaterial(color,alpha,specular,shininess)
            if nargin < 1, color = [1 1 1]; end
            if nargin < 2, alpha = 1; end
            if nargin < 3, specular = [1 1 1]; end
            if nargin < 4, shininess = 10; end
            obj.Color = color;
            obj.Alpha = alpha;
            obj.Specular = specular;
            obj.Shininess = shininess;
        end

        function tf = get.isTex(obj)
            tf = isscalartext(obj.Color) || size(obj.Color,3) > 1;
        end

        function set.Color(obj,c)
            obj.Color = c;
            notify(obj,'PropChanged');
        end

        function set.Alpha(obj,a)
            obj.Alpha = a;
            notify(obj,'PropChanged');
        end

        function set.Specular(obj,s)
            obj.Specular = s;
            notify(obj,'PropChanged');
        end

        function set.Shininess(obj,s)
            obj.Shininess = s;
            notify(obj,'PropChanged');
        end
    end
end

