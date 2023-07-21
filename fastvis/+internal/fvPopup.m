classdef fvPopup < handle
    
    properties
        mainMenu
        worldCoordButton
        objectButton
        cameraButton
        camMenu
    end
    
    methods
        function obj = fvPopup(fvfig)
            obj.mainMenu = JPopupMenu;
            obj.worldCoordButton = obj.mainMenu.add(JMenuItem('world_xyz'));
            obj.objectButton = obj.mainMenu.add(JMenu('object'));
            obj.cameraButton = obj.mainMenu.add(JMenu('Camera'));
            obj.camMenu.reset = obj.cameraButton.add(JMenuItem('Reset',@(~,~) fvfig.ResetCamera));
            obj.camMenu.get = obj.cameraButton.add(JMenuItem('Get',@(~,~) assignans(fvfig.Camera)));
            obj.camMenu.proj = obj.cameraButton.add(JMenu('Projection'));
            obj.camMenu.persp = obj.camMenu.proj.add(JMenuItem('Perspective',@(~,~) set(fvfig.Camera,'Projection','Perspective')));
            obj.camMenu.ortho = obj.camMenu.proj.add(JMenuItem('Orthographic',@(~,~) set(fvfig.Camera,'Projection','Orthographic')));
        end
        
        function show(obj,evt)
            cellfun(@delete,obj.objectButton.child);
            isOnObject = ~isempty(evt.data);
            if isOnObject
                obj.worldCoordButton.text = obj.CoordText(evt.data.xyz,'world');
                obj.worldCoordButton.ActionFcn = @(~,~) assignans(evt.data.xyz);
                o = evt.data.object;
                obj.objectButton.text = o.Name;
                m = o.RightClickMenu(o,evt);
                cellfun(@(c) obj.objectButton.add(c),m);
            end
            obj.objectButton.java.setVisible(isOnObject);
            obj.worldCoordButton.java.setVisible(isOnObject);

            obj.mainMenu.show(evt);
        end
    end
    methods(Static)
        function str = CoordText(x,type)
            x = arrayfun(@(a) sprintf('%.3f',a),x,'uni',0);
            str = ['(' strjoin(x,',') ') ' type];
        end
    end
end

