classdef fvText < fvPrimitive

    properties
        str
        col
        sz
        font
        hAlign
        vAlign
    end

    methods
        function obj = fvText(varargin)
            [ax,args,t] = fvFigure.ParseInit(varargin{:});
            p = inputParser;
            p.addOptional('str','Fast Visualization',@ischar);
            p.addOptional('col',[1 1 0]);
            p.addOptional('sz',1);
            p.addOptional('font','Arial',@ischar);
            p.addOptional('hAlign','left',@ischar);
            p.addOptional('vAlign','bottom',@ischar);
            p.parse(args{:});

            str = p.Results.str;
            col = p.Results.col;
            sz = p.Results.sz;
            font = p.Results.font;
            hAlign = p.Results.hAlign;
            vAlign = p.Results.vAlign;

            [xyz,ind] = fvText.makeShape(str,sz,font,hAlign,vAlign);



            obj@fvPrimitive(ax,'GL_TRIANGLES',xyz,col,[],ind);

            obj.isInit = false;

            obj.str = str;
            obj.col = col;
            obj.sz = sz;
            obj.font = font;
            obj.hAlign = hAlign;
            obj.vAlign = vAlign;

            obj.isInit = true;
        end

        function set.str(obj,v)
            if strcmp(v,obj.str), return, end
            obj.str = v;
            obj.UpdateShape;
        end

        function set.col(obj,v)
            obj.col = v;
            obj.UpdateShape;
        end

        function set.sz(obj,v)
            obj.sz = v;
            obj.UpdateShape;
        end

        function set.font(obj,v)
            obj.font = v;
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
            [xyz,ind] = obj.makeShape(obj.str,obj.sz,obj.font,obj.hAlign,obj.vAlign);
            obj.Coord = xyz;
            obj.Index = ind;
            obj.Color = obj.col;
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

