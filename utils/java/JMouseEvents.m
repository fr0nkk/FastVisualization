classdef JMouseEvents < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % parent
        clickTolerance = 1;
    end

    events
        Pressed
        Released
        Clicked
        Dragged
        WheelMoved
        Moved
    end

    properties(Access=protected)
        mousePressOrigin = nan(3,2);
        btnMask
    end
    
    methods
        function obj = JMouseEvents(parent)
            % obj.parent = parent;
            parent.setCallback('MousePressed',@obj.MousePressedCallback);
            parent.setCallback('MouseReleased',@obj.MouseReleasedCallback);
            parent.setCallback('MouseDragged',@obj.MouseDraggedCallback);
            parent.setCallback('MouseWheelMoved',@obj.MouseWheelMovedCallback);
            parent.setCallback('MouseMoved',@obj.MouseMovedCallback);
        end

        function MousePressedCallback(obj,src,evt)
            b = evt.getButton;
            obj.mousePressOrigin(b,:) = jevt2coords(evt,1);
            notify(obj,'Pressed',javaevent(evt));
        end

        function MouseReleasedCallback(obj,src,evt)
            b = evt.getButton;
            data.dxy = jevt2coords(evt,1) - obj.mousePressOrigin(b,:);
            obj.mousePressOrigin(b,:) = [nan nan];
            notify(obj,'Released',javaevent(evt,data));
            if all(abs(data.dxy) <= obj.clickTolerance)
                notify(obj,'Clicked',javaevent(evt));
            end
        end

        function MouseDraggedCallback(obj,src,evt)
            data.buttonMask = obj.getButtonMask(evt);
            data.dxy = jevt2coords(evt,1) - obj.mousePressOrigin;
            notify(obj,'Dragged',javaevent(evt,data));
        end

        function MouseWheelMovedCallback(obj,src,evt)
            notify(obj,'WheelMoved',javaevent(evt));
        end

        function MouseMovedCallback(obj,src,evt)
            notify(obj,'Moved',javaevent(evt));
        end
    end
    methods(Access=protected)
        function msk = getButtonMask(obj,evt)
            if isempty(obj.btnMask)
                obj.btnMask = [evt.BUTTON1_DOWN_MASK evt.BUTTON2_DOWN_MASK evt.BUTTON3_DOWN_MASK]';
            end
            msk = logical(bitand(obj.btnMask,evt.getModifiersEx));
        end
    end
end

