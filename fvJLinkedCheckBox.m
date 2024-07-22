classdef fvJLinkedCheckBox < JCheckBox
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
        function obj = fvJLinkedCheckBox(parent,object,property,varargin)
            obj@JCheckBox(parent,'Text','',varargin{:});
            obj.ActionFcn = @obj.ValueChanged;
            obj.object = object;
            property = cellstr(property);
            obj.property = property{1};
            obj.UpdateValue;

            obj.el = listener(object,property,'PostSet',@(~,~) obj.UpdateValue);
        end

        function ValueChanged(obj,src,evt)
            obj.object.(obj.property) = obj.Value;
        end

        function UpdateValue(obj)
            x = obj.object.(obj.property);
            obj.SilentSetValue(x);
        end
    end
end

