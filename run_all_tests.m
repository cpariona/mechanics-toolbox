function results = run_all_tests()
%RUN_ALL_TESTS Initialize the repository and run the complete test suite.
%
% This runner is independent of the caller's current working directory.
% It temporarily switches to the repository root, executes startup.m, runs
% every test under tests/, and restores the original working directory.

runnerFile = mfilename("fullpath");
repositoryRoot = fileparts(runnerFile);
originalFolder = pwd;

cleanup = onCleanup(@() cd(originalFolder)); %#ok<NASGU>

cd(repositoryRoot);
run(fullfile(repositoryRoot, "startup.m"));

results = runtests( ...
    fullfile(repositoryRoot, "tests"), ...
    "IncludeSubfolders", true ...
);

disp(table(results))

if ~all([results.Passed])
    failedResults = results(~[results.Passed]);
    fprintf("\nFailed or incomplete tests:\n");
    disp(table(failedResults))

    error("mechanics:tests:RepositoryTestsFailed", ...
        "One or more repository tests failed.");
end

fprintf("\nAll %d repository tests passed.\n", numel(results));
end
