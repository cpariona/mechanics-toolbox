function comparison = compareCurves(referenceCurve, candidateCurve, tolerance)
%COMPARECURVES Compare two stress-strain curves on a common strain grid.
arguments
    referenceCurve (1,1) struct
    candidateCurve (1,1) struct
    tolerance (1,1) double {mustBeNonnegative} = 1e-6
end

requiredFields = ["strain", "stress"];
if ~all(isfield(referenceCurve, requiredFields)) || ...
        ~all(isfield(candidateCurve, requiredFields))
    error("mechanics:validation:InvalidCurve", ...
        "Both curves must contain strain and stress.");
end

referenceStrain = referenceCurve.strain(:);
referenceStress = referenceCurve.stress(:);
candidateStrain = candidateCurve.strain(:);
candidateStress = candidateCurve.stress(:);

localValidateCurve(referenceStrain, referenceStress, "reference");
localValidateCurve(candidateStrain, candidateStress, "candidate");

[referenceStrain, referenceOrder] = sort(referenceStrain);
referenceStress = referenceStress(referenceOrder);
[candidateStrain, candidateOrder] = sort(candidateStrain);
candidateStress = candidateStress(candidateOrder);

lowerLimit = max(min(referenceStrain), min(candidateStrain));
upperLimit = min(max(referenceStrain), max(candidateStrain));

if upperLimit <= lowerLimit
    error("mechanics:validation:NoOverlap", ...
        "The curves do not share a common strain interval.");
end

referenceMask = referenceStrain >= lowerLimit & referenceStrain <= upperLimit;
commonStrain = referenceStrain(referenceMask);
referenceCommonStress = referenceStress(referenceMask);
candidateCommonStress = interp1( ...
    candidateStrain, candidateStress, commonStrain, "linear");

difference = candidateCommonStress - referenceCommonStress;
scale = max(max(abs(referenceCommonStress)), eps);
normalizedRmse = sqrt(mean(difference.^2)) ./ scale;

comparison.commonStrain = commonStrain;
comparison.referenceStress = referenceCommonStress;
comparison.candidateStress = candidateCommonStress;
comparison.difference = difference;
comparison.rmse = sqrt(mean(difference.^2));
comparison.normalizedRmse = normalizedRmse;
comparison.maximumAbsoluteDifference = max(abs(difference));
comparison.tolerance = tolerance;
comparison.passed = normalizedRmse <= tolerance;
end

function localValidateCurve(strain, stress, curveName)
if numel(strain) ~= numel(stress)
    error("mechanics:validation:SizeMismatch", ...
        "%s strain and stress must have equal lengths.", curveName);
end

valid = isfinite(strain) & isfinite(stress);
if nnz(valid) < 2
    error("mechanics:validation:InsufficientData", ...
        "%s curve must contain at least two finite points.", curveName);
end

strain = strain(valid);
if numel(unique(strain)) < 2
    error("mechanics:validation:InvalidCurve", ...
        "%s curve must span at least two strain values.", curveName);
end
end
