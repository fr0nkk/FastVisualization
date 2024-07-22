classdef fvJLinkedNumericField < JGridLayout
    %FVLINKEDVALUE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Transient)
        Value
        jcomp
        object
        property
        DragStep = 1;
    end

    properties(Access=private)
        el
        v0
        x0
        iDragStep = 1;
    end
    
    methods
        function obj = fvJLinkedNumericField(parent,object,property,varargin)
            obj@JGridLayout(parent,varargin{:});
            obj.object = object;
            property = cellstr(property);
            obj.property = property{1};
            v = obj.Value;
            
            P = metaclass(object).PropertyList;
            P = P(strcmp(property{1},{P.Name}));
            F = P.Validation.ValidatorFunctions;
            F = cellfun(@func2str,F,'uni',0);

            args = struct;
            args.SelectOnFocus = true;

            tf = contains(F,'mustBeNonnegative');
            if any(tf)
                args.Limits = [0 inf];
            end

            tf = contains(F,'mustBePositive');
            if any(tf)
                args.Limits = [eps inf];
            end

            tf = contains(F,'mustBeInRange');
            if any(tf)
                str = regexp(F{tf},'(?<=mustBeInRange\().*?(?=\))','match','once');
                str = strsplit(str,',');
                args.Limits = str2double(str(2:end));
            end

            tf = contains(F,'mustBeInteger');
            if any(tf)
                args.RoundStep = 1;
            end


            obj.Y = -1;
            obj.X = -ones(1,numel(v));
            
            n = numel(v);
            obj.jcomp = arrayfun(@(a) JNumericField(obj,'Value',v(a),'Constraints',JConstraints(a,1)),1:n);
            for i=1:n
                set(obj.jcomp(i),args);
                obj.jcomp(i).ActionFcn = @obj.ValueChanged;

                obj.jcomp(i).addJEvents({'MouseDragged','MousePressed'});
                addlistener(obj.jcomp(i),'MouseDragged',@obj.MouseDrag);
                addlistener(obj.jcomp(i),'MousePressed',@obj.MousePress);
            end
            obj.el = listener(object,property,'PostSet',@(~,~) obj.UpdateValue);
        end

        function ValueChanged(obj,src,evt)
            obj.SetObjectValue([obj.jcomp.Value]);
        end

        function v = get.Value(obj)
            v = obj.object.(obj.property);
        end

        function UpdateValue(obj)
            v = obj.Value;
            for i=1:numel(v)
                obj.jcomp(i).SilentSetValue(v(i));
            end
        end

        function set.Value(obj,v)
            obj.SetObjectValue(v);
        end

        function SetObjectValue(obj,v)
            obj.object.(obj.property) = v;
        end

        function MouseDrag(obj,src,evt)
            if ~bitand(evt.java.getModifiersEx,evt.java.BUTTON3_DOWN_MASK), return, end
            xy = jevt2coords(evt,1);
            dx = obj.x0 - xy(2);
            if abs(dx) < 5, dx = 0; end
            src.Value = obj.v0 + dx .* obj.iDragStep;
        end

        function MousePress(obj,src,evt)
            if evt.java.getButton ~= evt.java.BUTTON3, return, end
            obj.v0 = src.Value;
            xy = jevt2coords(evt,1);
            obj.x0 = xy(2);
            if isnumeric(obj.DragStep)
                obj.iDragStep = obj.DragStep;
            else
                obj.iDragStep = obj.DragStep(obj.object);
            end
        end
    end
end

