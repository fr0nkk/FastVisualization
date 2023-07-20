classdef (Abstract) fvChild < JChildParent & matlab.mixin.SetGet
%FVCHILD

    properties(Hidden,Transient,SetObservable)
        RightClickMenu = @internal.fvChild.Menu
    end
    
    properties(Transient,Hidden)
        isInit = false
    end

    properties(SetAccess=protected)
        % fvfig - fvFigure which contains this object
        fvfig fvFigure
    end

    properties(Hidden)
        fvSave logical = true;
    end
    
    methods
        function obj = fvChild(parent)
            parent.addChild(obj);
            while ~isa(parent,'fvFigure')
                parent = parent.parent;
            end
            obj.fvfig = parent;
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
            tf = cellfun(@(c) c.fvSave,obj.child);
            s.child = cellfun(@saveobj,obj.child(tf),'uni',0);
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

        function m = Menu(obj,evt)
            m = {
                JMenuItem('get',@(~,~) assignans(obj));
                JMenuItem('delete',@(~,~) delete(obj));
                };
        end

    end

end

