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
    "curves", struct(), "metrics", table(), "parameters", table(), ...
    "status", "insufficient"), numel(groups), 1);
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
    groupResults(groupIndex).parameters = localParameterTable(selected);
    groupResults(groupIndex).status = "processed";
end

populationStudy.manifest = manifest;
populationStudy.records = records;
populationStudy.summary = summary;
populationStudy.groups = groupResults;
populationStudy.config = config;
populationStudy.createdAt = datetime("now");
populationStudy.comparison = struct();

if isfield(config, "comparison") && config.comparison.enabled
    processedGroups = string({groupResults([groupResults.status]=="processed").name});
    if numel(processedGroups) >= 2
        adapter = localComparisonAdapter(records, summary);
        comparisonConfig = config.comparison.config;
        comparisonConfig.minimumSpecimensPerGroup = config.minimumSpecimensPerGroup;
        populationStudy.comparison = mechanics.workflow.analyzeGroupComparison( ...
            adapter, processedGroups, comparisonConfig);
    end
end

if config.export.enabled
    folder = string(config.export.outputFolder);
    if ~isfolder(folder), mkdir(folder); end
    summaryFile = fullfile(folder, "compression_population_summary.csv");
    writetable(summary, summaryFile);
    populationStudy.outputFiles.summary = string(summaryFile);
    for groupIndex = 1:numel(groupResults)
        if groupResults(groupIndex).status ~= "processed", continue; end
        safeName = regexprep(groupResults(groupIndex).name, "[^A-Za-z0-9_-]", "_");
        curves = groupResults(groupIndex).curves;
        curveTable = table(curves.strain, curves.centralStress, ...
            curves.meanStress, curves.medianStress, ...
            'VariableNames', {'Strain','CentralStress','MeanStress','MedianStress'});
        curveFile = fullfile(folder, safeName + "_population_curve.csv");
        writetable(curveTable, curveFile);
        populationStudy.outputFiles.(matlab.lang.makeValidName(safeName + "Curve")) = string(curveFile);
        metricFile = fullfile(folder, safeName + "_metrics.csv");
        writetable(groupResults(groupIndex).metrics, metricFile);
        populationStudy.outputFiles.(matlab.lang.makeValidName(safeName + "Metrics")) = string(metricFile);
        if ~isempty(groupResults(groupIndex).parameters)
            parameterFile = fullfile(folder, safeName + "_parameters.csv");
            writetable(groupResults(groupIndex).parameters, parameterFile);
            populationStudy.outputFiles.(matlab.lang.makeValidName(safeName + "Parameters")) = string(parameterFile);
        end
    end
    if isfield(populationStudy.comparison, "metricComparison") && ...
            ~isempty(populationStudy.comparison.metricComparison)
        comparisonFile = fullfile(folder, "compression_group_metric_comparison.csv");
        writetable(populationStudy.comparison.metricComparison, comparisonFile);
        populationStudy.outputFiles.comparison = string(comparisonFile);
    end
    if isfield(config.export, "saveFigures") && config.export.saveFigures
        figureFiles = mechanics.plotting.exportCompressionPopulationFigures( ...
            populationStudy, config.export);
        populationStudy.outputFiles.figures = figureFiles;
    end
    studyFile = fullfile(folder, "compression_population_study.mat");
    save(studyFile, "populationStudy");
    populationStudy.outputFiles.study = string(studyFile);
end
end

function manifest = localManifest(input, defaultLength)
if istable(input), manifest = input;
else, manifest = readtable(string(input), "VariableNamingRule", "preserve"); end
required = ["File", "SpecimenId", "InitialArea"];
names = string(manifest.Properties.VariableNames);
if ~all(ismember(required, names))
    error("mechanics:workflow:InvalidCompressionPopulationManifest", ...
        "Manifest requires File, SpecimenId, and InitialArea columns.");
end
manifest.File = string(manifest.File);
manifest.SpecimenId = string(manifest.SpecimenId);
if ~ismember("Group", names), manifest.Group = repmat("all", height(manifest), 1);
else, manifest.Group = string(manifest.Group); end
if ~ismember("InitialLength", names)
    manifest.InitialLength = repmat(defaultLength, height(manifest), 1);
end
if ~ismember("Include", names), manifest.Include = true(height(manifest), 1);
else, manifest.Include = logical(manifest.Include); end
if any(~isfinite(manifest.InitialLength) | manifest.InitialLength <= 0) || ...
        any(~isfinite(manifest.InitialArea) | manifest.InitialArea <= 0)
    error("mechanics:workflow:InvalidCompressionPopulationGeometry", ...
        "InitialLength and InitialArea must be positive finite values.");
