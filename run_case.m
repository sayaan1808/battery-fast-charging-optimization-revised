function [m,tbl,out]=run_case(p,name)
% All variants share per-run parameters, protection, logging and assessment.
if nargin<2,name='case';end
mdl='BatteryFastCharging';
if ~bdIsLoaded(mdl),load_system(fullfile(p.root,[mdl '.slx']));end
out=sim(make_simulation_input(p,mdl));
[m,tbl]=summarize_case(p,name,out,mdl);
end
