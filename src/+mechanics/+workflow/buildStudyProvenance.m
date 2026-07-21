function provenance = buildStudyProvenance(filename, analysis)
%BUILDSTUDYPROVENANCE Record reproducibility metadata.
arguments
    filename (1,1) string
    analysis (1,1) struct
end

info = dir(filename);
provenance.sourceFile = filename;
provenance.sourceFileName = string(info.name);
provenance.sourceFileBytes = info.bytes;
provenance.sourceFileModifiedAt = datetime(info.datenum, ...
    "ConvertFrom", "datenum");
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
