classdef fvText < internal.fvPrimitive

    properties
        Text
        Font
        HorizontalAlignment % left right center
        VerticalAlignment % top bottom center
    end

    methods
        function obj = fvText(varargin)
            [parent,args,t] = internal.fvParse(varargin{:});
            p = inputParser;
            p.addOptional('str','Fast Visualization',@isscalartext);
            p.addOptional('sz',20);
            p.addOptional('font','Arial',@ischar);
            p.addOptional('hAlign','left',@ischar);
            p.addOptional('vAlign','bottom',@ischar);
            p.parse(args{:});

            str = p.Results.str;
            font = p.Results.font;
            hAlign = p.Results.hAlign;
            vAlign = p.Results.vAlign;

            [xyz,ind] = fvText.makeShape(char(str),1,font,hAlign,vAlign);

            obj@internal.fvPrimitive(parent,'GL_TRIANGLES',xyz,[1 1 0],[],ind);
            obj.ConstantSizeIsNormal = true;
            obj.ConstantSize = p.Results.sz;

            obj.isInit = false;

            obj.Text = str;
            obj.Font = font;
            obj.HorizontalAlignment = hAlign;
            obj.VerticalAlignment = vAlign;

            obj.isInit = true;

            if ~obj.fvfig.isHold
                obj.ZoomTo;
            end
        end

        function set.Text(obj,v)
            if strcmp(v,obj.Text), return, end
            if ~isscalartext(v)
                error('Text must be scalar string or char')
            end
            obj.Text = char(v);
            obj.UpdateShape;
        end

        function set.Font(obj,v)
            obj.Font = v;
            obj.UpdateShape;
        end

        function set.HorizontalAlignment(obj,v)
            obj.HorizontalAlignment = v;
            obj.UpdateShape;
        end

        function set.VerticalAlignment(obj,v)
            obj.VerticalAlignment = v;
            obj.UpdateShape;
        end

        function UpdateShape(obj)
            if ~obj.isInit, return, end
            t = obj.UpdateOnCleanup;
            [xyz,ind] = obj.makeShape(obj.Text,1,obj.Font,obj.HorizontalAlignment,obj.VerticalAlignment);
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

