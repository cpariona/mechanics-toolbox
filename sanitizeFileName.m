function safeName = sanitizeFileName(fileName)
% Converts a text label into a safe file name.
%
% Inputs:
%   fileName - Input file name or label.
%
% Outputs:
%   safeName - File-system-safe name.

    safeName = char(string(fileName));
    safeName = strrep(safeName, ' ', '_');
    safeName = strrep(safeName, ':', '-');
    safeName = strrep(safeName, '/', '-');
    safeName = strrep(safeName, '\', '-');
    safeName = strrep(safeName, '[', '');
    safeName = strrep(safeName, ']', '');
    safeName = strrep(safeName, '(', '');
    safeName = strrep(safeName, ')', '');
end