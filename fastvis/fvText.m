classdef fvText < internal.fvPrimitive

    properties
        Text
        Font
        HorizontalAlignment = 'Left' % left right center
        VerticalAlignment = 'Bottom' % top bottom center
    end

    methods
        function obj = fvText(varargin)
            [parent,args,t] = internal.fvParse(varargin{:});
            p = inputParser;
            p.addRequired('Text',@isscalartext);
            p.addParameter('Size',20,@isscalar);
            p.addParameter('Font','Arial',@isscalartext);
            p.KeepUnmatched = true;
            if ~mod(numel(args),2)
                % if number of arguments is even, assume no str given
                args = [{'Fast Visualization'} args];
            end
            p.parse(args{:});
            
            sz = p.Results.Size;
            obj@internal.fvPrimitive(parent,'GL_TRIANGLES',[0 0 0],[1 1 0],[],nan,[],[],'ConstantSizeRot','Normal','ConstantSize',sz);

            obj.isInit = false;

            obj.Text = p.Results.Text;
            obj.Font = p.Results.Font;

            obj.isInit = true;

            obj.UpdateShape;

            set(obj,p.Unmatched);

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

function tf = istextmember(x,opts)
    tf = isscalartext(x) && ismember(lower(x),opts);
end

