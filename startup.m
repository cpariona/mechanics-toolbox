function startup()
%STARTUP Add the maintained toolbox implementation to the MATLAB path.
rootDir = fileparts(mfilename('fullpath'));
addpath(rootDir);
addpath(fullfile(rootDir, 'src'));
fprintf('mechanics-toolbox initialized from %s\n', rootDir);
end