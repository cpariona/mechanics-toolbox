function summary = summarizeFractureMetrics(records)
%SUMMARIZEFRACTUREMETRICS Build specimen-level fracture summary.
arguments
    records struct
end

processedMask = [records.status] == "processed";
processedRecords = records(processedMask);
n = numel(processedRecords);

specimenId = strings(n,1);
fractureDetected = false(n,1);
completeFracture = false(n,1);
peakForce = nan(n,1);
peakDisplacement = nan(n,1);
peakStress = nan(n,1);
peakStrain = nan(n,1);
postPeakDropFraction = nan(n,1);
residualForceFraction = nan(n,1);
energyToPeak = nan(n,1);
totalRecordedEnergy = nan(n,1);
energyDensityToPeak = nan(n,1);

for index = 1:n
    record = processedRecords(index);
    specimenId(index) = record.specimenId;

    if ~isfield(record.specimen, "fracture")
        continue;
    end

    fracture = record.specimen.fracture;
    fractureDetected(index) = fracture.fractureDetected;
    completeFracture(index) = fracture.completeFracture;
    peakForce(index) = fracture.peakForce;
    peakDisplacement(index) = fracture.peakDisplacement;
    peakStress(index) = fracture.peakStress;
    peakStrain(index) = fracture.peakStrain;
    postPeakDropFraction(index) = fracture.postPeakDropFraction;
    residualForceFraction(index) = fracture.residualForceFraction;
    energyToPeak(index) = fracture.energyToPeak;
    totalRecordedEnergy(index) = fracture.totalRecordedEnergy;
    energyDensityToPeak(index) = fracture.energyDensityToPeak;
end

summary = table( ...
    specimenId, fractureDetected, completeFracture, ...
    peakForce, peakDisplacement, peakStress, peakStrain, ...
    postPeakDropFraction, residualForceFraction, ...
    energyToPeak, totalRecordedEnergy, energyDensityToPeak, ...
    'VariableNames', { ...
        'SpecimenId', 'FractureDetected', 'CompleteFracture', ...
        'PeakForce', 'PeakDisplacement', 'PeakStress', 'PeakStrain', ...
        'PostPeakDropFraction', 'ResidualForceFraction', ...
        'EnergyToPeak', 'TotalRecordedEnergy', ...
        'EnergyDensityToPeak'});
end
