function mdl=build_simscape_model(p,mdl)
% Construct the actual Simscape Battery plant and built-in Battery CC-CV loop.
if nargin<1,p=project_parameters();end
if nargin<2,mdl='BatteryFastCharging';end
if bdIsLoaded(mdl),close_system(mdl,0);end
load_system('batt_lib');load_system('BatteryCurrentManagement');load_system('fl_lib');load_system('nesl_utility');
new_system(mdl);
set_param(mdl,'Solver','ode23t','RelTol','1e-5','AbsTol','1e-7','MaxStep','1','StopTime','p.Duration','ReturnWorkspaceOutputs','on');
[q,root]=prepare_case(p);mw=get_param(mdl,'ModelWorkspace');assignin(mw,'p',q);
add("batt_lib/Cells/Electrochemical/Battery Single"+newline+"Particle",'Cell',[680 180 780 290]);
dp=get_param([mdl '/Cell'],'DialogParameters');
fn=fieldnames(p);
for k=1:numel(fn)
 if isfield(dp,fn{k}),set_param([mdl '/Cell'],fn{k},['p.' fn{k}]);end
end
set_param([mdl '/Cell'],'StoichiometryBreakpointsSpecification','simscape.battery.enum.cells.electrochemical.StoichiometryBreakpointsSpecification.absolute',...
 'AbsoluteStoichiometryBreakpointsAnode','p.Sto','AbsoluteStoichiometryBreakpointsCathode','p.Sto',...
 'OpenCircuitPotentialAbsoluteAnode','p.Un','OpenCircuitPotentialAbsoluteCathode','p.Up',...
 'ShellCountAnode','p.Shells','ShellCountCathode','p.Shells',...
 'ElectrolyteLayerCountAnode','p.LayersAnode','ElectrolyteLayerCountCathode','p.LayersCathode','ElectrolyteLayerCountSeparator','p.LayersSeparator',...
 'stateOfCharge','p.SOC0','stateOfCharge_specify','on','stateOfCharge_priority','High',...
 'batteryTemperature','p.T0','batteryTemperature_specify','on','batteryTemperature_priority','High',...
 'averageElectrolyteConcentration','1000','averageElectrolyteConcentration_specify','on','averageElectrolyteConcentration_priority','High');
set_param([mdl '/Cell'],'InnerSEIMethod','simscape.battery.enum.cells.electrochemical.InnerSEIMethod.none','PlatingMethod','simscape.battery.enum.cells.electrochemical.PlatingMethod.none',...
 'MolarVolumeInnerSEI','9.585e-5','DiffusionCoefficientInnerSEI','1e-20','ConductivityInnerSEI','5e-6','DiffusionActivationEnergyInnerSEI','1e-6','thicknessSEI','p.InitialSEI','thicknessSEI_specify','on','thicknessSEI_priority','High');
