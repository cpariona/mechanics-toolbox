%EXPORT_ECOFLEX_STUDY_REPORT Export figures and Markdown report.
startup;

if ~exist("study", "var")
    run_ecoflex_tensile_study;
end

reportConfig = mechanics.config.studyReportConfig();
reportConfig.outputFolder = ...
    "results/ecoflex-0050/report";

reportFiles = mechanics.io.exportTensileStudyReport( ...
    study, reportConfig);

disp(reportFiles);
