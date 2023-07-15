classdef JAbstractButton < JComponent & JSetGetText & JActionnable
    
    properties

    end
    
    methods
        function obj = JAbstractButton(args,callback)
            if nargin < 1 || isempty(args)
                args = mfilename;
            end
            if ~iscell(args)
                args = {args};
            end
            obj@JComponent(args{:});
            obj@JActionnable;
            if nargin > 1
                obj.ActionFcn = callback;
            end
        end
    end
end

