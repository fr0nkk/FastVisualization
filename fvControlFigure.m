classdef fvControlFigure < JChildParent & matlab.mixin.SetGet
    %FVCONTROLFIGURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Transient)
        mainGrid
        sideGrid
        collapseButton
        fvfig
        tree
        panel
        bx

        controlsVisible
        bbox = {}
        axs = {}
    end
    
    methods
        function obj = fvControlFigure()
            frame = JFrame('Title',mfilename,'Size',[850 450]);
            addlistener(frame,'ObjectBeingDestroyed',@(~,~) obj.delete);
            frame.addChild(obj);

            obj.mainGrid = JGridLayout(frame,'X',[250 10 -1],'Y',[-1 40 -1]);

            obj.collapseButton = JButton(obj.mainGrid,'Text','<','ActionFcn',@obj.toggleControlsVisible,'Constraints',JConstraints(2,2));
            obj.collapseButton.java.setBorder([]);
            obj.collapseButton.java.setFocusPainted(false);
            obj.collapseButton.java.setContentAreaFilled(false);

            obj.sideGrid = JGridLayout(obj.mainGrid,'X',-1,'Y',[175 -1],'Constraints',JConstraints(1,[1 3]));
            canvas = GLCanvas(obj.mainGrid,'GL4','Constraints',JConstraints([2 3],[1 3]));
            obj.fvfig = fvFigure(canvas);

            p = JScrollPane(obj.sideGrid,'Constraints',JConstraints(1,1));
            obj.tree = JTree(p,'RootVisible',true,'ActionFcn',@obj.TreeChanged);
            obj.tree.RootNode.Name = 'Scene';
            obj.tree.RootNode.UserData = obj.fvfig;
            
            p = JScrollPane(obj.sideGrid,'Constraints',JConstraints(1,2));
            obj.bx = JBoxLayout(p,'Axis','Y','Padding',5);
            p.java.getVerticalScrollBar().setUnitIncrement(10);

            addlistener(obj.fvfig,'MouseClicked',@obj.FigMouseClicked);

            fvPointcloud;
            fvhold(obj.fvfig,'on');
            p = fvPointcloud('Colormap','jet','Translation',[6 0 0]);
            p.Color = fvColor(struct('Z',p.Coord(:,3),'XYZ',p.Coord,'X',p.Coord(:,1)));
            m = fvMesh().Translate([-6 0 0]);
            fvLine(m);
            fvhold(obj.fvfig,'off');
            % fvSurf;

            obj.UpdateTree;

            frame.refresh;
        end

        function UpdateTree(obj)
            arrayfun(@delete,obj.tree.nodes(2:end));
            cellfun(@(c) addToTree(obj.tree,c),obj.fvfig.validateChilds('internal.fvDrawable'));
        end

        function TreeChanged(obj,src,evt)
            node = evt.data;
            % node = obj.tree.SelectedNodes;
            temp = obj.fvfig.PauseUpdates;
            cellfun(@delete,obj.bbox);
            % cellfun(@delete,obj.axs);
            state = fvhold(obj.fvfig,'on');
            obj.bbox = arrayfun(@(c) fvBoundingBox(c.UserData,[]),node,'Uni',0);
            % obj.axs = cellfun(@(c) fvAxes(c.data,'UIHidden',true,'ConstantSize',false),node,'Uni',0);
            fvhold(obj.fvfig,state);
            % delete(temp)

            cellfun(@delete,obj.bx.child);
            
            obj.bx.parent.java.setVisible(false);
            if isscalar(node)
                node.UserData.ui(obj.bx);
            end
            obj.bx.parent.java.setVisible(true);

            obj.bx.refresh;
        end

        function TreeKeyPressed(obj,src,evt)
            if evt.getKeyCode == evt.VK_DELETE
                node = obj.tree.getSelected;
                if isscalar(node) && node{1}.java.isRoot
                    node{1}.data.Reset;
                else
                    cellfun(@(c) delete(c.data),node);
                end
            end
            
        end

        function FigMouseClicked(obj,src,evt)
            if evt.java.getButton ~= evt.java.BUTTON1, return, end
            o = evt.data.object;
            if isempty(o)
                obj.tree.SelectedNodes = [];
            else
                tf = arrayfun(@(c) eq(c.UserData,o),obj.tree.nodes);
                obj.tree.SelectedNodes = obj.tree.nodes(tf);
            end
        end

        function tf = get.controlsVisible(obj)
            tf = obj.mainGrid.X(1) > 0;
        end

        function set.controlsVisible(obj,tf)
            if tf
                obj.collapseButton.Text = '<';
                obj.mainGrid.X(1) = 250;
            else
                obj.collapseButton.Text = '>';
                obj.mainGrid.X(1) = 0;
            end
        end

        function toggleControlsVisible(obj,~,~)
            obj.controlsVisible = ~obj.controlsVisible;
            obj.mainGrid.refresh;
        end
        
        function delete(obj)
            cellfun(@delete,obj.bbox);
            cellfun(@delete,obj.axs);
            jf = obj.parent;
            if isvalid(jf) && isa(jf,'JFrame')
                delete(jf);
            end
        end
    end
end

function addToTree(parentNode,fv)
    node = JTreeNode(parentNode,'Name',fv.Name,'UserData',fv);
    addlistener(fv,'ObjectBeingDestroyed',@(~,~) delete(node));
    addlistener(fv,'Name','PostSet',@(~,evt) changeNodeName(node,fv));
    C = fv.validateChilds('internal.fvDrawable');
    tf = cellfun(@(c) c.UIHidden,C);
    cellfun(@(c) addToTree(node,c),C(~tf));
end

function changeNodeName(node,fv)
    if ~strcmp(fv.Name,node.Name)
        % x = node.Tree.SelectedNodes;
        node.Name = fv.Name;
        % node.Tree.SelectedNodes = x;
    end
end