add("fl_lib/Electrical/Electrical Sources/Controlled Current"+newline+"Source",'CurrentSource',[550 175 600 240]);
add('fl_lib/Electrical/Electrical Elements/Electrical Reference','ElectricalReference',[630 310 665 345]);
add("nesl_utility/Solver"+newline+"Configuration",'Solver',[530 315 575 350]);
add("nesl_utility/Simulink-PS"+newline+"Converter",'CurrentToPhysical',[460 195 505 225]);set_param([mdl '/CurrentToPhysical'],'Unit','A');
add('nesl_utility/Probe','CellProbe',[820 160 940 420]);
vars=sort(["anodeElectrolyteOverpotential","anodeModel.surfaceConcentration","batteryCurrent","batteryTemperature","batteryVoltage","electrolyteModel.concentrationAnode","electrolyteModel.concentrationCathode","electrolyteModel.concentrationSeparator","irreversiblePlatedMaterial","reversiblePlatedMaterial","stateOfCharge","thicknessSEI"]);
simscape.probe.setBoundBlock([mdl '/CellProbe'],[mdl '/Cell']);simscape.probe.setVariables([mdl '/CellProbe'],vars);
add('fl_lib/Thermal/Thermal Elements/Thermal Resistance','CoreToSurface',[680 400 740 445]);
add('fl_lib/Thermal/Thermal Elements/Thermal Mass','SurfaceMass',[770 465 825 505]);
add('fl_lib/Thermal/Thermal Elements/Thermal Resistance','SurfaceToAmbient',[855 420 915 460]);
add('fl_lib/Thermal/Thermal Sources/Temperature Source','Ambient',[965 440 1020 480]);
set_param([mdl '/CoreToSurface'],'resistance','p.RcoreSurface');
set_param([mdl '/SurfaceToAmbient'],'resistance','p.RsurfaceAmbient');
set_param([mdl '/SurfaceMass'],'mass','1','sp_heat','p.Csurface','T','p.T0','T_specify','on','T_priority','High');
set_param([mdl '/Ambient'],'temperature','p.Tamb');
add('nesl_utility/Probe','SurfaceProbe',[890 520 980 555]);simscape.probe.setBoundBlock([mdl '/SurfaceProbe'],[mdl '/SurfaceMass']);simscape.probe.setVariables([mdl '/SurfaceProbe'],'T');
% Physical network: source injects current into the positive battery terminal.
ph=ports('Cell');src=ports('CurrentSource');ref=ports('ElectricalReference');sv=ports('Solver');pc=ports('CurrentToPhysical');
wire(src.LConn(1),ph.LConn(1));wire(src.RConn(2),ph.RConn(1));wire(ph.RConn(1),ref.LConn(1));wire(ref.LConn(1),sv.RConn(1));wire(pc.RConn(1),src.RConn(1));
cs=ports('CoreToSurface');sa=ports('SurfaceToAmbient');sm=ports('SurfaceMass');am=ports('Ambient');
wire(ph.RConn(2),cs.LConn(1));wire(cs.RConn(1),sm.LConn(1));wire(sm.LConn(1),sa.LConn(1));wire(sa.RConn(1),am.LConn(1));
% SOC for comparisons uses a common 5 Ah coulomb-counting definition.
add('simulink/Math Operations/Gain','CoulombGain',[1060 220 1110 250]);set_param([mdl '/CoulombGain'],'Gain','1/(3600*p.Q_Ah)');
add('simulink/Continuous/Integrator','ProjectSOC',[1150 220 1195 250]);set_param([mdl '/ProjectSOC'],'InitialCondition','p.SOC0');
line('CellProbe',idx('batteryCurrent'),'CoulombGain',1);line('CoulombGain',1,'ProjectSOC',1);
% A discrete supervisor avoids an algebraic loop through electrochemical limits.
add('simulink/Ports & Subsystems/Subsystem','Supervisor',[160 125 300 265]);
configure_supervisor([mdl '/Supervisor']);
add('simulink/Sources/From Workspace','Stages',[20 320 95 350]);set_param([mdl '/Stages'],'VariableName','p.ProfileData','Interpolate','on','SampleTime','p.Ts');
add('simulink/Sources/Constant','SwitchSOC',[20 370 95 400]);set_param([mdl '/SwitchSOC'],'Value','p.SOCswitch');
add('simulink/Discrete/Zero-Order Hold','SampleSOC',[30 25 80 50]);set_param([mdl '/SampleSOC'],'SampleTime','p.Ts');line('ProjectSOC',1,'SampleSOC',1);line('SampleSOC',1,'Supervisor',1);
signals={'batteryTemperature','batteryVoltage','anodeElectrolyteOverpotential'};
for k=1:3
 nm=['Sample' num2str(k)];add('simulink/Discrete/Zero-Order Hold',nm,[30 55+45*k 80 80+45*k]);set_param([mdl '/' nm],'SampleTime','p.Ts');line('CellProbe',idx(signals{k}),nm,1);line(nm,1,'Supervisor',k+1);
end
% Reduce each region independently, then take the scalar minimum.
add('simulink/Math Operations/MinMax','MinAcrossSpace',[1130 340 1175 375]);set_param([mdl '/MinAcrossSpace'],'Function','min','Inputs','3');
regions={'Anode','Separator','Cathode'};
for k=1:3
 nm=['Min' regions{k}];add('simulink/Math Operations/MinMax',nm,[1040 310+45*k 1085 340+45*k]);set_param([mdl '/' nm],'Function','min','Inputs','1');
 line('CellProbe',idx(['electrolyteModel.concentration' regions{k}]),nm,1);line(nm,1,'MinAcrossSpace',k);
