function varargout = fvhold(varargin)
%FVHOLD Shortcut to the current fvFigure's hold function
a = gcfv;
[varargout{1:nargout}] = a.fvhold(varargin{:});
end
