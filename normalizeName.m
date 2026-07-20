function out = normalizeName(name)
% Normalizes a variable name for robust matching.
%
% Inputs:
%   name - Input variable name.
%
% Outputs:
%   out - Normalized variable name.

    out = lower(string(name));
    out = erase(out, " ");
    out = erase(out, "_");
    out = erase(out, "-");
    out = erase(out, ".");
    out = char(out);
end