end
end

function summary = localSummary(records)
count = numel(records); Index=(1:count)'; SpecimenId=string({records.specimenId})';
Group=string({records.group})'; Status=string({records.status})';
PeakStress=nan(count,1); PeakStrain=nan(count,1); HysteresisEnergy=nan(count,1);
HysteresisFraction=nan(count,1); MedianTangentModulus=nan(count,1); SelectedModel=strings(count,1);
for index=1:count
    if records(index).status~="processed", continue; end
    study=records(index).study; PeakStress(index)=study.cycleMetrics.peakStress;
    PeakStrain(index)=study.cycleMetrics.peakStrain; HysteresisEnergy(index)=study.cycleMetrics.hysteresisEnergy;
    HysteresisFraction(index)=study.cycleMetrics.hysteresisFraction;
    MedianTangentModulus(index)=study.specimen.analysis.tangentModulus.medianModulus;
    if isfield(study.specimen,"modelSelection") && study.specimen.modelSelection.selection.hasEligibleModel
        SelectedModel(index)=study.specimen.modelSelection.selection.bestModel;
    end
end
summary=table(Index,SpecimenId,Group,Status,PeakStress,PeakStrain,HysteresisEnergy,HysteresisFraction,MedianTangentModulus,SelectedModel);
end

function metrics=localMetricTable(records)
count=numel(records); SpecimenId=strings(count,1); PeakStress=nan(count,1);
HysteresisEnergy=nan(count,1); HysteresisFraction=nan(count,1); MedianTangentModulus=nan(count,1);
for index=1:count
    SpecimenId(index)=records(index).specimenId; study=records(index).study;
    PeakStress(index)=study.cycleMetrics.peakStress;
    HysteresisEnergy(index)=study.cycleMetrics.hysteresisEnergy;
    HysteresisFraction(index)=study.cycleMetrics.hysteresisFraction;
    MedianTangentModulus(index)=study.specimen.analysis.tangentModulus.medianModulus;
end
metrics=table(SpecimenId,PeakStress,HysteresisEnergy,HysteresisFraction,MedianTangentModulus);
end

function parameters=localParameterTable(records)
rows=struct('SpecimenId',{},'Model',{},'Parameter',{},'Estimate',{},'Lower',{},'Median',{},'Upper',{});
row=0;
for index=1:numel(records)
    specimen=records(index).study.specimen;
    if ~isfield(specimen,"modelSelection") || ~specimen.modelSelection.selection.hasEligibleModel, continue; end
    best=specimen.modelSelection.selection.bestModel; rec=specimen.modelSelection.records;
    mask=[rec.succeeded] & string({rec.modelName})==best; selected=rec(mask);
    [~,j]=max([selected.windowFraction]); fit=selected(j).fitResult;
    lower=nan(size(fit.parameters)); median=nan(size(fit.parameters)); upper=nan(size(fit.parameters));
    if isfield(specimen,"geometryMonteCarloFit")
        lower=specimen.geometryMonteCarloFit.parameterLower;
        median=specimen.geometryMonteCarloFit.parameterMedian;
        upper=specimen.geometryMonteCarloFit.parameterUpper;
    end
    for p=1:numel(fit.parameters)
        row=row+1; rows(row).SpecimenId=string(specimen.id); rows(row).Model=best;
        rows(row).Parameter=string(fit.parameterNames(p)); rows(row).Estimate=fit.parameters(p);
        rows(row).Lower=lower(p); rows(row).Median=median(p); rows(row).Upper=upper(p);
    end
end
if isempty(rows), parameters=table(); else, parameters=struct2table(rows); end
end

function adapter=localComparisonAdapter(records,summary)
adapter.summary=summary; adapter.summary.MaximumStrain=summary.PeakStrain;
adapter.summary.MaximumStress=summary.PeakStress;
adapter.records=repmat(struct('index',NaN,'specimenId',"",'sheetName',"", ...
    'status',"",'group',"",'specimen',struct()),numel(records),1);
for i=1:numel(records)
    adapter.records(i).index=records(i).index;
    adapter.records(i).specimenId=records(i).specimenId;
    adapter.records(i).sheetName=records(i).file;
    adapter.records(i).status=records(i).status;
    adapter.records(i).group=records(i).group;
    if records(i).status=="processed"
        adapter.records(i).specimen=records(i).study.specimen;
    end
end
end

function record=localEmptyRecord()
record.index=NaN; record.specimenId=""; record.group=""; record.file=""; record.status="pending";
record.study=struct(); record.errorIdentifier=""; record.errorMessage="";
end
