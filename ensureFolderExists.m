function ensureFolderExists(folderPath)
% Creates a folder if it does not already exist.
%
% Inputs:
%   folderPath - Folder path to check or create.
%
% Outputs:
%   Creates the folder if needed.

    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end
end