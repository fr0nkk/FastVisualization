classdef (Abstract) fvSaveLoad < handle & matlab.mixin.SetGet

    properties(Abstract)
        child
    end

    methods(Hidden)
        function s = saveobj(obj)
            m = metaclass(obj);
            tf = [m.PropertyList.Transient] & [m.PropertyList.SetObservable];
            props = {m.PropertyList(tf).Name};
            vals = cellfun(@(p) {obj.(p)},props,'uni',0);
            args = [props ; vals];
            s = struct('fcn',str2func(class(obj)),'props',struct(args{:}));
            s.child = cellfun(@saveobj,obj.child,'uni',0);
        end
    end

    methods(Static,Hidden)
        function obj = loadobj(s)
            obj = struct2obj(s);
        end
    end

end

function obj = struct2obj(s,parent)
    if nargin < 2
        parent = gcfv;
        t = parent.UpdateOnCleanup;
    end
    obj = s.fcn(parent);
    set(obj,s.props);
    cellfun(@(c) struct2obj(c,obj),s.child,'uni',0);
end
