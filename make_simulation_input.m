function in=make_simulation_input(p,model)
% Per-run overrides are restored by SimulationInput; no saved-model mutation.
if nargin<2,model='BatteryFastCharging';end
[q,~]=prepare_case(p);
in=Simulink.SimulationInput(model);in=in.setVariable('p',q,'Workspace',model);
in=in.setModelParameter('StopTime',num2str(p.Duration),'MaxStep',num2str(p.MaxStep),...
 'RelTol',num2str(p.RelTol),'AbsTol',num2str(p.AbsTol),'ReturnWorkspaceOutputs','on');
if p.EnableAging
 sei='simscape.battery.enum.cells.electrochemical.InnerSEIMethod.diffusionLimitedSEIGrowth';
 plating='simscape.battery.enum.cells.electrochemical.PlatingMethod.fractionalReversiblePlating';
else
 sei='simscape.battery.enum.cells.electrochemical.InnerSEIMethod.none';
 plating='simscape.battery.enum.cells.electrochemical.PlatingMethod.none';
end
in=in.setBlockParameter([model '/Cell'],'InnerSEIMethod',sei);
in=in.setBlockParameter([model '/Cell'],'PlatingMethod',plating);
end
