function figHandle = createWhiteFigure()
% Creates a white MATLAB figure with standard menu and toolbar.
%
% Inputs:
%   None.
%
% Outputs:
%   figHandle - Handle to the created figure.

    figHandle = figure( ...
        'MenuBar','figure', ...
        'ToolBar','figure', ...
        'Color','w');
end