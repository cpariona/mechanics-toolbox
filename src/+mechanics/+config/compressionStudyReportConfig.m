function config = compressionStudyReportConfig()
%COMPRESSIONSTUDYREPORTCONFIG Default compression-study report configuration.
config.outputFolder = "results/compression-study/report";
config.reportFilename = "report.md";
config.figureFormat = "png";
config.figureResolution = 200;
config.studyTitle = "auto";

% Single-specimen report content.
config.includeCycleOverview = true;
config.includeSelectedBranch = true;

% Multi-specimen report content.
config.includeIndividualCurves = true;
config.includePopulationCurve = true;
config.includePopulationTangentModulus = true;
config.includeCycleDiagnostics = true;

% Shared content.
config.includeTangentModulus = true;
config.closeFiguresAfterExport = true;
end
