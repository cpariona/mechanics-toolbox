function comparison = compareGroupMetrics(summary,groupA,groupB,config)
%COMPAREGROUPMETRICS Compare scalar metrics between two groups.
required=["Status","Group","MaximumStrain","MaximumStress","MedianTangentModulus"];
if ~all(ismember(required,string(summary.Properties.VariableNames)))
    error("mechanics:statistics:InvalidGroupedSummary", ...
        "Summary lacks required grouped metrics.");
end
metrics=["MaximumStrain";"MaximumStress";"MedianTangentModulus"];
n=numel(metrics); na=zeros(n,1); nb=zeros(n,1);
ma=nan(n,1); mb=nan(n,1); delta=nan(n,1); lower=nan(n,1); upper=nan(n,1);
S=summary(summary.Status=="processed",:);
for k=1:n
    a=S.(metrics(k))(S.Group==groupA); b=S.(metrics(k))(S.Group==groupB);
    a=a(isfinite(a)); b=b(isfinite(b)); na(k)=numel(a); nb(k)=numel(b);
    if isempty(a)||isempty(b), continue; end
    ma(k)=mean(a); mb(k)=mean(b); delta(k)=ma(k)-mb(k);
    if config.bootstrap.enabled
        c=config.bootstrap; c.randomSeed=config.bootstrap.randomSeed+5000+k;
        ci=mechanics.statistics.bootstrapDifferenceOfMeans(a,b,c);
        lower(k)=ci.lower; upper(k)=ci.upper;
    end
end
comparison=table(metrics,repmat(groupA,n,1),repmat(groupB,n,1),na,nb,ma,mb,delta,lower,upper, ...
 'VariableNames',{'Metric','GroupA','GroupB','SampleCountA','SampleCountB','MeanA','MeanB','MeanDifference','ConfidenceLower','ConfidenceUpper'});
end
