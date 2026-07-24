function summary = summarizePeakMetrics(records)
%SUMMARIZEPEAKMETRICS Build specimen-level peak-metric summary.
arguments
    records struct
end

processedRecords = records([records.status] == "processed");
n = numel(processedRecords);
specimenId = strings(n,1);
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
    if ~isfield(record.specimen, "peakMetrics")
        continue;
    end
    metrics = record.specimen.peakMetrics;
    peakForce(index) = metrics.peakForce;
    peakDisplacement(index) = metrics.peakDisplacement;
    peakStress(index) = metrics.peakStress;
    peakStrain(index) = metrics.peakStrain;
    postPeakDropFraction(index) = metrics.postPeakDropFraction;
    residualForceFraction(index) = metrics.residualForceFraction;
    energyToPeak(index) = metrics.energyToPeak;
    totalRecordedEnergy(index) = metrics.totalRecordedEnergy;
    energyDensityToPeak(index) = metrics.energyDensityToPeak;
end

summary = table(specimenId, peakForce, peakDisplacement, peakStress, ...
    peakStrain, postPeakDropFraction, residualForceFraction, energyToPeak, ...
    totalRecordedEnergy, energyDensityToPeak, 'VariableNames', { ...
    'SpecimenId', 'PeakForce', 'PeakDisplacement', 'PeakStress', ...
    'PeakStrain', 'PostPeakDropFraction', 'ResidualForceFraction', ...
    'EnergyToPeak', 'TotalRecordedEnergy', 'EnergyDensityToPeak'});
end
