function config = studyReportConfig()
%STUDYREPORTCONFIG Default configuration for tensile-study reporting.
config.outputFolder = "results/tensile-study/report";
config.reportFilename = "report.md";
config.figureFormat = "png";
config.figureResolution = 200;
config.studyTitle = "auto";
config.includeIndividualCurves = true;
config.includePopulationCurve = true;
config.includePeakMetrics = true;
config.includeFractureMetrics = true; % compatibility alias
config.includeTangentModulus = true;
config.includeZeroReferenceDiagnostics = true;
config.closeFiguresAfterExport = true;
end