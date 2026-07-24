function provenance = buildStudyProvenance(inputInfo, analysis)
%BUILDSTUDYPROVENANCE Record reproducibility metadata.
arguments
    inputInfo (1,1) struct
    analysis (1,1) struct
end

sourceFiles = strings(0,1);
if isfield(inputInfo,"sourceFiles")
    sourceFiles = string(inputInfo.sourceFiles(:));
end
sourceFileName = strings(numel(sourceFiles),1);
sourceFileBytes = nan(numel(sourceFiles),1);
sourceFileModifiedAt = NaT(numel(sourceFiles),1);
for index = 1:numel(sourceFiles)
    if ~isfile(sourceFiles(index))
        continue;
    end
    info = dir(sourceFiles(index));
    sourceFileName(index) = string(info.name);
    sourceFileBytes(index) = info.bytes;
    sourceFileModifiedAt(index) = datetime(info.datenum, ...
        "ConvertFrom", "datenum");
end

provenance.inputType = string(inputInfo.type);
provenance.sourceFiles = sourceFiles;
provenance.sourceFileNames = sourceFileName;
provenance.sourceFileBytes = sourceFileBytes;
provenance.sourceFileModifiedAt = sourceFileModifiedAt;

% Preserve the original single-source fields for downstream consumers.
provenance.sourceFile = "";
provenance.sourceFileName = "";
if ~isempty(sourceFiles)
    provenance.sourceFile = sourceFiles(1);
    provenance.sourceFileName = sourceFileName(1);
end

provenance.matlabVersion = string(version);
provenance.matlabRelease = string(version("-release"));
provenance.platform = string(computer);
provenance.createdAt = datetime("now");

provenance.specimenCount = height(analysis.summary);
provenance.processedSpecimenCount = ...
    nnz(analysis.summary.Status == "processed");
provenance.qualityFailedSpecimenCount = ...
    nnz(analysis.summary.Status == "quality-failed");
provenance.failedSpecimenCount = ...
    nnz(analysis.summary.Status == "failed");
end
