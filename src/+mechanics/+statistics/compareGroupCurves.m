function comparison = compareGroupCurves(groupA,groupB,config)
%COMPAREGROUPCURVES Compare two population stress-strain curves.
lo=max(groupA.curves.strainRange(1),groupB.curves.strainRange(1));
hi=min(groupA.curves.strainRange(2),groupB.curves.strainRange(2));
if hi<=lo
    error("mechanics:statistics:NoCommonGroupStrainRange", ...
        "Groups do not share a common strain range.");
end
n=min(numel(groupA.curves.strain),numel(groupB.curves.strain));
strain=linspace(lo,hi,n)';
A=localInterp(groupA.curves,strain); B=localInterp(groupB.curves,strain);
meanA=mean(A,2); meanB=mean(B,2); difference=meanA-meanB;
lower=nan(n,1); upper=nan(n,1);
if config.bootstrap.enabled
    for k=1:n
        c=config.bootstrap; c.randomSeed=config.bootstrap.randomSeed+k-1;
        ci=mechanics.statistics.bootstrapDifferenceOfMeans(A(k,:),B(k,:),c);
        lower(k)=ci.lower; upper(k)=ci.upper;
    end
end
comparison.strain=strain;
comparison.meanStressA=meanA;
comparison.meanStressB=meanB;
comparison.meanDifference=difference;
comparison.confidenceLower=lower;
comparison.confidenceUpper=upper;
comparison.groupNameA=groupA.name;
comparison.groupNameB=groupB.name;
comparison.sampleCountA=size(A,2);
comparison.sampleCountB=size(B,2);
comparison.stressMatrixA=A;
comparison.stressMatrixB=B;
end
function M=localInterp(curves,x)
M=nan(numel(x),size(curves.stressMatrix,2));
for j=1:size(M,2)
    M(:,j)=interp1(curves.strain,curves.stressMatrix(:,j),x,"linear");
end
end
