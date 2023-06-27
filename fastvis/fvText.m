classdef fvText < fvPrimitive & fvConstantSize

    properties
        Text
        Font
        hAlign % left right center
        vAlign % top bottom center
    end

    properties(Hidden)
        ConstSizeIsNormal = true;
    end

    methods
        function obj = fvText(varargin)
            [parent,args,t] = fvFigure.ParseInit(varargin{:});
            p = inputParser;
            p.addOptional('str','Fast Visualization',@ischar);
            p.addOptional('sz',20);
            p.addOptional('font','Arial',@ischar);
            p.addOptional('hAlign','left',@ischar);
            p.addOptional('vAlign','bottom',@ischar);
            p.parse(args{:});

            str = p.Results.str;
            font = p.Results.font;
            hAlign = p.Results.hAlign;
            vAlign = p.Results.vAlign;

            [xyz,ind] = fvText.makeShape(str,1,font,hAlign,vAlign);

            obj@fvPrimitive(parent,'GL_TRIANGLES',xyz,[1 1 0],[],ind);
            obj = obj@fvConstantSize(p.Results.sz);

            obj.isInit = false;

            obj.Text = str;
            obj.Font = font;
            obj.hAlign = hAlign;
            obj.vAlign = vAlign;

            obj.isInit = true;
        end

        function set.Text(obj,v)
            if strcmp(v,obj.Text), return, end
            obj.Text = v;
            obj.UpdateShape;
        end

        function set.Font(obj,v)
            obj.Font = v;
            obj.UpdateShape;
        end

        function set.hAlign(obj,v)
            obj.hAlign = v;
            obj.UpdateShape;
        end

        function set.vAlign(obj,v)
            obj.vAlign = v;
            obj.UpdateShape;
        end

        function UpdateShape(obj)
            if ~obj.isInit, return, end
            t = obj.UpdateOnCleanup;
            [xyz,ind] = obj.makeShape(obj.Text,1,obj.Font,obj.hAlign,obj.vAlign);
            obj.Coord = xyz;
            obj.Index = ind;
        end
    end

    methods(Static)
        function [xyz,ind] = makeShape(str,sz,font,hAlign,vAlign)
            shp = str2shape(str,sz,font,hAlign,vAlign,6);
            if ~shp.NumRegions
                xyz = [nan nan];
                ind = 1;
            else
                tri = shp.triangulation;
                xyz = tri.Points;
                ind = tri.ConnectivityList;
            end
        end
    end
end

