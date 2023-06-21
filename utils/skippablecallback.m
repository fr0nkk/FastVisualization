classdef skippablecallback < handle
    %CALLBACKSKIPPER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fcn
        args

        isWorking = false;
        triggerNeeded = false;
    end
    
    methods
        function obj = skippablecallback(fcn)
            obj.fcn = fcn;
        end
        
        function trigger(obj,varargin)
            obj.triggerNeeded = true;
            obj.args = varargin;
            if obj.isWorking,return, end
            obj.isWorking = true;
            temp = onCleanup(@obj.EndTrigger);
            while obj.triggerNeeded
                drawnow limitrate
                obj.triggerNeeded = false;
                obj.fcn(obj.args{:});
            end
        end

        function EndTrigger(obj)
            obj.isWorking = false;
        end
    end
end

