function z = parametersToUnconstrained(parameters, lowerBounds, upperBounds)
%PARAMETERSTOUNCONSTRAINED Map bounded parameters to unconstrained values.
parameters = reshape(parameters, 1, []);
z = zeros(size(parameters));
margin = sqrt(eps);

for j = 1:numel(parameters)
    p = parameters(j); lb = lowerBounds(j); ub = upperBounds(j);
    if isfinite(lb) && isfinite(ub)
        ratio = (p - lb) / (ub - lb);
        ratio = min(max(ratio, margin), 1 - margin);
        z(j) = log(ratio / (1 - ratio));
    elseif isfinite(lb)
        z(j) = log(max(p - lb, margin));
    elseif isfinite(ub)
        z(j) = log(max(ub - p, margin));
    else
        z(j) = p;
    end
end
end
