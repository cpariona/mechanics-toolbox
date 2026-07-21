function figureHandle = plotGroupComparison(result)
%PLOTGROUPCOMPARISON Plot group means and pairwise difference.
if ~isfield(result,"curveComparison") || isempty(fieldnames(result.curveComparison))
    error("mechanics:plotting:NoPairwiseComparison", ...
        "Pairwise plotting requires exactly two groups.");
end
c=result.curveComparison;
figureHandle=figure("Color","w"); tiledlayout(figureHandle,2,1);
nexttile; hold on;
plot(c.strain,c.meanStressA,"LineWidth",2,"DisplayName",char(c.groupNameA));
plot(c.strain,c.meanStressB,"LineWidth",2,"DisplayName",char(c.groupNameB));
xlabel("Strain"); ylabel("Stress"); grid on; box on; legend("Location","best","Interpreter","none");
nexttile; hold on;
if all(isfinite(c.confidenceLower)) && all(isfinite(c.confidenceUpper))
    fill([c.strain;flipud(c.strain)],[c.confidenceLower;flipud(c.confidenceUpper)], ...
        0.8*[1 1 1],"EdgeColor","none","FaceAlpha",0.5,"DisplayName","Bootstrap CI");
end
plot(c.strain,c.meanDifference,"LineWidth",2,"DisplayName","Mean difference");
yline(0,"--","HandleVisibility","off"); xlabel("Strain"); ylabel("Stress difference");
grid on; box on; legend("Location","best");
end
