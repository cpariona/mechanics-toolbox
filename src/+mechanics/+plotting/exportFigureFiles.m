function imageFile = exportFigureFiles(figureHandle, folder, baseName, format, resolution)
%EXPORTFIGUREFILES Export one figure as an image and editable MATLAB FIG.
arguments
    figureHandle (1,1) matlab.ui.Figure
    folder (1,1) string
    baseName (1,1) string
    format (1,1) string
    resolution (1,1) double {mustBePositive}
end

if ~isfolder(folder)
    mkdir(folder);
end

format = lower(strtrim(format));
if startsWith(format, ".")
    format = extractAfter(format, 1);
end
if strlength(format) == 0
    error("mechanics:plotting:EmptyFigureFormat", ...
        "Figure format must be nonempty.");
end

imageFile = string(fullfile(folder, baseName + "." + format));
figureFile = string(fullfile(folder, baseName + ".fig"));

exportgraphics(figureHandle, imageFile, "Resolution", resolution);
savefig(figureHandle, figureFile);
end
