function y_smooth = smoothMechanicalVector(y, frameLength, polyOrder)
% Smooths a mechanical data vector using Savitzky-Golay filtering.
% If the vector is too short, the original vector is returned.
%
% Inputs:
%   y           - Input vector.
%   frameLength - Requested smoothing frame length.
%   polyOrder   - Savitzky-Golay polynomial order.
%
% Outputs:
%   y_smooth - Smoothed vector.

    y = y(:);

    if nargin < 3 || isempty(polyOrder)
        polyOrder = 3;
    end

    if nargin < 2 || isempty(frameLength)
        frameLength = 21;
    end

    frameLength = min(frameLength, length(y));

    if mod(frameLength, 2) == 0
        frameLength = frameLength - 1;
    end

    if frameLength <= polyOrder || frameLength < 5
        y_smooth = y;
        return;
    end

    y_smooth = sgolayfilt(y, polyOrder, frameLength);
end