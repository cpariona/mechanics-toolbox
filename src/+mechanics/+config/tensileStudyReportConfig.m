function config = tensileStudyReportConfig()
%TENSILESTUDYREPORTCONFIG Default tensile-study report configuration.
config.outputFolder = "results/tensile-study/report";
config.reportFilename = "report.md";
config.figureFormat = "png";
config.figureResolution = 200;
config.studyTitle = "auto";
config.includeIndividualCurves = true;
config.includePopulationCurve = true;
config.includePeakMetrics = true;
config.includeTangentModulus = true;
config.includeZeroReferenceDiagnostics = true;
config.closeFiguresAfterExport = true;
end
