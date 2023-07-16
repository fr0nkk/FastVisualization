classdef (Abstract) fvChild < JChildParent & internal.fvSaveLoad
%FVCHILD
    
    properties(Transient,Hidden)
        isInit = false
    end

    properties(SetAccess=protected)
        % fvfig - fvFigure which contains this object
        fvfig fvFigure
    end
    
    methods
        function obj = fvChild(ax)
            if isempty(ax)
                ax = gcfv;
            end
            while ~isa(ax,'fvFigure')
                ax = ax.parent;
            end
            obj.fvfig = ax;
        end

        function [gl,temp] = getContext(obj)
            [gl,temp] = obj.fvfig.getContext;
        end

        function Update(obj)
            if ~obj.isInit, return, end
            obj.fvfig.Update;
        end

        function temp = UpdateOnCleanup(obj)
            if obj.isInit
                temp = obj.fvfig.UpdateOnCleanup;
            else
                temp = [];
            end
        end

        function C = validateChilds(obj,desiredClass)
            C = obj.validateChilds@JChildParent;
            if nargin >= 2
                C = C(cellfun(@(c) isa(c,desiredClass),C));
            end
        end

        function fvclear(obj)
            t = obj.UpdateOnCleanup;
            cellfun(@delete,obj.child);
            obj.Update;
        end

        function clear(obj)
            obj.fvclear;
        end

        function delete(obj)
            try
                obj.fvclear;
            catch
            end
        end
    end

end

