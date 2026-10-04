function checks=finalize_project()
% Produce interpretation figures, save a clean nominal model, and verify.
p=project_parameters();mdl='BatteryFastCharging';
evaluate_profile_selection();
names={'CCCV_baseline','optimized','collocation_replay','rl_replay'};
f=figure('Visible','off','Position',[100 100 1150 720]);tiledlayout(2,2);
for k=1:numel(names)
 d=readtable(fullfile(p.root,'results',['simscape_' names{k} '.csv']));
 nexttile(1);hold on;plot(d.time_s/60,1000*d.anode_potential_V,'LineWidth',1.2);
 nexttile(2);hold on;plot(d.time_s/60,d.electrolyte_min_mol_m3,'LineWidth',1.2);
 nexttile(3);hold on;plot(d.time_s/60,d.anode_surface_mol_m3/p.MaximumConcentrationAnode,'LineWidth',1.2);
 nexttile(4);hold on;plot(d.time_s/60,d.core_C-d.surface_C,'LineWidth',1.2);
end
nexttile(1);yline(20,'k--');ylabel('Anode potential proxy (mV)');legend(strrep(names,'_',' '),'Location','best');
nexttile(2);yline(100,'k--');ylabel('Minimum electrolyte (mol/m^3)');
nexttile(3);yline(.98,'k--');ylabel('Anode surface stoichiometry');
nexttile(4);ylabel('Core - surface temperature (C)');
for j=1:4,nexttile(j);xlabel('Time (min)');grid on;end
exportgraphics(f,fullfile(p.root,'figures','electrochemical_margins.png'),'Resolution',180);close(f);
d=readtable(fullfile(p.root,'results','simscape_high_soc_CCCV.csv'));
f=figure('Visible','off','Position',[100 100 1100 430]);tiledlayout(1,2);nexttile;plot(d.time_s/60,d.current_charge_A,'LineWidth',1.4);xlabel('Time (min)');ylabel('Charge current (A)');grid on;
nexttile;plot(d.time_s/60,d.voltage_V,'LineWidth',1.4);yline(p.Vcontrol,'k--');xlabel('Time (min)');ylabel('Voltage (V)');grid on;exportgraphics(f,fullfile(p.root,'figures','cccv_taper.png'),'Resolution',180);close(f);
d=readtable(fullfile(p.root,'results','simscape_robustness.csv'));
f=figure('Visible','off','Position',[100 100 1100 430]);tiledlayout(1,2);
for k=1:2
 nexttile;hold on;
 for temp=[15 25 35]
  r=d(d.temperature_C==temp & d.profile==k,:);dur=r.duration_s/60;dur(~r.feasible)=NaN;plot(100*r.initial_soc,dur,'-o','DisplayName',sprintf('%d C',temp),'LineWidth',1.4);
 end
 xlabel('Initial SOC (%)');ylabel('Time to 80% (min)');legend('Location','best');grid on;
 if k==1,title('0.5C CC-CV');else,title('Optimized staged request');end
 if k==2,subtitle('Only completed runs shown');end
end
exportgraphics(f,fullfile(p.root,'figures','robustness.png'),'Resolution',180);close(f);
assignin(get_param(mdl,'ModelWorkspace'),'p',prepare_case(p));
set_param(mdl,'MaxStep','1','RelTol','1e-5','AbsTol','1e-7','StopTime','p.Duration');
Simulink.BlockDiagram.arrangeSystem(mdl);
save_system(mdl,fullfile(p.root,[mdl '.slx']));
try,print(['-s' mdl],'-dpng','-r180',fullfile(p.root,'figures','simscape_model.png'));catch e,warning('Model print: %s',e.message);end
checks=verify_project();
end
