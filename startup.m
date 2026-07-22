function startup()
%STARTUP Add mechanics-toolbox folders to the MATLAB path.
rootDir = fileparts(mfilename('fullpath'));
addpath(rootDir);
addpath(fullfile(rootDir, 'src'));
addpath(fullfile(rootDir, 'examples'));
addpath(fullfile(rootDir, 'tests'));
fprintf('mechanics-toolbox initialized from %s\n', rootDir);
end
