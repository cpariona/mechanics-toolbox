function result = bootstrapDifferenceOfMeans(a,b,config)
%BOOTSTRAPDIFFERENCEOFMEANS Bootstrap mean(a)-mean(b).
a=a(:); b=b(:); a=a(isfinite(a)); b=b(isfinite(b));
if isempty(a)||isempty(b)
    error("mechanics:statistics:NoFiniteData", ...
        "Both groups require finite observations.");
end
n=round(config.iterations);
if ~isscalar(n)||n<1
    error("mechanics:statistics:InvalidBootstrapIterations", ...
        "Bootstrap iterations must be positive.");
end
if config.confidenceLevel<=0||config.confidenceLevel>=1
    error("mechanics:statistics:InvalidConfidenceLevel", ...
        "Confidence level must lie in (0,1).");
end
rng(config.randomSeed,"twister");
d=zeros(n,1);
for k=1:n
    d(k)=mean(a(randi(numel(a),numel(a),1)))- ...
         mean(b(randi(numel(b),numel(b),1)));
end
alpha=1-config.confidenceLevel;
result.meanDifference=mean(a)-mean(b);
result.lower=localPercentile(d,alpha/2);
result.upper=localPercentile(d,1-alpha/2);
result.bootstrapDifferences=d;
result.sampleCountA=numel(a);
result.sampleCountB=numel(b);
end
function v=localPercentile(x,p)
x=sort(x(:)); n=numel(x); pos=1+p*(n-1); lo=floor(pos); hi=ceil(pos);
if lo==hi, v=x(lo); else, f=pos-lo; v=x(lo)*(1-f)+x(hi)*f; end
end
