function manifest = readBatchManifest(filename)
%READBATCHMANIFEST Read and validate a specimen batch manifest.
arguments
    filename (1,1) string
end

if ~isfile(filename)
    error("mechanics:io:ManifestNotFound", ...
        "Batch manifest does not exist: %s", filename);
end

[~, ~, extension] = fileparts(filename);
extension = lower(string(extension));

switch extension
    case {".xlsx", ".xls", ".xlsm"}
        manifest = readtable(filename, "VariableNamingRule", "preserve");
    case {".csv", ".txt"}
        manifest = readtable(filename, "VariableNamingRule", "preserve");
    otherwise
        error("mechanics:io:UnsupportedManifestType", ...
            "Unsupported manifest file type: %s", extension);
end

manifest = mechanics.workflow.validateBatchManifest(manifest);
end