end
add('simulink/Discrete/Zero-Order Hold','SampleCe',[95 280 140 310]);set_param([mdl '/SampleCe'],'SampleTime','p.Ts');line('MinAcrossSpace',1,'SampleCe',1);line('SampleCe',1,'Supervisor',5);
add('simulink/Discrete/Zero-Order Hold','SampleCurrent',[95 325 140 350]);set_param([mdl '/SampleCurrent'],'SampleTime','p.Ts');line('CellProbe',idx('batteryCurrent'),'SampleCurrent',1);line('SampleCurrent',1,'Supervisor',6);
line('Stages',1,'Supervisor',7);line('SwitchSOC',1,'Supervisor',8);
add('simulink/Sources/Digital Clock','ControlClock',[20 420 90 450]);set_param([mdl '/ControlClock'],'SampleTime','p.Ts');line('ControlClock',1,'Supervisor',9);
add('BatteryCurrentManagement/Battery CC-CV','CCCV',[335 120 425 260]);
set_param([mdl '/CCCV'],'MaxCellVoltage','p.Vcontrol','Kp','20','Ki','2','Kaw','1','Kt','1','Ts','p.Ts');
add('simulink/Sources/Constant','ChargingEnabled',[190 30 260 55]);set_param([mdl '/ChargingEnabled'],'Value','true','OutDataTypeStr','boolean');
add('simulink/Sources/Constant','ZeroDischarge',[210 325 265 350]);set_param([mdl '/ZeroDischarge'],'Value','0');
line('ChargingEnabled',1,'CCCV',1);line('CellProbe',idx('batteryVoltage'),'CCCV',2);line('Supervisor',1,'CCCV',3);line('ZeroDischarge',1,'CCCV',4);
add('simulink/Sources/From Workspace','ExternalCurrent',[320 480 410 510]);set_param([mdl '/ExternalCurrent'],'VariableName','p.InputCurrent','Interpolate','on','SampleTime','p.Ts');
add('simulink/Sources/Constant','UseExternalCurrent',[320 540 410 570]);set_param([mdl '/UseExternalCurrent'],'Value','p.UseExternalCurrent');
line('ExternalCurrent',1,'Supervisor',10);line('UseExternalCurrent',1,'Supervisor',11);
add('simulink/Signal Routing/Switch','CurrentMode',[455 425 500 480]);set_param([mdl '/CurrentMode'],'Threshold','0.5');
line('ExternalCurrent',1,'CurrentMode',1);line('Supervisor',6,'CurrentMode',2);line('CCCV',1,'CurrentMode',3);
add('simulink/Discontinuities/Saturation','CurrentLimit',[440 130 485 160]);set_param([mdl '/CurrentLimit'],'UpperLimit','p.Imax','LowerLimit','-p.ImaxDischarge');line('CurrentMode',1,'CurrentLimit',1);
add('simulink/Logic and Bit Operations/Logical Operator','TerminalEvent',[335 295 380 330]);set_param([mdl '/TerminalEvent'],'Operator','OR','Inputs','2');line('Supervisor',2,'TerminalEvent',1);line('Supervisor',3,'TerminalEvent',2);
add('simulink/Logic and Bit Operations/Logical Operator','Running',[400 350 435 375]);set_param([mdl '/Running'],'Operator','NOT');line('TerminalEvent',1,'Running',1);
add('simulink/Math Operations/Product','FinalGate',[490 340 520 375]);line('CurrentLimit',1,'FinalGate',1);line('Running',1,'FinalGate',2);
add('simulink/Continuous/Transfer Fcn','ActuatorDynamics',[520 425 615 460]);set_param([mdl '/ActuatorDynamics'],'Numerator','1','Denominator','[p.ActuatorTau 1]');line('FinalGate',1,'ActuatorDynamics',1);line('ActuatorDynamics',1,'CurrentToPhysical',1);
add('simulink/Sinks/Stop Simulation','Stop',[425 290 470 325]);line('Supervisor',4,'Stop',1);
% Log a compact matrix and retain the full Simscape log separately.
logNames={'time_s','current_charge_A','voltage_V','soc','core_K','surface_K','anode_potential_V','anode_surface_mol_m3','electrolyte_min_mol_m3','internal_soc','fault','sei_m','irreversible_plating_mol','reversible_plating_mol','complete','stop_after_settling','termination_reason','command_current_A','thermal_limit_A','anode_limit_A','electrolyte_limit_A','requested_current_A','binding_limiter','aging_enabled','characterization_replay'};
add('simulink/Signal Routing/Mux','Measurements',[1250 60 1255 400]);set_param([mdl '/Measurements'],'Inputs','21');
add('simulink/Sources/Clock','Clock',[1150 65 1190 90]);line('Clock',1,'Measurements',1);
line('CellProbe',idx('batteryCurrent'),'Measurements',2);line('CellProbe',idx('batteryVoltage'),'Measurements',3);line('ProjectSOC',1,'Measurements',4);
line('CellProbe',idx('batteryTemperature'),'Measurements',5);line('SurfaceProbe',1,'Measurements',6);line('CellProbe',idx('anodeElectrolyteOverpotential'),'Measurements',7);
line('CellProbe',idx('anodeModel.surfaceConcentration'),'Measurements',8);line('MinAcrossSpace',1,'Measurements',9);line('CellProbe',idx('stateOfCharge'),'Measurements',10);
add('simulink/Signal Attributes/Data Type Conversion','FaultToDouble',[1150 435 1200 465]);set_param([mdl '/FaultToDouble'],'OutDataTypeStr','double');line('Supervisor',3,'FaultToDouble',1);line('FaultToDouble',1,'Measurements',11);
% Inactive degradation states are explicitly missing, never a physical measurement.
agingVars={'thicknessSEI','irreversiblePlatedMaterial','reversiblePlatedMaterial'};
add('simulink/Sources/Constant','AgingEnabled',[990 660 1060 690]);set_param([mdl '/AgingEnabled'],'Value','double(p.EnableAging)');
add('simulink/Sources/Constant','InactiveAging',[990 710 1060 740]);set_param([mdl '/InactiveAging'],'Value','NaN');
for k=1:3
 nm=['AgingChannel' num2str(k)];add('simulink/Signal Routing/Switch',nm,[1110 550+45*k 1150 580+45*k]);set_param([mdl '/' nm],'Threshold','.5');
 line('CellProbe',idx(agingVars{k}),nm,1);line('AgingEnabled',1,nm,2);line('InactiveAging',1,nm,3);line(nm,1,'Measurements',11+k);
