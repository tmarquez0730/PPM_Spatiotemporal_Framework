%% Main Script for Plantar Pressure Mapping Over Stance Intervals
% Built for the EMED-x platform (original smaller version).
clear, clc, close all

% This main code only requires a file directory that contains both the
% maximum pressure pictures (MPP) and the raw sampled plantar pressure 
% frames at 10 ms intervals (FRAME).

% The file type accepted is .txt files converted from .lst files from the
% EMASCII Novel-software. Please save out the MPP files without the header
% or Gait Line. Boxes to be checked are the 1)sensor grid, 2)values of
% pressure, and 3)MPP. The raw sampled frames will need the header on and
% check the frames box.

% Save your files as the following:
        %-----> For MPP: MPP_X (where X is trial #)
        %-----> For frames: FRAME_X (where X is trial #)
        % Make sure you know which trials are left and right feet.

% The code is built on rotation by the Foot Progression Angle (FPA). The
% FPA can be imported from varying plantar pressure softwares or calculated
% within the code.

% This main code will export all data to an excel spreadsheet [ 1) MPP
% raw and aligned data, 2) Frames raw and aligned, 3) COP across frames].
% The code will also export a MATLAB figure (.fig) for each aligned stance
% interval and MPP and raw data collection interval and MPP over the entire
% platform. These aligned stance intervals are also combined into a gif for
% easy vizualization.

% Author: Tyce C. Marquez
% Date (last update): May 28th, 2026

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set up the directory location and get file names
FolderPathName = uigetdir('*.*', 'Select folder with PPM files');
FileList = dir(FolderPathName);
cd(FolderPathName);

%Enter the trial number and foot side for analysis
Prompt = {'Enter the trial number'};
DlgTitle = 'Trial Number';
FieldSize = [1 40];
TrialNumber = inputdlg(Prompt,DlgTitle,FieldSize);
TrialNumber = cell2mat(TrialNumber);
Prompt = {'Select if the foot is right or left'};
ListSide = {'Right','Left'};
FootSide = listdlg('PromptString',Prompt,'ListString',ListSide); %1 = Right, 2 = Left
FootSide_string = string(ListSide(FootSide));
FootSide_string = convertStringsToChars(FootSide_string);
NewFolderName = ['Sample' '_' TrialNumber '_' FootSide_string];
mkdir(NewFolderName);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Maximum Pressure Picture (MPP) and Foot Progression Angle (FPA)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Load in the MPP file
FileName = ['MPP_' num2str(TrialNumber) '.txt'];
MPP = readmatrix(fullfile(FolderPathName, FileName));

%Get rid of row/column indices that do not contain pressure values
MPP = MPP(2:95,2:65); %Size based on total number of platform sensors
isZero = (MPP ~= 0);
[rowIndices, colIndices] = find(isZero);
Minimum_ind_row = min(rowIndices);
Maximum_ind_row = max(rowIndices);
Minimum_ind_col = min(colIndices);
Maximum_ind_col = max(colIndices);
MPP_Box = MPP(Minimum_ind_row:Maximum_ind_row, Minimum_ind_col:Maximum_ind_col);

%Create meshgrid of x and y points from the MPP
[xGrid, yGrid] = meshgrid(1:size(MPP, 2), 1:size(MPP, 1));
xPoints = xGrid(:);
yPoints = yGrid(:);
zPoints = MPP(:);
ValidIndices = zPoints > 0;
xPoints = xPoints(ValidIndices);
yPoints = -yPoints(ValidIndices);
zPoints = zPoints(ValidIndices);

%Convert all left feet to right feet
if FootSide == 1
    xPoints = -xPoints;
    MPP = fliplr(MPP);
    MPP_Box = fliplr(MPP_Box);
end

