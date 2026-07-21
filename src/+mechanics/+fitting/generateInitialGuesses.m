function starts = generateInitialGuesses(initialGuess, lowerBounds, upperBounds, numberOfStarts)
%GENERATEINITIALGUESSES Create deterministic bounded multi-start guesses.
initialGuess = reshape(initialGuess, 1, []);
starts = repmat(initialGuess, numberOfStarts, 1);

for i = 2:numberOfStarts
    for j = 1:numel(initialGuess)
        lb = lowerBounds(j);
        ub = upperBounds(j);
        p0 = initialGuess(j);

        if isfinite(lb) && isfinite(ub)
            fraction = 0.1 + 0.8 * rand();
            starts(i,j) = lb + fraction * (ub - lb);
        elseif isfinite(lb)
            scale = max(abs(p0 - lb), max(abs(p0), 1));
            starts(i,j) = lb + scale * exp(1.5 * randn());
        elseif isfinite(ub)
            scale = max(abs(ub - p0), max(abs(p0), 1));
            starts(i,j) = ub - scale * exp(1.5 * randn());
        else
            scale = max(abs(p0), 1);
            starts(i,j) = p0 + scale * randn();
        end
    end
end
end
