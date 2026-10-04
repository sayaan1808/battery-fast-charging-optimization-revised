function [p,decision]=select_tested_profile(initialSOC,temperatureC)
% Select a request from the executed operating-condition grid.
% Outside that grid, return the conservative baseline with no validation claim.
p=project_parameters();p.SOC0=initialSOC;p.T0=temperatureC+273.15;p.Tamb=p.T0;
r=readtable(fullfile(p.root,'results','simscape_robustness.csv'));
hit=abs(r.initial_soc-initialSOC)<1e-8 & abs(r.temperature_C-temperatureC)<1e-8;
decision=struct('profile','CCCV_baseline','tested_initial_condition',any(hit),'reason','Baseline fallback; initial condition is outside the tested grid.');
if any(hit)
 fast=r(hit & r.profile==2,:);
 if ~isempty(fast) && fast.feasible(1)
  b=load(fullfile(p.root,'results','simscape_optimization.mat'),'best');p.Istages=b.best.currents_A;p.SOCswitch=b.best.switch_soc;
  decision.profile='optimized';decision.reason='Staged profile completed this exact nominal-cell initial-condition test.';
 else
  decision.reason='Staged profile tripped a constraint in this test; the tested baseline is selected.';
 end
end
end
