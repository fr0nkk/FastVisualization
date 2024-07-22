classdef fvJLinkedComboBox < JComboBox
    %FVLINKEDVALUE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Transient)
        object
        property
    end

    properties(Access=private)
        el
    end
    
    methods
        function obj = fvJLinkedComboBox(parent,object,property,varargin)
            obj@JComboBox(parent,varargin{:});
            obj.ActionFcn = @obj.ValueChanged;
            obj.object = object;
            property = cellstr(property);
            obj.property = property{1};
            obj.UpdateValue;

            obj.el = listener(object,property,'PostSet',@(~,~) obj.UpdateValue);
        end

        function ValueChanged(obj,src,evt)
            obj.object.(obj.property) = obj.ValueData;
        end

        function UpdateValue(obj)
            x = obj.object.(obj.property);
            if ~isempty(obj.ItemsData)
                tf = cellfun(@(y) isequaln(x,y),obj.ItemsData);
                if ~any(tf)
                    error('Invalid ValueData')
                end
                x = obj.Items{find(tf,1)};
            end

            obj.SilentSetValue(x);
        end
    end
end