%Plot the raw EMED maximum pressure data
cbar_min = 0;            %Set up colormap for entire workflow...
cbar_max = 1000;
threshold = 10; %kPa*s
n_colors = 256;
cmap = jet(n_colors);  % base colormap
gray_rgb = [0.9 0.9 0.9]; % light gray
n_gray = round((threshold - cbar_min) / (cbar_max - cbar_min) * n_colors);
n_gray = max(1, min(n_gray, n_colors));  % Clamp to [1, 256]
cmap(1:n_gray, :) = repmat(gray_rgb, n_gray, 1);  % replace low values with gray
f1 = figure; %Includes all values across sensor platform
h1 = heatmap(MPP, 'MissingDataColor', 'white', 'Colormap', parula);
Max_MPP_peaks = max(MPP,[],"all");
title('Raw Maximum Pressure Values Across Entire Sensor Platform (kPa)');
f1.Position = [10 200 550 850];
colormap(cmap);
caxis([0 Max_MPP_peaks]);
f2 = figure; %Only includes row/column indices with pressure values
h2 = heatmap(MPP_Box, 'MissingDataColor', 'white', 'Colormap', parula);
title('Raw Maximum Pressure Values Only at Non-Zero Indices (kPa)');
f2.Position = [585 200 550 850];
colormap(cmap);
caxis([0 Max_MPP_peaks]);

%Contour the maximum pressure picture
 PlantarMesh = alphaShape(xPoints, yPoints, 5); 
[k, v] = boundaryFacets(PlantarMesh);
X_contour = [v(k(:,1),1), v(k(:,2),1), NaN(size(k,1),1)]';
Y_contour = [v(k(:,1),2), v(k(:,2),2), NaN(size(k,1),1)]';
f3 = figure; hold on; axis tight;
plot(X_contour(:), Y_contour(:), 'k-', 'LineWidth', 2); 
f3.Position = [1160 200 550 850];
title('Maximum pressure distribution contour')

%If the FPA is already known, enter here
Prompt = {'If known, enter the FPA, if not enter 0'};
DlgTitle = 'FPA';
FieldSize = [1 40];
FPA = inputdlg(Prompt,DlgTitle,FieldSize);
FPA = cell2mat(FPA);
FPA = str2double(FPA);

%Select medial/lateral boundaries of the foot
if FPA == 0;
    isCorrect = false;
    while ~isCorrect
        fig = uifigure;
        fig.Position = [650 400 500 500];
        fig_message = ["Please select four points","1st: Lateral Forefoot",...
            "2nd: Lateral Hindfoot","3rd: Medial Forefoot", "4th Medial Hindfoot",...
            "***Ignore the toe regions when selecting***"...
            "GOAL: Tangent lines along the lateral and medial boundaries"];
        uialert(fig, fig_message, "Foot Progression Angle Instructions.");
        [x_selection, y_selection] = ginput(4);
        close(fig);
        figure(f3);
        plot(x_selection, y_selection, 'ro', 'LineWidth', 1.5, 'MarkerSize', 8);
        for i = 1:2
            if i == 1
                idx = 1:2;
                line_padding = 2;
            else
                idx = 3:4;
                line_padding = 1;
            end
            x_selection_min = min(x_selection(idx)) - line_padding;
            x_selection_max = max(x_selection(idx)) + line_padding;
            x_line_vals = linspace(x_selection_min, x_selection_max, 100);
            m = (y_selection(idx(2)) - y_selection(idx(1))) / ...
                (x_selection(idx(2)) - x_selection(idx(1)));
            b = y_selection(idx(1)) - m * x_selection(idx(1));
            y_line_vals = m * x_line_vals + b;
            plot(x_line_vals, y_line_vals, 'r--', 'LineWidth', 2);
        end
        Choice = questdlg('Do the lines look correct?', ...
                          'Confirm Point Selection', ...
                          'Yes','No','No');
        if strcmp(Choice,'Yes')
            isCorrect = true;
        else
            % User wants to re-select → loop repeats and re-draws
            disp('Re-select the 4 points...');
            cla;
            plot(X_contour(:), Y_contour(:), 'k-', 'LineWidth', 2); 
        end
    end
    
    %Foot Progression Angle (FPA) Calculation
    x_med1 = x_selection(1); y_med1 = y_selection(1);
    x_med2 = x_selection(2); y_med2 = y_selection(2);
    x_lat1 = x_selection(3); y_lat1 = y_selection(3);
    x_lat2 = x_selection(4); y_lat2 = y_selection(4);
    MedialAngle = y_med1 - y_med2;
    LateralAngle = y_lat1 - y_lat2;
    mag_MedialAngle = sqrt((x_med1 - x_med2)^2 + (MedialAngle)^2);
    mag_LateralAngle = sqrt((x_lat1 - x_lat2)^2 + (LateralAngle)^2);
    theta_med = acos(MedialAngle / mag_MedialAngle);
    theta_lat = acos(LateralAngle / mag_LateralAngle);
    AverageAngle = (theta_med + theta_lat) / 2;
    FootProgressionAngle = rad2deg(AverageAngle);
