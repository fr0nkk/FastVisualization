classdef JSetGetText < handle
    %JSETGETTEXT Summary of this class goes here
    %   Detailed explanation goes here

    properties(Abstract)
        java
    end
    
    properties(Transient)
        text
    end
    
    methods
        function set.text(obj,str)
            obj.java.setText(str);
        end

        function str = get.text(obj)
            str = char(obj.java.getText);
        end
    end
end

