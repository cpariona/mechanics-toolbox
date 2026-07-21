function summary = summarizeExtractedDataset(dataset)
%SUMMARIZEEXTRACTEDDATASET Summarize extracted or processed specimens.
arguments
    dataset (1,1) struct
end

specimens = dataset.specimens(:);
specimenCount = numel(specimens);

specimenId = strings(specimenCount, 1);
sheetName = strings(specimenCount, 1);
observationCount = zeros(specimenCount, 1);
initialLength = nan(specimenCount, 1);
thickness = nan(specimenCount, 1);
width = nan(specimenCount, 1);
initialArea = nan(specimenCount, 1);
maximumDisplacement = nan(specimenCount, 1);
maximumForce = nan(specimenCount, 1);
maximumStrain = nan(specimenCount, 1);
maximumStress = nan(specimenCount, 1);
medianTangentModulus = nan(specimenCount, 1);

for index = 1:specimenCount
    specimen = specimens(index);
    specimenId(index) = specimen.id;

    if isfield(specimen, "sheetName")
        sheetName(index) = specimen.sheetName;
    end

    observationCount(index) = numel(specimen.raw.force);
    maximumDisplacement(index) = max(specimen.raw.displacement);
    maximumForce(index) = max(specimen.raw.force);

    geometryFields = ["initialLength", "thickness", "width", "initialArea"];
    geometryOutputs = { ...
        initialLength, thickness, width, initialArea};

    for fieldIndex = 1:numel(geometryFields)
        if isfield(specimen.geometry, geometryFields(fieldIndex))
            geometryOutputs{fieldIndex}(index) = ...
                specimen.geometry.(geometryFields(fieldIndex));
        end
    end

    initialLength = geometryOutputs{1};
    thickness = geometryOutputs{2};
    width = geometryOutputs{3};
    initialArea = geometryOutputs{4};

    if isfield(specimen, "processed")
        maximumStrain(index) = max(specimen.processed.strain);
        maximumStress(index) = max(specimen.processed.stress);
    end

    if isfield(specimen, "analysis") && ...
            isfield(specimen.analysis, "tangentModulus")
        medianTangentModulus(index) = ...
            specimen.analysis.tangentModulus.medianModulus;
    end
end

summary = table( ...
    specimenId, sheetName, observationCount, ...
    initialLength, thickness, width, initialArea, ...
    maximumDisplacement, maximumForce, ...
    maximumStrain, maximumStress, medianTangentModulus, ...
    'VariableNames', { ...
        'SpecimenId', 'SheetName', 'ObservationCount', ...
        'InitialLength', 'Thickness', 'Width', 'InitialArea', ...
        'MaximumDisplacement', 'MaximumForce', ...
        'MaximumStrain', 'MaximumStress', ...
        'MedianTangentModulus'});
end
