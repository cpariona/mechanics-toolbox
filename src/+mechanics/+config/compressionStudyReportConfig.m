function config = compressionStudyReportConfig()
%COMPRESSIONSTUDYREPORTCONFIG Default compression-study report configuration.
config.outputFolder = "results/compression-study/report";
config.reportFilename = "report.md";
config.figureFormat = "png";
config.figureResolution = 200;
config.studyTitle = "auto";
config.includeCycleOverview = true;
config.includeSelectedBranch = true;
config.includeTangentModulus = true;
config.closeFiguresAfterExport = true;
end