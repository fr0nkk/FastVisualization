classdef fvConfig < handle

    properties(SetAccess = protected, SetObservable)
        cfg
    end

    methods
        function obj = fvConfig(varargin)
            persistent p % singleton
            if isempty(p)
                obj.Read(varargin{:});
                p = obj;
            else
                obj = p;
            end
        end

        function Read(obj,source,decoder)
            if nargin < 2, source = 'fvConfig.json'; end
            if nargin < 3, decoder = @(src) jsondecode(fileread(src)); end
            obj.cfg = decoder(source);
        end

        function varargout = subsref(obj,s)
            if ismember(s(1).subs,{'Read','cfg'})
                [varargout{1:nargout}] = builtin('subsref',obj,s);
            else
                [varargout{1:nargout}] = subsref(obj.cfg,s);
            end
        end
    end
end

