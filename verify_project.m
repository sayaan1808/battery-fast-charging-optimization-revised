function checks=verify_project()
p=project_parameters();checks=struct;
files=dir(fullfile(p.root,'matlab','*.m'));issues={};
for k=1:numel(files)
 d=checkcode(fullfile(files(k).folder,files(k).name),'-id');
 for j=1:numel(d)
  if any(strcmp(d(j).id,{'PARSE','SYNER','ENDCT','MISLP'})),issues{end+1}=sprintf('%s:%d %s',files(k).name,d(j).line,d(j).message);end %#ok<AGROW>
 end
end
checks.parse_issues=issues;checks.matlab_release=version('-release');
if isfile(fullfile(p.root,'results','simscape_comparison.csv'))
 d=readtable(fullfile(p.root,'results','simscape_comparison.csv'));checks.all_comparison_targets_reached=all(d.target_reached);checks.all_comparison_feasible=all(d.feasible);
end
if isfile(fullfile(p.root,'results','simscape_convergence.json'))
 d=jsondecode(fileread(fullfile(p.root,'results','simscape_convergence.json')));checks.convergence_time_under_1percent=abs(d.time_difference_percent)<1;checks.convergence_voltage_under_10mV=abs(d.voltage_difference_mV)<10;
end
checks.coulomb_counting=struct([]);initialOK=true;solidOK=true;
for name={'CCCV_baseline','two_stage','three_stage','four_stage','adaptive','optimized','collocation_replay','rl_replay','high_soc_CCCV','refined'}
 d=readtable(fullfile(p.root,'results',['simscape_' name{1} '.csv']));
 q=trapz(d.time_s,d.current_charge_A)/3600;expected=p.Q_Ah*(d.soc(end)-d.soc(1));
 checks.coulomb_counting=[checks.coulomb_counting;struct('case',name{1},'delivered_Ah',q,'soc_equivalent_Ah',expected,'absolute_error_Ah',abs(q-expected))]; %#ok<AGROW>
 initialOK=initialOK && abs(d.core_C(1)-25)<.05 && abs(d.surface_C(1)-25)<.05 && abs(d.electrolyte_min_mol_m3(1)-1000)<.05;
 solidOK=solidOK && all(d.anode_surface_mol_m3/p.MaximumConcentrationAnode<.98);
end
checks.initial_states_match=initialOK;checks.solid_surface_below_98percent=solidOK;
checks.coulomb_error_under_1mAh=all([checks.coulomb_counting.absolute_error_Ah]<.001);
r=readtable(fullfile(p.root,'results','simscape_robustness.csv'));checks.robustness_runs=height(r);checks.all_robustness_feasible=all(r.feasible);
v=readtable(fullfile(p.root,'results','simscape_validation_metrics.csv'));checks.all_validation_windows_complete=all(v.coverage_fraction>.99999);
checks.experimental_voltage_RMSE_mV=v.voltage_RMSE_after_mV;checks.experimental_temperature_RMSE_C=v.temperature_RMSE_C;
a=readtable(fullfile(p.root,'results','aging_summary.csv'));checks.aging_cycle_rows=height(a);checks.aging_proxy_in_0_to_1=all(a.lithium_inventory_SOH_proxy>=0 & a.lithium_inventory_SOH_proxy<=1);
reg=jsondecode(fileread(fullfile(p.root,'verification','revision_regressions.json')));
checks.protection_regressions_pass=reg.passed;
checks.model_has_no_root=~isfield(evalin(get_param('BatteryFastCharging','ModelWorkspace'),'p'),'root');
checks.technical_checks_pass=isempty(issues) && checks.all_comparison_feasible && initialOK && checks.coulomb_error_under_1mAh && checks.convergence_time_under_1percent && checks.convergence_voltage_under_10mV && checks.all_validation_windows_complete && height(a)==12 && checks.aging_proxy_in_0_to_1 && checks.all_robustness_feasible && reg.passed && checks.model_has_no_root;
fid=fopen(fullfile(p.root,'verification','final_checks.json'),'w');fprintf(fid,'%s',jsonencode(checks,PrettyPrint=true));fclose(fid);
disp(checks);
assert(checks.technical_checks_pass,'One or more final technical checks failed; inspect final_checks.json.');
end
