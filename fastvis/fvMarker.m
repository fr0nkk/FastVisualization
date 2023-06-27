classdef fvMarker < fvLine & fvConstantSize

    properties(Hidden)
        ConstSizeIsNormal = false
    end

    methods
        function obj = fvMarker(varargin)
            [parent,args,t] = fvFigure.ParseInit(varargin{:});
            p = inputParser;
            p.addOptional('pos',[0 0 0]);
            p.addOptional('sz',20);
            p.parse(args{:});
            
            xyz = [-1 0 0; 1 0 0 ; 0 -1 0 ; 0 1 0 ; 0 0 -1 ; 0 0 1]./2;

            obj@fvLine(parent,xyz,[1 1 0],[1 2 nan 3 4 nan 5 6]');
            obj@fvConstantSize(p.Results.sz)
            obj.clickable = 0;
            obj.model = MTrans3D(p.Results.pos);
            
        end
    end
end

