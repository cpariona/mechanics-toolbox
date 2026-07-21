function config = studyReportConfig()
%STUDYREPORTCONFIG Default configuration for tensile-study reporting.
config.outputFolder = "results/tensile-study/report";
config.reportFilename = "report.md";
config.figureFormat = "png";
config.figureResolution = 200;
config.includeIndividualCurves = true;
config.includePopulationCurve = true;
config.includeFractureMetrics = true;
config.closeFiguresAfterExport = true;
end
