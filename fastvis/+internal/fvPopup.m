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
            % obj.mainMenu = JPopupMenu;
            % obj.worldCoordButton = obj.mainMenu.add(JMenuItem('world_xyz'));
            % obj.objectButton = obj.mainMenu.add(JMenu('object'));
            % obj.cameraButton = obj.mainMenu.add(JMenu('Camera'));
            % obj.camMenu.reset = obj.cameraButton.add(JMenuItem('Reset',@(~,~) fvfig.ResetCamera));
            % obj.camMenu.get = obj.cameraButton.add(JMenuItem('Get',@(~,~) assignans(fvfig.Camera)));
            % obj.camMenu.proj = obj.cameraButton.add(JMenu('Projection'));
            % obj.camMenu.persp = obj.camMenu.proj.add(JMenuItem('Perspective',@(~,~) set(fvfig.Camera,'Perspective',true)));
            % obj.camMenu.ortho = obj.camMenu.proj.add(JMenuItem('Orthographic',@(~,~) set(fvfig.Camera,'Perspective',false)));
            obj.mainMenu = JPopupMenu;
            obj.worldCoordButton = JMenuItem(obj.mainMenu,'Text','world_xyz');
            obj.objectButton = JMenu(obj.mainMenu,'Text','object');
            obj.cameraButton = JMenu(obj.mainMenu,'Text','Camera');
            obj.camMenu.reset = JMenuItem(obj.cameraButton,'Text','Reset','ActionFcn',@(~,~) fvfig.ResetCamera);
            obj.camMenu.get = JMenuItem(obj.cameraButton,'Text','Get','ActionFcn',@(~,~) assignans(fvfig.Camera));
            obj.camMenu.proj = JMenu(obj.cameraButton,'Text','Projection');
            obj.camMenu.persp = JMenuItem(obj.camMenu.proj,'Text','Perspective','ActionFcn',@(~,~) set(fvfig.Camera,'Perspective',true));
            obj.camMenu.ortho = JMenuItem(obj.camMenu.proj,'Text','Orthographic','ActionFcn',@(~,~) set(fvfig.Camera,'Perspective',false));
        end
        
        function show(obj,evt)
            cellfun(@delete,obj.objectButton.child);
            isOnObject = ~isempty(evt.data.object);
            obj.worldCoordButton.Text = obj.CoordText(evt.data.xyz,'world');
            obj.worldCoordButton.ActionFcn = @(~,~) assignans(evt.data.xyz);
            if isOnObject
                o = evt.data.object;
                obj.objectButton.Text = o.Name;

                o.RightClickMenu(o,obj.objectButton,evt);
                % cellfun(@(c) obj.objectButton.add(c),m);
            end
            obj.objectButton.java.setVisible(isOnObject);

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

