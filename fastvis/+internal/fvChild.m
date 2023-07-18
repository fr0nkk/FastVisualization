classdef (Abstract) fvChild < JChildParent & matlab.mixin.SetGet
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

    methods(Hidden)
        function s = saveobj(obj)
            s = obj.fv2struct;
        end

        function s = fv2struct(obj,varargin)
            m = metaclass(obj);
            tf = [m.PropertyList.Transient] & [m.PropertyList.SetObservable];
            props = {m.PropertyList(tf).Name};
            vals = cellfun(@(p) {obj.(p)},props,'uni',0);
            args = [props ; vals];
            s = struct('class',class(obj),'varargin',{varargin},'props',struct(args{:}));
            s.child = cellfun(@saveobj,obj.child,'uni',0);
        end
    end

    methods(Static,Hidden)
        function obj = loadobj(s)
            obj = internal.fvChild.struct2fv(s);
        end
        
        function obj = struct2fv(s,parent)
            if nargin < 2
                parent = gcfv;
                t = parent.UpdateOnCleanup;
            end
            f = str2func(s.class);
            obj = f(parent,s.varargin{:});
            set(obj,s.props);
            cellfun(@(c) internal.fvChild.struct2fv(c,obj),s.child,'uni',0);
        end

    end

end

