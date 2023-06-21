classdef fvMaterial < handle
    
    properties
        color
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
        function obj = fvMaterial(color,specular,shininess)
            if nargin < 1, color = [1 1 1]; end
            if nargin < 2, specular = [1 1 1]; end
            if nargin < 3, shininess = 10; end
            obj.color = color;
            obj.specular = specular;
            obj.shininess = shininess;
        end

        function tf = get.isTex(obj)
            tf = ischar(obj.color) || isstring(obj.color) || size(obj.color,3) > 1;
        end

        function set.color(obj,c)
            obj.color = c;
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

