classdef fvPopup < handle
    
    properties
        mainMenu
        worldCoordButton
        localCoordButton
        objectButton
        deleteButton
        current
    end
    
    methods
        function obj = fvPopup()
            obj.mainMenu = JPopupMenu;
            obj.worldCoordButton = obj.mainMenu.add(JMenuItem('',@(~,~) obj.ToBase('xyz')));
            obj.localCoordButton = obj.mainMenu.add(JMenuItem('',@(~,~) obj.ToBase('xyz_local')));
            obj.objectButton = obj.mainMenu.add(JMenuItem('',@(~,~) obj.ToBase('object')));
            obj.deleteButton = obj.mainMenu.add(JMenuItem('delete',@obj.DeleteTarget));
        end
        
        function show(obj,evt)
            obj.current = evt;
            coordText = @(coord,type) ['(' strjoin(arrayfun(@(a) sprintf('%.3f',a),coord,'uni',0),',') ') ' type];
            obj.worldCoordButton.text = coordText(obj.current.data.xyz,'world');
            obj.localCoordButton.text = coordText(obj.current.data.xyz_local,'local');
            obj.objectButton.text = obj.current.data.object.Name;
            obj.mainMenu.show(evt);
        end

        function ToBase(obj,val)
            assignin('base','ans',obj.current.data.(val));
            evalin('base','ans');
        end

        function DeleteTarget(obj,src,evt)
            delete(obj.current.data.object)
        end
    end
end

