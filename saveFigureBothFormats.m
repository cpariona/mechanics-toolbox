function saveFigureBothFormats(figHandle, saveFolder, fileName)
% Saves a MATLAB figure in .fig and .tif formats.
% The TIFF file is exported at 300 dpi.
%
% Inputs:
%   figHandle  - Handle to the figure.
%   saveFolder - Folder where the figure is saved.
%   fileName   - File name without extension.
%
% Outputs:
%   Saves .fig and .tif files.

    ensureFolderExists(saveFolder);

    savefig(figHandle, fullfile(saveFolder, [fileName '.fig']));

    exportgraphics(figHandle, fullfile(saveFolder, [fileName '.tif']), ...
        'Resolution', 300);
end