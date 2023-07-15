classdef JPopupMenu < JComponent
    
    properties(Constant)
        isEDT = false
        JClass = 'javax.swing.JPopupMenu'
    end
    
    methods
        function show(obj,arg1,xy)
            % arg1 can be evt or java component
            if nargin < 3
                % no xy, arg1 must be event
                xy = jevt2coords(arg1,0);
                arg1 = arg1.java.getComponent;
            end
            if ~isjava(arg1)
                arg1 = arg1.java;
            end
            obj.java.show(arg1,xy(1),xy(2))
        end
        
    end
end

