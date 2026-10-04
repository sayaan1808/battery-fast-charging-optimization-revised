function [m,tbl]=summarize_case(p,name,out,mdl)
if nargin<4,mdl='BatteryFastCharging';end
names=evalin(get_param(mdl,'ModelWorkspace'),'logNames');
values=out.trace;
if ndims(values)==3,values=reshape(values,numel(names),[])';end
tbl=array2table(values,'VariableNames',names);
tbl.core_C=tbl.core_K-273.15;tbl.surface_C=tbl.surface_K-273.15;
assert(abs(tbl.core_K(1)-p.T0)<.05,'Core initialization mismatch.');
assert(abs(tbl.surface_K(1)-p.T0)<.05,'Surface initialization mismatch.');
assert(abs(tbl.electrolyte_min_mol_m3(1)-1000)<.05,'Electrolyte initialization mismatch.');
if p.EnableAging
 assert(abs(tbl.sei_m(1)-p.InitialSEI)<1e-12,'SEI initialization mismatch.');
else
 assert(all(isnan(tbl.sei_m)),'Inactive aging must be missing.');
end
reached=any(tbl.complete>0);fault=any(tbl.fault>0);
code=tbl.termination_reason(end);
if code==0
 if ~p.StopOnTarget && tbl.time_s(end)>=p.Duration-.01,code=9;else,code=8;end
 tbl.termination_reason(end)=code;
end
endIndex=find(tbl.complete>0,1);if isempty(endIndex),endIndex=height(tbl);end
chargeTime=tbl.time_s(endIndex);
m=struct('name',name,'duration_s',chargeTime,'stop_time_s',tbl.time_s(end),...
 'final_soc',tbl.soc(end),'max_voltage_V',max(tbl.voltage_V),'max_core_C',max(tbl.core_C),...
 'max_surface_C',max(tbl.surface_C),'min_anode_potential_V',min(tbl.anode_potential_V),...
 'min_electrolyte_mol_m3',min(tbl.electrolyte_min_mol_m3),'max_current_A',max(tbl.current_charge_A),...
 'delivered_Ah',trapz(tbl.time_s,tbl.current_charge_A)/3600,...
 'energy_Wh',trapz(tbl.time_s,tbl.current_charge_A.*tbl.voltage_V)/3600,...
 'target_reached',reached,'fault',fault,'termination_reason',code,...
 'terminal_current_A',tbl.current_charge_A(end),'aging_enabled',p.EnableAging,...
 'characterization_replay',p.CharacterizationReplay);
m.feasible=reached && ~fault && ~p.CharacterizationReplay && m.max_voltage_V<=p.Vmax+.002 && m.max_core_C<=p.Tmax-273.15+.05 && m.min_anode_potential_V>=p.AnodePotentialMin-.003 && m.min_electrolyte_mol_m3>=p.ElectrolyteMin && m.max_current_A<=p.Imax+.001 && abs(m.terminal_current_A)<=p.ShutdownCurrentTolerance+.001;
dt=diff(tbl.time_s(1:endIndex));b=tbl.binding_limiter(1:endIndex-1);
for k=1:5,m.(['binding_fraction_' num2str(k)])=sum(dt(b==k))/max(eps,chargeTime);end
if ~isempty(name)
 writetable(tbl,fullfile(p.root,'results',['simscape_' name '.csv']));
 write_json(fullfile(p.root,'results',['simscape_' name '_metrics.json']),m);
end
fprintf('%s: %.2f min, SOC %.4f, reason %d, terminal %.4f A, feasible=%d\n',name,m.duration_s/60,m.final_soc,code,m.terminal_current_A,m.feasible);
end
