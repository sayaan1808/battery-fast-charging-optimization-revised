% Run from the project folder to open the saved, self-contained nominal model.
projectFolder=fileparts(mfilename('fullpath'));
addpath(fullfile(projectFolder,'matlab'),fullfile(projectFolder,'report'));
open_system(fullfile(projectFolder,'BatteryFastCharging.slx'));
disp('Model opened. Run run_project to reproduce all studies.');
