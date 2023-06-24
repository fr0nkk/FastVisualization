classdef fvMaterial < handle
    
    properties
        color
        alpha
        specular
        shininess
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
            obj.color = color;
            obj.alpha = alpha;
            obj.specular = specular;
            obj.shininess = shininess;
        end

        function tf = get.isTex(obj)
            tf = isscalartext(obj.color) || size(obj.color,3) > 1;
        end

        function set.color(obj,c)
            obj.color = c;
            notify(obj,'PropChanged');
        end

        function set.alpha(obj,a)
            obj.alpha = a;
            notify(obj,'PropChanged');
        end

        function set.specular(obj,s)
            obj.specular = s;
            notify(obj,'PropChanged');
        end

        function set.shininess(obj,s)
            obj.shininess = s;
            notify(obj,'PropChanged');
        end
    end
end

