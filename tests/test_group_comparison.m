function tests = test_group_comparison
tests=functiontests(localfunctions);
end
function setupOnce(~), startup; end
function testGroupAssignment(testCase)
a=localAnalysis(); A=table(["a1";"a2";"b1";"b2"],["control";"control";"treated";"treated"], ...
 'VariableNames',{'SpecimenId','Group'});
a=mechanics.workflow.assignSpecimenGroups(a,A);
verifyEqual(testCase,a.summary.Group,["control";"control";"treated";"treated"]);
end
function testBootstrapDifference(testCase)
c.enabled=true;c.iterations=300;c.confidenceLevel=.95;c.randomSeed=4;
r=mechanics.statistics.bootstrapDifferenceOfMeans([3 4 5],[1 2 3],c);
verifyEqual(testCase,r.meanDifference,2,"AbsTol",1e-12);
verifyLessThanOrEqual(testCase,r.lower,2); verifyGreaterThanOrEqual(testCase,r.upper,2);
end
function testTwoGroupComparison(testCase)
a=localAnalysis(); A=table(["a1";"a2";"b1";"b2"],["control";"control";"treated";"treated"], ...
 'VariableNames',{'SpecimenId','Group'});
a=mechanics.workflow.assignSpecimenGroups(a,A);
c=mechanics.config.groupComparisonConfig(); c.populationConfig.bootstrap.enabled=false; c.bootstrap.enabled=false; c.populationConfig.strainGridPointCount=21;
r=mechanics.workflow.analyzeGroupComparison(a,["control","treated"],c);
verifyEqual(testCase,numel(r.groups),2); verifyEqual(testCase,r.groups(1).specimenCount,2);
verifyEqual(testCase,r.curveComparison.meanDifference(end),-2,"AbsTol",1e-12);
verifyEqual(testCase,height(r.metricComparison),3);
end
function testInsufficientGroupRejected(testCase)
a=localAnalysis(); A=table(["a1";"a2";"b1";"b2"],["control";"control";"treated";"other"], ...
 'VariableNames',{'SpecimenId','Group'});
a=mechanics.workflow.assignSpecimenGroups(a,A);
verifyError(testCase,@() mechanics.workflow.analyzeGroupComparison(a,["control","treated"],mechanics.config.groupComparisonConfig()), ...
 "mechanics:workflow:InsufficientGroupSpecimens");
end
function a=localAnalysis()
ids=["a1";"a2";"b1";"b2"]; slopes=[2;2;4;4]; rec=repmat(localRecord("",1),4,1);
for k=1:4, rec(k)=localRecord(ids(k),slopes(k)); end
a.records=rec; a.summary=table(ids,repmat("processed",4,1),ones(4,1),slopes,slopes, ...
 'VariableNames',{'SpecimenId','Status','MaximumStrain','MaximumStress','MedianTangentModulus'});
end
function r=localRecord(id,slope)
x=linspace(0,1,21)'; s.id=string(id); s.processed.strain=x; s.processed.stress=slope*x;
r.index=1;r.specimenId=string(id);r.sheetName=string(id);r.status="processed";r.quality=struct();r.specimen=s;r.errorIdentifier="";r.errorMessage="";r.group="";
end
