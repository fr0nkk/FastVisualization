function varargout = fvhold(varargin)
%FVHOLD Shortcut to the current fvFigure's hold function
% fvhold on - hold the current fvFigure
% fvhold off - unhold the current fvFigure
% output is the state before hold or unhold

a = gcfv;
[varargout{1:nargout}] = a.fvhold(varargin{:});
end
