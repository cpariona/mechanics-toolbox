function dataset = extractGenericTableWorkbook(filename, config)
%EXTRACTGENERICTABLEWORKBOOK Adapt one generic table to the dataset contract.
arguments
    filename (1,1) string
    config (1,1) struct
end

importConfig = mechanics.config.excelImportConfig();
importConfig.sheet = config.generic.sheet;
importConfig.dataRange = config.generic.dataRange;
importConfig.specimenId = config.generic.specimenId;

specimen = mechanics.io.readSpecimenTable(filename, importConfig);
specimen.sheetName = string(config.generic.sheet);
specimen.testType = "tension";
specimen.geometry.initialLength = config.generic.initialLength;
specimen.geometry.initialArea = config.generic.initialArea;

dataset.source.filename = filename;
dataset.source.sheetNames = string(config.generic.sheet);
dataset.specimens = specimen;
dataset.metadata.specimenCount = 1;
dataset.metadata.extractedAt = datetime("now");
dataset.metadata.configuration = config;
end
