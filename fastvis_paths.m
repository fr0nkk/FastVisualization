function out = fastvis_paths(addFlag)
% add or remove necessary paths when not using as a toolbox

if nargin < 1, addFlag = true; end

if addFlag
    matoglCheck('3.1.2');
end

pathList = {
    'fastvis'
    'utils'
    'obj'
    fullfile('utils','java')
    };

if addFlag
    func = @addpath;
else
    func = @rmpath;
end

rootDir = fileparts(mfilename('fullpath'));

fullPathList = fullfile(rootDir,pathList);

cellfun(func,fullPathList);

if nargout >= 1, out = fullPathList; end

end

function matoglCheck(minVersion)

try
    matogl_id = 'fe3f503f-9f2c-425b-8ba1-c290ca01c4a3';
    s = matlab.addons.toolbox.installedToolboxes;
    if ~isempty(s)
        s = s(strcmp({s.Name},'matogl'));
    end
    
    % check if installed
    addonLink = "<a href=""matlab:matlab.internal.language.introspective.showAddon('" + matogl_id + "')"">Add-On Explorer</a>";
    if isempty(s)
        error('matogl:notInstalled','Fast Visualization toolbox requires matogl. %s',addonLink);
    end
    
    % check against multiple installs
    if numel(s) > 1
        error('matogl:multipleInstallations','Multiple matogl installed, ensure only the latest is installed')
    end
    
    % check version
    curVersion = str2double(strsplit(s.Version,'.'));
    neededVersion = str2double(strsplit(minVersion,'.'));
    ver2abs = @(x) int32(sum(x .* 10.^([4 2 0]))); % [1 2 3] -> 010203 -- good for versions up to 99
    if ver2abs(curVersion(1:3)) < ver2abs(neededVersion)
        error('matogl:wrongVersion','matogl version must be at least %s - %s\n(Click the version in the toolbox page, top left)',minVersion,addonLink)
    end

    % check enabled
    if ~matlab.addons.isAddonEnabled(matogl_id)
        cmd = "matlab.addons.enableAddon('" + matogl_id + "')";
        error('matogl:notEnabled','matogl must be enabled. <a href="matlab:%s">Enable</a>',cmd);
    end

catch ME
    if startsWith(ME.identifier,'matogl:')
        throwAsCaller(ME)
    else
        str = getReport(ME,"basic");
        warning('%s\n\n matogl check failed. Ensure matogl toolbox version %s is installed',str,minVersion);
    end
end

end