else
    FootProgressionAngle = FPA;
end

%Aligning the MPP through FPA rotation and scaling
TargetRows_MPP = 50; % Change as needed, initial 50 and 18 based on control mean following FPA rotation
TargetColumns_MPP = 18;
RotatedPlatform = imrotate(MPP, -FootProgressionAngle, 'bilinear', 'loose');
Rotated_MPP = imrotate(MPP_Box, -FootProgressionAngle, 'bilinear', 'loose');
RotatedPlatform(RotatedPlatform < 10) = 0;
isZero_MPP = (RotatedPlatform ~= 0);
[rowIndices_MPP, colIndices_MPP] = find(isZero_MPP);
minimum_ind_row_MPP = min(rowIndices_MPP);
maximum_ind_row_MPP = max(rowIndices_MPP);
minimum_ind_col_MPP = min(colIndices_MPP);
maximum_ind_col_MPP = max(colIndices_MPP);
max_box_MPP = RotatedPlatform(minimum_ind_row_MPP:maximum_ind_row_MPP, minimum_ind_col_MPP:maximum_ind_col_MPP);
Aligned_MPP = resample_force_preserve(max_box_MPP, TargetRows_MPP, TargetColumns_MPP); % MAIN FUNCTION

%Adding a peak pressure conserved approach to analyze final peak pressure
%locations (using nearest interpolation - keeps peaks close to preserved)
Rotated_MPP_peaks = imrotate(MPP, -FootProgressionAngle, 'nearest', 'loose');
max_box_MPP_peaks = Rotated_MPP_peaks(minimum_ind_row_MPP:maximum_ind_row_MPP, minimum_ind_col_MPP:maximum_ind_col_MPP);
Aligned_MPP_peaks = imresize(max_box_MPP_peaks, [TargetRows_MPP TargetColumns_MPP], 'nearest', 'Antialiasing', true);

%Apply original threshold of 10 kPa to the aligned pressure distribution
Aligned_MPP(Aligned_MPP < 10) = 0;
f4 = figure;
h3 = heatmap(Aligned_MPP, 'MissingDataColor', 'white', 'Colormap', parula);
title('Aligned Maximum Pressure Picture by the FPA (kPa)');
f4.Position = [1160 200 550 850];
colormap(cmap);
caxis([0 Max_MPP_peaks]);

