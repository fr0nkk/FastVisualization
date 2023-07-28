classdef fvText < internal.fvPrimitive
%FVTEXT Insert text
% fvText(text,'Property',Value,...)

    properties(Transient,SetObservable)
        % Text - Text to display
        Text char

        % Font - Font for the rendered text
        % Use str2shape() to see a list of available fonts
        Font char = 'Arial'

        % HorizontalAlignment - Horizontal alignment of the anchor point
        % Valid values: Left, Right, Center
        HorizontalAlignment char = 'Left' 

        % VerticalAlignment - Vertical alignment of the anchor point
        % Valid values: Top, Bottom, Center
        VerticalAlignment char = 'Bottom' 
    end

    properties(Dependent,SetObservable)
        % TextSize - Size of the text - Alias of the ConstantSize property
        TextSize
    end

    methods
        function obj = fvText(varargin)
            [parent,args,t] = internal.fvParse(varargin{:});
            p = inputParser;
            p.addRequired('Text',@isscalartext);
            p.KeepUnmatched = true;
            if ~mod(numel(args),2)
                % if number of arguments is even, assume no str given
                args = [{'Fast Visualization'} args];
            end
            p.parse(args{:});
            
            obj@internal.fvPrimitive(parent,'GL_TRIANGLES',[0 0 0],[1 1 0],[],nan,[],[],'Name','fvText','ConstantSizeRot','Normal');

            obj.isInit = false;
            obj.ConstantSize = 20;
            obj.Text = p.Results.Text;
            set(obj,p.Unmatched);
            obj.isInit = true;

            obj.UpdateShape;
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

        function set.TextSize(obj,sz)
            obj.ConstantSize = sz;
        end

        function sz = get.TextSize(obj)
            sz = obj.ConstantSize;
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
            t = obj.PauseUpdates;
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

