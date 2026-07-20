function validateRawCurve(rawCurve)
%VALIDATERAWCURVE Validate the minimum raw-curve contract.
arguments
    rawCurve (1,1) struct
end
requiredFields = ["force", "displacement"];
for fieldName = requiredFields
    if ~isfield(rawCurve, fieldName)
        error("mechanics:io:MissingField", "rawCurve.%s is required.", fieldName);
    end
end
force = rawCurve.force(:);
displacement = rawCurve.displacement(:);
if numel(force) ~= numel(displacement)
    error("mechanics:io:SizeMismatch", "Force and displacement must have equal lengths.");
end
if isempty(force)
    error("mechanics:io:EmptyCurve", "The raw curve cannot be empty.");
end
end
