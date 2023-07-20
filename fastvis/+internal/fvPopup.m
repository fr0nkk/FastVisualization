classdef fvPopup < handle
    
    properties
        mainMenu
        worldCoordButton
        objectButton
        current
    end
    
    methods
        function obj = fvPopup()
            obj.mainMenu = JPopupMenu;
            obj.worldCoordButton = obj.mainMenu.add(JMenuItem('base_xyz',@(~,~) obj.ToBase('xyz')));
            obj.objectButton = obj.mainMenu.add(JMenu('object'));
        end
        
        function show(obj,evt)
            obj.current = evt;
            obj.worldCoordButton.text = obj.CoordText(obj.current.data.xyz,'world');
            o = evt.data.object;
            obj.objectButton.text = o.Name;
            cellfun(@delete,obj.objectButton.child);
            m = o.RightClickMenu(o,evt);
            cellfun(@(c) obj.objectButton.add(c),m);
            obj.mainMenu.show(evt);
        end

        function ToBase(obj,val)
            assignans(obj.current.data.(val));
        end
    end
    methods(Static)
        function str = CoordText(x,type)
            x = arrayfun(@(a) sprintf('%.3f',a),x,'uni',0);
            str = ['(' strjoin(x,',') ') ' type];
        end
    end
end

