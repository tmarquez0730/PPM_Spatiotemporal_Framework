function [pressure_template, diagnostics] = resample_force_preserve(in, targetRows, targetCols, varargin)
% RESAMPLE_FORCE_PRESERVE
%  Area-overlap (force-preserving) resampling of a pressure map
%  to a target grid.  Force is preserved exactly (within floating eps).
%
%  USAGE:
%    P = resample_force_preserve(in, 50, 18);
%
%  INPUTS:
%    in          - HxW pressure matrix for resampling (or scaling)
%    targetRows  - number of rows in template (e.g. 50)
%    targetCols  - number of cols in template (e.g. 18)
%    Optional name/value:
%      'inputPixelArea' numeric scalar default 1  (area units per input pixel)
%
%  OUTPUTS:
%    pressure_template - targetRows x targetCols matrix
%    diagnostics       - struct with fields:
%        .force_input
%        .force_template
%        .A_template_pixel
%        .conserved (true if close)
%
%  NOTES:
%    - This routine treats each input pixel (i,j) as covering the rectangle
%      x in [j-1, j], y in [i-1, i] in a continuous index coordinate system.
%      The output grid covers the same continuous extents [0,W] x [0,H],
%      subdivided into targetCols x targetRows bins.
%    - For example, if the new resampled sensor grid standard H,W leads to
%      new sensors being larger than the original, the new pressure will be
%      as followed:
%                   PRESSUREnew = FORCEnew / AREAnew
%         where:
%                   FORCEnew = SUM(AREAn * PRESSUREn) for n=1:4
%                   AREAnew = (Width / TargetColumns) * (Height /
%                   TargetRows) * AREAinput
% 

% parse optional args
p = inputParser;
addParameter(p, 'inputPixelArea', 1); % area per input pixel (default 1)
parse(p, varargin{:});
A_input_pixel = p.Results.inputPixelArea;

%Input pressure matrix and sensor grid edges
[H, W] = size(in);
x_edges_in = 0:W;
y_edges_in = 0:H;

%Target pressure matrix size with target sensor grid edges
force_template = zeros(targetRows, targetCols);
x_edges_out = linspace(0, W, targetCols+1);
y_edges_out = linspace(0, H, targetRows+1);

% For each output sensor, compute overlap with input sensors
for r = 1:targetRows
    y1 = y_edges_out(r);
    y2 = y_edges_out(r+1);
    in_iy_min = max(1, floor(y1)+1);
    in_iy_max = min(H, ceil(y2));
    for c = 1:targetCols
        x1 = x_edges_out(c);
        x2 = x_edges_out(c+1);
        in_ix_min = max(1, floor(x1)+1);
        in_ix_max = min(W, ceil(x2));
        %Check the order is correct of mix/max (all feet are left
        %orientation)
        if in_iy_min > in_iy_max
            in_iy_min = 1; in_iy_max = H;
        end
        if in_ix_min > in_ix_max
            in_ix_min = 1; in_ix_max = W;
        end
        %New force grid (preserved) based on overlapping areas and input
        %pressures
        force_accum = 0;
        for ii = in_iy_min:in_iy_max
            ay = min(ii, y2) - max(ii-1, y1);
            if ay <= 0, continue; end
            for jj = in_ix_min:in_ix_max
                ax = min(jj, x2) - max(jj-1, x1);
                if ax <= 0, continue; end
                overlap_area = ax * ay;
                force_accum = force_accum + in(ii,jj) * overlap_area * A_input_pixel;
            end
        end
        force_template(r,c) = force_accum;
    end
end

% new sensor area following overlaid standard grid (e.g. 50x18)
A_template_pixel = (W / targetCols) * (H / targetRows) * A_input_pixel;

% Convert new force preserved sensor grid back to pressure based on new
% sensor area
pressure_template = zeros(size(force_template));
nonzero_mask = (A_template_pixel > 0);
if nonzero_mask
    pressure_template = force_template ./ A_template_pixel;
end

% diagnostics: check that force is preserved and output new sensor area
force_input = sum(in(:)) * A_input_pixel;
force_out = sum(force_template(:));
diagnostics.force_input = force_input;
diagnostics.force_template = force_out;
diagnostics.A_template_pixel = A_template_pixel;
diagnostics.conserved = abs(force_input - force_out) < 1e-8*max(1,abs(force_input));

end
