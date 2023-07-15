classdef JActionnable < handle
    
    properties
        ActionFcn
    end

    methods(Abstract)
        setCallback(obj,cb)
    end
    
    methods
        function obj = JActionnable()
            obj.setCallback('ActionPerformed',@obj.ActionTrigger);
        end

        function ActionTrigger(obj,src,evt)
            if isempty(obj.ActionFcn) || obj.ActionFilter(evt), return, end
            obj.ActionFcn(obj,evt);
        end

        function doCancel = ActionFilter(obj,evt)
            % overload if canceling is necessary in case of multiple triggers
            % see JComboBox
            doCancel = false;
        end


    end
end

