function [metrics,traces]=run_cases(cases,names)
% Independent SimulationInput runs, restored after execution by Simulink.
model='BatteryFastCharging';p=cases{1};
if ~bdIsLoaded(model),load_system(fullfile(p.root,[model '.slx']));end
for k=numel(cases):-1:1,inputs(k)=make_simulation_input(cases{k},model);end
if isempty(gcp('nocreate')),parpool('Processes',2);end
outputs=parsim(inputs,'ShowProgress','on','UseFastRestart','off',...
 'TransferBaseWorkspaceVariables','off');
metrics=struct([]);traces=cell(size(cases));
for k=1:numel(cases)
 assert(isempty(outputs(k).ErrorMessage),'Case %s failed: %s',names{k},outputs(k).ErrorMessage);
 [row,traces{k}]=summarize_case(cases{k},names{k},outputs(k),model);
 metrics=[metrics;row]; %#ok<AGROW>
end
end
