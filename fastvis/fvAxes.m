classdef fvAxes < fvLine
    methods
        function obj = fvAxes(varargin)
            [parent,~,t] = fvFigure.ParseInit(varargin{:});

            xyz = [0 0 0; 1 0 0 ; 0 0 0 ; 0 1 0 ; 0 0 0 ; 0 0 1];
            col = [1 0 0 ; 1 0 0 ; 0 1 0 ; 0 1 0 ; 0 0 1; 0 0 1];

            obj@fvLine(parent,xyz,col);
            obj.primitive_type = 'GL_LINES';
            obj.clickable = 0;
        end
    end
end

