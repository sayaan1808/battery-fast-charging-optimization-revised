function configure_supervisor(ss)
% Reviewable MATLAB Function logic with individually named inputs.
Simulink.SubSystem.deleteContents(ss);
inputs={'z','T','V','psi','ce','Iapplied','stages','sw','t','external','useExternal'};
outputs={'CurrentCeiling','Complete','Fault','StopAfterSettling','TerminationReason','AllowExternal','LimiterDiagnostics'};
for k=1:numel(inputs)
 add_block('simulink/Ports & Subsystems/In1',[ss '/' inputs{k}],'Port',num2str(k),'Position',[20 30+35*k 45 45+35*k]);
end
add_block('simulink/User-Defined Functions/MATLAB Function',[ss '/Control'],'Position',[210 110 435 340]);
chart=find(sfroot,'-isa','Stateflow.EMChart','Path',[ss '/Control']);
chart.Script=fileread(fullfile(fileparts(mfilename('fullpath')),'supervisor_step.m'));
parameter=find(chart,'-isa','Stateflow.Data','Name','p');parameter.Scope='Parameter';
for k=1:numel(inputs),add_line(ss,[inputs{k} '/1'],['Control/' num2str(k)],'autorouting','on');end
for k=1:numel(outputs)
 add_block('simulink/Ports & Subsystems/Out1',[ss '/' outputs{k}],'Port',num2str(k),'Position',[610 50+45*k 640 65+45*k]);
 add_line(ss,['Control/' num2str(k)],[outputs{k} '/1'],'autorouting','on');
end
end