end
statusPorts=[2 4 5];
for k=1:3
 nm=['StatusDouble' num2str(k)];add('simulink/Signal Attributes/Data Type Conversion',nm,[1170 490+45*k 1220 520+45*k]);set_param([mdl '/' nm],'OutDataTypeStr','double');
 line('Supervisor',statusPorts(k),nm,1);line(nm,1,'Measurements',14+k);
end
line('FinalGate',1,'Measurements',18);line('Supervisor',7,'Measurements',19);line('AgingEnabled',1,'Measurements',20);
add('simulink/Sources/Constant','CharacterizationMode',[990 760 1080 790]);set_param([mdl '/CharacterizationMode'],'Value','double(p.CharacterizationReplay)');line('CharacterizationMode',1,'Measurements',21);
add('simulink/Sinks/To Workspace','Record',[1320 180 1400 220]);set_param([mdl '/Record'],'VariableName','trace','SaveFormat','Array');line('Measurements',1,'Record',1);
assignin(mw,'logNames',logNames);
set_param(mdl,'InitFcn',"addpath(fullfile(fileparts(get_param(bdroot,'FileName')),'matlab'));");
set_param(mdl,'Location',[0 0 1500 700],'SimscapeLogType','all');
save_system(mdl,fullfile(root,[mdl '.slx']));
fprintf('Built %s\n',fullfile(root,[mdl '.slx']));
function add(src,name,pos),add_block(char(src),[mdl '/' name],'Position',pos);end
function h=ports(n),h=get_param([mdl '/' n],'PortHandles');end
function wire(a,b),add_line(mdl,a,b,'autorouting','on');end
function line(a,ap,b,bp),add_line(mdl,[a '/' num2str(ap)],[b '/' num2str(bp)],'autorouting','on');end
function i=idx(v),i=find(vars==string(v),1);end
end
