function d = execdir(non_deployed_dir,varargin)

% non_deployed_dir : base directory when not deployed
% otherwise, non_deployed_dir will be the executable location

% https://www.mathworks.com/matlabcentral/answers/92949-how-can-i-find-the-directory-containing-my-compiled-application
if isdeployed % Stand-alone mode.
    [status, result] = system('path');
    base_dir = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
else % MATLAB mode.
    base_dir = non_deployed_dir;
end

d = fullfile(base_dir,varargin{:});

end
