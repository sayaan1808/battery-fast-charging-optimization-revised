function [q,root]=prepare_case(p)
% Validate runtime inputs and remove machine-specific paths from model data.
root=fileparts(fileparts(mfilename('fullpath')));
if isfield(p,'root'),root=p.root;p=rmfield(p,'root');end
assert(p.Imax>0 && p.ImaxDischarge>=0,'Invalid current bounds.');
assert(p.ElectrolyteGain>0 && p.ElectrolyteSoftMargin>=0,'Invalid electrolyte derate.');
assert(all([p.LayersAnode p.LayersSeparator p.LayersCathode]>=1),'Invalid electrolyte layer counts.');
assert(p.ShutdownMaxTime>p.ShutdownMinTime,'Invalid shutdown settling window.');
assert(p.Vcontrol<p.Vmax,'Voltage setpoint must be below ceiling.');
assert(numel(p.Istages)==4 && numel(p.SOCswitch)==3,'Expected four current slots and three switches.');
assert(all(diff(p.SOCswitch)>0),'SOC switches must increase.');
assert(~p.CharacterizationReplay || p.UseExternalCurrent==1,'Characterization requires an explicit external replay.');
if isfield(p,'Replay')
 schedule=p.Replay;
 assert(size(schedule,2)==2 && all(diff(schedule(:,1))>0),'Invalid request schedule.');
 p.ProfileData=[schedule(:,1),repmat(schedule(:,2),1,4)];p=rmfield(p,'Replay');
else
 p.ProfileData=[0 p.Istages;max(24000,p.Duration) p.Istages];
end
if p.ProfileData(end,1)<p.Duration,p.ProfileData(end+1,:)=[p.Duration p.ProfileData(end,2:end)];end
assert(size(p.InputCurrent,2)==2 && all(diff(p.InputCurrent(:,1))>0),'Invalid external-current time series.');
q=p;
end
