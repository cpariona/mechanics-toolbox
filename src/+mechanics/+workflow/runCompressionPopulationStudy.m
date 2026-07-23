function populationStudy = runCompressionPopulationStudy(manifestInput, config)
%RUNCOMPRESSIONPOPULATIONSTUDY Analyze multiple compression specimens and groups.
arguments
    manifestInput
    config (1,1) struct = mechanics.config.compressionPopulationConfig()
end

manifest = localManifest(manifestInput, config.defaultInitialLength);
records = repmat(localEmptyRecord(), height(manifest), 1);

for index = 1:height(manifest)
    records(index).index = index;
    records(index).specimenId = manifest.SpecimenId(index);
    records(index).group = manifest.Group(index);
    records(index).file = manifest.File(index);
    if ~manifest.Include(index)
        records(index).status = "skipped";
        continue;
    end
    try
        studyConfig = config.studyConfig;
        studyConfig.import.specimenId = manifest.SpecimenId(index);
        studyConfig.geometry.initialLength = manifest.InitialLength(index);
        studyConfig.geometry.initialArea = manifest.InitialArea(index);
        studyConfig.export.enabled = false;
        study = mechanics.workflow.runCompressionStudy( ...
            manifest.File(index), studyConfig);
        records(index).status = "processed";
        records(index).study = study;
    catch ME
        records(index).status = "failed";
        records(index).errorIdentifier = string(ME.identifier);
        records(index).errorMessage = string(ME.message);
        if ~config.continueOnError
            rethrow(ME);
        end
    end
end

summary = localSummary(records);
groups = unique(manifest.Group, "stable");
groupResults = repmat(struct("name", "", "specimenCount", 0, ...
    "curves", struct(), "metrics", table(), "status", "insufficient"), ...
    numel(groups), 1);
for groupIndex = 1:numel(groups)
    groupName = groups(groupIndex);
    mask = string({records.status})' == "processed" & ...
        string({records.group})' == groupName;
    selected = records(mask);
    groupResults(groupIndex).name = groupName;
    groupResults(groupIndex).specimenCount = numel(selected);
    if numel(selected) < config.minimumSpecimensPerGroup
        continue;
    end
    specimens = arrayfun(@(r) r.study.specimen, selected);
    groupResults(groupIndex).curves = ...
        mechanics.statistics.aggregateStressStrain(specimens, config.population);
    groupResults(groupIndex).metrics = localMetricTable(selected);
    groupResults(groupIndex).status = "processed";
end

populationStudy.manifest = manifest;
populationStudy.records = records;
populationStudy.summary = summary;
populationStudy.groups = groupResults;
populationStudy.config = config;
populationStudy.createdAt = datetime("now");

if config.export.enabled
    folder = string(config.export.outputFolder);
    if ~isfolder(folder)
        mkdir(folder);
    end
    summaryFile = fullfile(folder, "compression_population_summary.csv");
    writetable(summary, summaryFile);
    populationStudy.outputFiles.summary = string(summaryFile);
    for groupIndex = 1:numel(groupResults)
        if groupResults(groupIndex).status ~= "processed"
            continue;
        end
        safeName = regexprep(groupResults(groupIndex).name, "[^A-Za-z0-9_-]", "_");
        curves = groupResults(groupIndex).curves;
        curveTable = table(curves.strain, curves.centralStress, ...
            curves.meanStress, curves.medianStress, ...
            'VariableNames', {'Strain','CentralStress','MeanStress','MedianStress'});
        curveFile = fullfile(folder, safeName + "_population_curve.csv");
        writetable(curveTable, curveFile);
        populationStudy.outputFiles.(matlab.lang.makeValidName(safeName + "Curve")) = ...
            string(curveFile);
    end
    studyFile = fullfile(folder, "compression_population_study.mat");
    save(studyFile, "populationStudy");
    populationStudy.outputFiles.study = string(studyFile);
end
end

function manifest = localManifest(input, defaultLength)
if istable(input)
    manifest = input;
else
    manifest = readtable(string(input), "VariableNamingRule", "preserve");
end
required = ["File", "SpecimenId", "InitialArea"];
names = string(manifest.Properties.VariableNames);
if ~all(ismember(required, names))
    error("mechanics:workflow:InvalidCompressionPopulationManifest", ...
        "Manifest requires File, SpecimenId, and InitialArea columns.");
end
manifest.File = string(manifest.File);
manifest.SpecimenId = string(manifest.SpecimenId);
if ~ismember("Group", names)
    manifest.Group = repmat("all", height(manifest), 1);
else
    manifest.Group = string(manifest.Group);
end
if ~ismember("InitialLength", names)
    manifest.InitialLength = repmat(defaultLength, height(manifest), 1);
end
if ~ismember("Include", names)
    manifest.Include = true(height(manifest), 1);
else
    manifest.Include = logical(manifest.Include);
end
if any(~isfinite(manifest.InitialLength) | manifest.InitialLength <= 0) || ...
        any(~isfinite(manifest.InitialArea) | manifest.InitialArea <= 0)
    error("mechanics:workflow:InvalidCompressionPopulationGeometry", ...
        "InitialLength and InitialArea must be positive finite values.");
end
end

function summary = localSummary(records)
count = numel(records);
Index = (1:count)';
SpecimenId = string({records.specimenId})';
Group = string({records.group})';
Status = string({records.status})';
PeakStress = nan(count,1);
PeakStrain = nan(count,1);
HysteresisEnergy = nan(count,1);
HysteresisFraction = nan(count,1);
MedianTangentModulus = nan(count,1);
SelectedModel = strings(count,1);
for index = 1:count
    if records(index).status ~= "processed"
        continue;
    end
    study = records(index).study;
    PeakStress(index) = study.cycleMetrics.peakStress;
    PeakStrain(index) = study.cycleMetrics.peakStrain;
    HysteresisEnergy(index) = study.cycleMetrics.hysteresisEnergy;
    HysteresisFraction(index) = study.cycleMetrics.hysteresisFraction;
    MedianTangentModulus(index) = ...
        study.specimen.analysis.tangentModulus.medianModulus;
    if isfield(study.specimen, "modelSelection") && ...
            study.specimen.modelSelection.selection.succeeded
        SelectedModel(index) = study.specimen.modelSelection.selection.modelName;
    end
end
summary = table(Index, SpecimenId, Group, Status, PeakStress, PeakStrain, ...
    HysteresisEnergy, HysteresisFraction, MedianTangentModulus, SelectedModel);
end

function metrics = localMetricTable(records)
metrics = table(string({records.specimenId})', ...
    arrayfun(@(r) r.study.cycleMetrics.peakStress, records)', ...
    arrayfun(@(r) r.study.cycleMetrics.hysteresisEnergy, records)', ...
    arrayfun(@(r) r.study.cycleMetrics.hysteresisFraction, records)', ...
    'VariableNames', {'SpecimenId','PeakStress','HysteresisEnergy','HysteresisFraction'});
end

function record = localEmptyRecord()
record.index = NaN;
record.specimenId = "";
record.group = "";
record.file = "";
record.status = "pending";
record.study = struct();
record.errorIdentifier = "";
record.errorMessage = "";
end
