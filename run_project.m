function status=run_project()
% Reproduce the complete revision; never report a partial pipeline as a pass.
p=project_parameters();addpath(fullfile(p.root,'matlab'),fullfile(p.root,'report'));
for folder={'results','figures','verification'},if ~isfolder(fullfile(p.root,folder{1})),mkdir(fullfile(p.root,folder{1}));end,end
steps={@()build_simscape_model(p),@revision_regression_tests,@battery_diagnostics,@run_simscape_study,@optimize_simscape,@validate_experiments,@()direct_collocation(p),@()learn_charging_policy(p),@robustness_and_replay,@aging_study,@additional_validation,@finalize_project,@build_report,@record_demo};
names={'model_build','protection_regressions','native_battery_diagnostics','charging_comparison','simscape_optimization','SDO_experimental_validation','direct_collocation','RL_full_plant','parallel_robustness_and_refinement','aging','charge_validation_and_sensitivity','final_checks','native_report','recorded_trace_demo'};
status=struct([]);
for k=1:numel(steps)
 stageTimer=tic;
 try
  steps{k}();entry=struct('step',names{k},'executed',true,'error','','wall_seconds',toc(stageTimer));
 catch e
  entry=struct('step',names{k},'executed',false,'error',getReport(e,'extended','hyperlinks','off'),'wall_seconds',toc(stageTimer));warning('%s failed: %s',names{k},e.message);
 end
 status=[status;entry]; %#ok<AGROW>
 write_json(fullfile(p.root,'verification','pipeline_status.json'),status);
end
assert(all([status.executed]),'Required pipeline stages failed; inspect verification/pipeline_status.json.');
end
