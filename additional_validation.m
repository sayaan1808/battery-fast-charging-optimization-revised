function result=additional_validation()
% Held-out measured charging profile and fitted-parameter sensitivity.
p=project_parameters();fit=jsondecode(fileread(fullfile(p.root,'results','simscape_parameter_fit.json')));
d=readtable(fullfile(p.root,'data','processed','LGM50_cell04_cycle4_step19_C.csv'));
rest=readtable(fullfile(p.root,'data','processed','LGM50_cell04_cycle4_step18_R.csv'));
d=d(d.time_s<=.9*d.time_s(end),:);d=d(1:2:end,:);
ocv=@(z)interp1(p.Sto,p.Up,p.MaximumStoichiometryCathode-z*(p.MaximumStoichiometryCathode-p.MinimumStoichiometryCathode))-interp1(p.Sto,p.Un,p.MinimumStoichiometryAnode+z*(p.MaximumStoichiometryAnode-p.MinimumStoichiometryAnode));
z0=fminbnd(@(z)(ocv(z)-rest.voltage_V(end))^2,0,.3);
pp=p;pp.ActiveMaterialDiffusionCoefficientAnode=fit.Dn;pp.ActiveMaterialDiffusionCoefficientCathode=fit.Dp;pp.RsurfaceAmbient=fit.RsurfaceAmbient;
pp.SOC0=z0;pp.SOCtarget=2;pp.StopOnTarget=false;pp.CharacterizationReplay=true;pp.UseExternalCurrent=1;pp.InputCurrent=[d.time_s d.current_charge_A];pp.Duration=d.time_s(end);
pp.T0=d.surface_C(1)+273.15;pp.Tamb=median(d.ambient_C)+273.15;
[~,tr]=run_case(pp,'measured_charge_replay');assert(tr.time_s(end)>=pp.Duration-.01,'Incomplete measured-charge window');[tt,ia]=unique(tr.time_s);tr=tr(ia,:);ok=d.time_s<=tt(end)+1e-6;d=d(ok,:);tq=min(d.time_s,tt(end));
v=interp1(tt,tr.voltage_V,tq);temp=interp1(tt,tr.surface_C,tq);
result=struct('cell','cell04','role','held-out 0.3C CC charge, first 90% of CC phase','initial_soc',z0,'initial_soc_method','Inversion of fixed published OCP curves at preceding rest endpoint; no charge samples fitted','coverage_fraction',tq(end)/pp.Duration,'voltage_RMSE_mV',1000*sqrt(mean((v-d.voltage_V).^2)),'temperature_RMSE_C',sqrt(mean((temp-d.surface_C).^2)));
pred=table(d.time_s,d.voltage_V,v,d.surface_C,temp,'VariableNames',{'time_s','measured_voltage_V','predicted_voltage_V','measured_surface_C','predicted_surface_C'});
writetable(pred,fullfile(p.root,'results','heldout_charge_validation.csv'));
fid=fopen(fullfile(p.root,'results','heldout_charge_validation.json'),'w');fprintf(fid,'%s',jsonencode(result,PrettyPrint=true));fclose(fid);
f=figure('Visible','off','Position',[50 50 1100 450]);tiledlayout(1,2);nexttile;plot(d.time_s/60,d.voltage_V,'k.',d.time_s/60,v,'LineWidth',1.3);ylabel('Voltage (V)');xlabel('Time (min)');legend('Measured','Predicted','Location','best');grid on;
nexttile;plot(d.time_s/60,d.surface_C,'k.',d.time_s/60,temp,'LineWidth',1.3);ylabel('Surface temperature (C)');xlabel('Time (min)');grid on;exportgraphics(f,fullfile(p.root,'figures','heldout_charge_validation.png'),'Resolution',180);close(f);
% Apply fitted diffusivities, retaining the intended 6 K/W charging fixture.
s=load(fullfile(p.root,'results','simscape_optimization.mat'),'best');pp=p;pp.Istages=s.best.currents_A;pp.SOCswitch=s.best.switch_soc;
pp.ActiveMaterialDiffusionCoefficientAnode=fit.Dn;pp.ActiveMaterialDiffusionCoefficientCathode=fit.Dp;run_case(pp,'fitted_diffusion_sensitivity');
% Then vary the fixture to its experimental fitted thermal resistance.
pp.RsurfaceAmbient=fit.RsurfaceAmbient;run_case(pp,'fitted_fixture_sensitivity');
end
