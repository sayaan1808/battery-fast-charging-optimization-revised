function mdl=build_rl_model(p)
% The agent requests current from the SAME electrochemical and thermal plant.
mdl=build_simscape_model(p,'BatteryFastChargingRL');load_system('rllib');
ph=get_param([mdl '/ExternalCurrent'],'PortHandles');
delete_line(get_param(ph.Outport(1),'Line'));
delete_block([mdl '/ExternalCurrent']);
set_param([mdl '/UseExternalCurrent'],'Value','1');
add_block('rllib/RL Agent',[mdl '/RL Agent'],'Position',[170 830 340 930]);
set_param([mdl '/RL Agent'],'Agent','chargingAgent');
add_block('simulink/User-Defined Functions/MATLAB Function',[mdl '/ObservationReward'],'Position',[900 830 1160 1020]);
chart=find(sfroot,'-isa','Stateflow.EMChart','Path',[mdl '/ObservationReward']);
chart.Script=fileread(fullfile(fileparts(mfilename('fullpath')),'rl_observation_step.m'));
parameter=find(chart,'-isa','Stateflow.Data','Name','p');parameter.Scope='Parameter';
sources={'ProjectSOC','Sample1','MinAcrossSpace','SampleCurrent','Supervisor','Supervisor'};
ports=[1 1 1 1 2 3];
for k=1:6
 nm=['RLsample' num2str(k)];
 if k>=5,library='simulink/Discrete/Unit Delay';else,library='simulink/Discrete/Zero-Order Hold';end
 add_block(library,[mdl '/' nm],...
 'SampleTime','p.RLsampleTime','Position',[700 760+45*k 750 790+45*k]);
 add_line(mdl,[sources{k} '/' num2str(ports(k))],[nm '/1'],'autorouting','on');
 add_line(mdl,[nm '/1'],['ObservationReward/' num2str(k)],'autorouting','on');
end
for k=1:3,add_line(mdl,['ObservationReward/' num2str(k)],['RL Agent/' num2str(k)],'autorouting','on');end
add_line(mdl,'RL Agent/1','Supervisor/10','autorouting','on');
add_line(mdl,'RL Agent/1','CurrentMode/1','autorouting','on');
delete_line(mdl,'Supervisor/4','Stop/1');add_line(mdl,'ObservationReward/3','Stop/1','autorouting','on');
set_param(mdl,'SimscapeLogType','none');
save_system(mdl,fullfile(p.root,[mdl '.slx']));
end
