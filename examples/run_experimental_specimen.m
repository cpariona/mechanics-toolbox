%RUN_EXPERIMENTAL_SPECIMEN Import and process one real specimen.
startup;

filename = "path/to/specimen.xlsx";

importConfig = mechanics.config.excelImportConfig();
importConfig.sheet = 1;
importConfig.forceColumns = ["Force_N", "Force", "Load_N"];
importConfig.displacementColumns = [ ...
    "Displacement_mm", "Displacement", "Extension_mm"];
importConfig.specimenId = "specimen-01";

specimen = mechanics.io.readSpecimenTable(filename, importConfig);

geometry.initialLength = 25;
geometry.initialArea = 6 * 2;

processingConfig = mechanics.config.tensionConfig();

specimen = mechanics.workflow.processUniaxialSpecimen( ...
    specimen, geometry, processingConfig);

mechanics.plotting.plotStressStrain(specimen.processed);

outputFiles = mechanics.io.exportSpecimenResults( ...
    specimen, "results/specimen-01");

disp(outputFiles);
