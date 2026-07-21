function parameters = unconstrainedToParameters(z, lowerBounds, upperBounds)
%UNCONSTRAINEDTOPARAMETERS Map unconstrained values to bounded parameters.
z = reshape(z, 1, []);
parameters = zeros(size(z));
for j = 1:numel(z)
    lb = lowerBounds(j); ub = upperBounds(j);
    if isfinite(lb) && isfinite(ub)
        if z(j) >= 0
            logistic = 1 / (1 + exp(-z(j)));
        else
            ez = exp(z(j));
            logistic = ez / (1 + ez);
        end
        parameters(j) = lb + (ub - lb) * logistic;
    elseif isfinite(lb)
        parameters(j) = lb + exp(min(z(j), 700));
    elseif isfinite(ub)
        parameters(j) = ub - exp(min(z(j), 700));
    else
        parameters(j) = z(j);
    end
end
end