%Save MPP Pictures
cd([FolderPathName,'\',NewFolderName])
savefig(f1, 'MPP_platform.fig');
savefig(f3, 'FPA_Selection.fig');
savefig(f4, 'Aligned_MPP.fig');
    pause(5);
    close all;
disp('Maximum Pressure Distribution Alignment is Complete.');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Plantar Pressure Frames and Stance Intervals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Holder Matrices/Arrays for final data
Rows_peaks = [];
Columns_peaks = [];
Peaks_stance = [];
COP_idx = [];
FivePercentInterval_holder = [];
AlignedInterval_holder = [];

%Load in the sampled frames file
cd(FolderPathName);
FileName_frames = ['FRAME_' num2str(TrialNumber) '.txt'];
fid = fopen(FileName_frames, 'r');

%Count the number of lines the file has to compute the number of frames
LineCount = 0;
while ~feof(fid)
    CurrentLine = fgetl(fid);
    if ischar(CurrentLine)
        LineCount = LineCount + 1;
    end
end
fclose(fid);
NumberFrames = (LineCount - 110) / 108;

%Read in each frame of plantar pressure data
fid = fopen(FileName_frames, 'r');
for i = 1:NumberFrames
    while true
        CurrentLine = fgetl(fid);
        if contains(CurrentLine, '1       2       3')
        % if contains(CurrentLine, '123')
            break;
        end
    end
    RawMatrix = zeros(95, 64); % Platform size
    for row = 1:95
        line = fgetl(fid);
        values = str2num(line);
        RawMatrix(row, :) = values(2:65);
    end
    PressureFrames(:, :, i) = RawMatrix;
end
fclose(fid);

frameSum = squeeze(sum(sum(PressureFrames,1),2));
validFrames = frameSum > 0;
PressureFrames = PressureFrames(:,:,validFrames);

%Interpolate frames into stance intervals (Linear = default)
[nRows, nCols, nFrames] = size(PressureFrames); 
TargetTimepoints = 21; %Number of stance intervals for comparison
OriginalTime = linspace(0, 1, nFrames);
InterpolatedTime = linspace(0, 1, TargetTimepoints);
InterpolatedFrames = zeros(nRows, nCols, TargetTimepoints);
for row = 1:nRows
    for col = 1:nCols
        ts = squeeze(PressureFrames(row, col, :));  % Time series for this pixel
        InterpolatedFrames(row, col, :) = interp1(OriginalTime, ts, InterpolatedTime, 'linear');
    end
end

%Read in each Interval Frame and align for sensor-level comparisons
IntervalSpot = 0;
IntervalCount = 5;
for i = 1:TargetTimepoints
    FivePercent_Interval = InterpolatedFrames(:, :, i);
    FivePercentInterval_holder = [FivePercentInterval_holder, FivePercent_Interval];
    [xGrid_stance, yGrid_stance] = meshgrid(1:size(FivePercent_Interval, 2), 1:size(FivePercent_Interval, 1));
    x_5 = xGrid_stance(:);
    y_5 = yGrid_stance(:);
    y_5 = -y_5;
    z_5 = FivePercent_Interval(:);

    %Convert all left feet to right feet
    if FootSide == 1
        x_5 = -x_5;
        FivePercent_Interval = fliplr(FivePercent_Interval);
    end
    
    f1 = figure;
    h4 = heatmap(FivePercent_Interval, 'MissingDataColor', 'white', 'Colormap', parula);
    Rotated_FRAME = imrotate(FivePercent_Interval, -FootProgressionAngle, 'bilinear', 'loose');
    Rotated_FRAME(Rotated_FRAME < 10) = 0;
    title('Individual Raw Pressure Inerval (kPa)');
    f1.Position = [10 200 550 850];
    colormap(cmap);
    caxis([0 Max_MPP_peaks]);
    f2 = figure;
    h5 = heatmap(Rotated_FRAME, 'MissingDataColor', 'white', 'Colormap', parula);
    title('Rotated Pressure Interval by the FPA (kPa)');
    f2.Position = [585 200 550 850];
    colormap(cmap);
    caxis([0 Max_MPP_peaks]);

    BoundingBox_FRAME = Rotated_FRAME(minimum_ind_row_MPP:maximum_ind_row_MPP, minimum_ind_col_MPP:maximum_ind_col_MPP);
    [x_5, y_5] = meshgrid(1:size(BoundingBox_FRAME, 2), 1:size(BoundingBox_FRAME, 1));
    [xq_5, yq_5] = meshgrid(linspace(1, size(BoundingBox_FRAME, 2), TargetColumns_MPP), linspace(1, size(BoundingBox_FRAME, 1), TargetRows_MPP));
    Aligned_FRAME = resample_force_preserve(BoundingBox_FRAME, TargetRows_MPP, TargetColumns_MPP); %Main Function
    Aligned_FRAME(Aligned_FRAME < 10) = 0;
    AlignedInterval_holder = [AlignedInterval_holder, Aligned_FRAME];
    f3 = figure;
    h6 = heatmap(Aligned_FRAME, 'MissingDataColor', 'white', 'Colormap', parula);
    title('Aligned Pressure Interval (kPa)');
    f3.Position = [1160 200 550 850];
    colormap(cmap);
    caxis([0 Max_MPP_peaks]);

    %Adding a peak pressure conserved approach to analyze final peak pressures
    Rotated_FRAME_peaks = imrotate(FivePercent_Interval, -FootProgressionAngle, 'nearest', 'loose');
    BoundingBox_FRAME_peaks = Rotated_FRAME_peaks(minimum_ind_row_MPP:maximum_ind_row_MPP, minimum_ind_col_MPP:maximum_ind_col_MPP);
    Aligned_FRAME_peaks = imresize(BoundingBox_FRAME_peaks, [TargetRows_MPP TargetColumns_MPP], 'nearest', 'Antialiasing', true);
    [M,I] = max(Aligned_FRAME_peaks);
    M2 = max(M);
    Peaks_across_stance = [];     %Saving location and peak values throughout stance
    Locations = [];
    for i = 1:18 %number of rows
        peak_I = M(i);
        if peak_I == M2;
            Peaks_across_stance = [Peaks_across_stance, peak_I];
            Locations = [Locations; [i, I(i)]];
        end
    end
    avg_row_peaks = round(mean(Locations(:,1)));
    avg_column_peaks = round(mean(Locations(:,2)));
    Rows_peaks = [Rows_peaks; avg_row_peaks];
    Columns_peaks = [Columns_peaks; avg_column_peaks];
    Peaks_stance = [Peaks_stance; M2];

    %Adding a COP analysis from aligned pressure distributions
    COP_mask = Aligned_FRAME > 10;
    valuesAbove = Aligned_FRAME(COP_mask);
    [rowIdx, colIdx] = find(COP_mask);
    COP_row = round(mean(rowIdx, 'Weights', valuesAbove),2);
    COP_col = round(mean(colIdx, 'Weights', valuesAbove),2);
    COP_idx = [COP_idx; [COP_row, COP_col]];
    COP_idx = COP_idx(~any(isnan(COP_idx), 2), :);

    %Save Interval Figures
    cd([FolderPathName,'\',NewFolderName]);
    figureName_1 = ['Raw_Interval', num2str(IntervalSpot), '.fig'];
    figureName_2 = ['Aligned_Interval', num2str(IntervalSpot), '.fig'];
    savefig(f1, figureName_1);
    savefig(f3, figureName_2);
        pause(5);
        close all;
    IntervalSpot = IntervalSpot + IntervalCount;
end

%Plotting Peak Pressure Locations and COP Line (Aligned)
Peaks_throughStance = zeros(50,18);
Peak_ids = [Columns_peaks, Rows_peaks];
for i = 1:21
    peak_replace = Peak_ids(i,:);
    peaks_val_rep = Peaks_stance(i);
    Peaks_throughStance(peak_replace(1), peak_replace(2)) = peaks_val_rep;
end
f4 = figure;
h7 = heatmap(Peaks_throughStance, 'MissingDataColor', 'white', 'Colormap', parula);
title('Peak Pressures Throughout Stance - Aligned (kPa)');
f4.Position = [585 200 550 850];
colormap(cmap);
caxis([0 Max_MPP_peaks]);
f5 = figure;
imagesc(Aligned_MPP);
colormap(cmap);
caxis([0 Max_MPP_peaks]);
hold on;
plot(COP_idx(:,2), COP_idx(:,1), 'Color', 'r', 'LineWidth', 2.5);
title('COP Line on Maximum Pressure Distribution');
f5.Position = [1160 200 550 850];
savefig(f4, 'Peak_Pressures_Aligned_Stance.fig');
savefig(f5, 'COP_Aligned.fig');
disp('Stance Interval Alignment is Complete, beginning Excel Outputs.');
pause(5);
close all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Export data to an excel spreadsheet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ExcelFileName = 'Aligned_Pressure_Data.xlsx';
format bank % Set format to display numbers without scientific notation

%Save the FPA and maximum pressure distribution data to sheet 1
FPA_words = cellstr('FPA');
FPA_Table = [FPA_words, FootProgressionAngle];
writecell(FPA_Table, ExcelFileName, 'Sheet', 1, 'Range', 'A1:B1');
MPP_Aligned_words = cellstr('Aligned MPP');
writecell(MPP_Aligned_words, ExcelFileName, 'Sheet', 1, 'Range', 'A3:B3')
Aligned_MPP_rounded = round(Aligned_MPP, 3);
writematrix(Aligned_MPP_rounded, ExcelFileName, 'Sheet', 1, 'Range', 'A4:R53');
MPP_Aligned_words = cellstr('Original MPP');
writecell(MPP_Aligned_words, ExcelFileName, 'Sheet', 1, 'Range', 'T3:U3')
writematrix(MPP_Box, ExcelFileName, 'Sheet', 1, 'Range', 'T4:BG73');
MPPpeaks_Aligned_words = cellstr('Aligned MPP - Peaks Focused (nearest interpolation)');
writecell(MPPpeaks_Aligned_words, ExcelFileName, 'Sheet', 1, 'Range', 'AQ3:AR3')
writematrix(Aligned_MPP_peaks, ExcelFileName, 'Sheet', 1, 'Range', 'AQ4:BH53');

%Save the individual stance interval data to sheet 2
Peak_Stance_words = cellstr('Peak Values Across Stance');
writecell(Peak_Stance_words, ExcelFileName, 'Sheet', 2, 'Range', 'A1:C3')
peak_stance_Table = [0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,...
    85,90,95,100; Peaks_stance'];
writematrix(peak_stance_Table, ExcelFileName, 'Sheet', 2, 'Range', 'B2:V3');
Aligned_Stance_rounded = round(AlignedInterval_holder, 3);
Aligned_Stance_words = cellstr('Aligned Stance Intervals');
writecell(Aligned_Stance_words, ExcelFileName, 'Sheet', 2, 'Range', 'A5:B5');
writematrix(Aligned_Stance_rounded, ExcelFileName, 'Sheet', 2, 'Range', 'A6:OJ55');
Original_Stance_words = cellstr('Original Stance Intervals');
writecell(Original_Stance_words, ExcelFileName, 'Sheet', 2, 'Range', 'A57:B57');
writematrix(FivePercentInterval_holder, ExcelFileName, 'Sheet', 2, 'Range', 'A59:DKJ154');

%Save the COP data to sheet 3
COP_idx_new = COP_idx(:,2) .* TargetRows_MPP;
COP_idx_new = COP_idx_new + COP_idx(:,1);
COP_idx_new(isnan(COP_idx_new)) = COP_idx_new(20);
% Adding zeros to the end of COP indices if the last frames do not contain 
% pressure values larger than the 10 kPa threshold.
if length(COP_idx) < 20
    COP_idx = [COP_idx; [0,0]; [0,0]];
elseif length(COP_idx) < 21
    COP_idx = [COP_idx; [0,0]];
end
COP_words = cellstr('COP Indices for Aligned Distributions');
writecell(COP_words, ExcelFileName, 'Sheet', 3, 'Range', 'A1:B1');
writematrix(COP_idx, ExcelFileName, 'Sheet', 3, 'Range', 'A3:B30');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Creating Gifs of Stance Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
outputGif = 'plantar_progression.gif';
for i = 1:21
    metric = i * 18;
    Stance_frame = Aligned_Stance_rounded(:, metric-17:metric);
    figure('Units','pixels','Position',[100 100 400 800]); % fix figure size
    imagesc(Stance_frame);
    colormap(cmap);
    % colormap(hot);
    caxis([cbar_min cbar_max]);
    colorbar;
    axis tight off; 
    set(gca, 'Position', [0 0 1 1])
    
    % Capture frame
    frame = getframe(gcf);
    im = frame2im(frame);
    [A, map] = rgb2ind(im, 256);
    
    % Write to GIF
    if i == 1;
        imwrite(A, map, outputGif, 'gif', 'LoopCount', Inf, 'DelayTime', 0.2);
    else
        imwrite(A, map, outputGif, 'gif', 'WriteMode', 'append', 'DelayTime', 0.2);
    end
    pause(5);
    close;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Code is Complete!');