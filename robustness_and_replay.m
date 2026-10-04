function rows=robustness_and_replay()
p=project_parameters();s=load(fullfile(p.root,'results','simscape_optimization.mat'),'best');b=s.best;cases={};names={};tags=[];
for temp=[15 25 35]
 for soc=[.1 .2 .4]
  for type=1:2
   pp=p;pp.T0=temp+273.15;pp.Tamb=pp.T0;pp.SOC0=soc;
   if type==2,pp.Istages=b.currents_A;pp.SOCswitch=b.switch_soc;end
   cases{end+1}=pp;names{end+1}=sprintf('grid_T%d_Z%d_P%d',temp,round(100*soc),type);tags(end+1,:)=[temp soc type]; %#ok<AGROW>
  end
 end
end
[rows,~]=run_cases(cases,names);
for k=1:numel(rows),rows(k).temperature_C=tags(k,1);rows(k).initial_soc=tags(k,2);rows(k).profile=tags(k,3);end
writetable(struct2table(rows),fullfile(p.root,'results','simscape_robustness.csv'));
% Direct-collocation and learned requests must survive the full plant replay.
pc=p;c=readtable(fullfile(p.root,'results','direct_collocation_nodes.csv'));pc.Replay=[c.time_s c.current_A];run_case(pc,'collocation_replay');
% RL evaluation is produced directly by learn_charging_policy on the full plant.
% Numerical convergence: refine both spatial resolution and maximum time step.
pc=p;pc.Istages=b.currents_A;pc.SOCswitch=b.switch_soc;
pf=pc;pf.Shells=20;pf.LayersAnode=20;pf.LayersSeparator=20;pf.LayersCathode=20;
pf.MaxStep=.25;pf.RelTol=1e-6;pf.AbsTol=1e-8;
[mesh,~]=run_cases({pc,pf},{'coarse','refined'});coarse=mesh(1);fine=mesh(2);
check=struct('coarse',coarse,'fine',fine,'time_difference_percent',100*(fine.duration_s-coarse.duration_s)/coarse.duration_s,'voltage_difference_mV',1000*(fine.max_voltage_V-coarse.max_voltage_V),'temperature_difference_C',fine.max_core_C-coarse.max_core_C);
fid=fopen(fullfile(p.root,'results','simscape_convergence.json'),'w');fprintf(fid,'%s',jsonencode(check,PrettyPrint=true));fclose(fid);

% Temperature feedback sensitivity: finite diffusion activation energies are
% hypothetical sensitivity assumptions, not fitted Chen2020 measurements.
pt=p;pt.Istages=b.currents_A;pt.SOCswitch=b.switch_soc;pt.ActiveMaterialDiffusionActivationEnergyAnode=20000;pt.ActiveMaterialDiffusionActivationEnergyCathode=20000;run_case(pt,'diffusion_thermal_sensitivity');
end
