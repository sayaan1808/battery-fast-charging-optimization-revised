function report=validate_experiments()
% Real experimental validation. Cell 02 fit; cells 03 and 04 held out.
p=project_parameters();
cases={'cell02',3,12,'fit';'cell02',4,17,'fit';'cell03',4,17,'validation';'cell04',5,22,'validation'};
data=cell(4,1);
for k=1:4
 file=sprintf('LGM50_%s_cycle%d_step%d_D.csv',cases{k,1},cases{k,2},cases{k,3});
 d=readtable(fullfile(p.root,'data','processed',file));d=d(d.time_s<=.90*d.time_s(end),:);data{k}=d(1:2:end,:);
end
history=[];base=residual([0 0 6],true);
design=param.Continuous('fitVector',[0;0;6]);design.Minimum=[-.6;-.6;2];design.Maximum=[.6;.6;25];design.Scale=[1;1;6];
opts=sdo.OptimizeOptions;opts.Method='lsqnonlin';
opts.MethodOptions.MaxFunEvals=80;opts.MethodOptions.MaxIter=10;
opts.MethodOptions.TolFun=1e-3;opts.MethodOptions.TolX=1e-3;
[solution,fitInfo]=sdo.optimize(@objective,design,opts);
x=solution.Value(:)';resnorm=sum(fitInfo.F(:).^2);exitflag=fitInfo.exitflag;
output=struct('message','See sdo_fit_info.mat for native optimizer diagnostics.');
save(fullfile(p.root,'results','sdo_fit_info.mat'),'fitInfo','solution','opts');
final=residual(x,true);report=struct([]);
f=figure('Visible','off','Position',[100 100 1150 780]);tiledlayout(2,2);
for k=1:4
 r=final{k};d=data{k};t=r.time_s;
 vb=interp1(base{k}.time_s,base{k}.predicted_voltage_V,t,'linear','extrap');
 mm=struct('cell',cases{k,1},'role',cases{k,4},'current_A',abs(median(d.current_charge_A)),'points',height(r),'requested_comparison_duration_s',d.time_s(end),'actual_comparison_duration_s',t(end),'coverage_fraction',t(end)/d.time_s(end),'voltage_RMSE_before_mV',1000*sqrt(mean((vb-r.measured_voltage_V).^2)),'voltage_RMSE_after_mV',1000*sqrt(mean((r.predicted_voltage_V-r.measured_voltage_V).^2)),'temperature_RMSE_C',sqrt(mean((r.predicted_surface_C-r.measured_surface_C).^2)));
 report=[report;mm]; %#ok<AGROW>
 writetable(r,fullfile(p.root,'results',sprintf('simscape_validation_%s_%.1fA.csv',cases{k,1},mm.current_A)));
 nexttile;plot(t/60,r.measured_voltage_V,'k.',t/60,r.predicted_voltage_V,'LineWidth',1.3);xlabel('Time (min)');ylabel('Voltage (V)');title([cases{k,1} ' - ' cases{k,4}]);legend('Measured','Simscape','Location','best');grid on;
end
exportgraphics(f,fullfile(p.root,'figures','simscape_validation.png'),'Resolution',180);close(f);
writetable(struct2table(report),fullfile(p.root,'results','simscape_validation_metrics.csv'));
fit=struct('method','SDO SimulationTest + SignalTracking + optimize; grouped cell02 experiments','Dn',p.ActiveMaterialDiffusionCoefficientAnode*10^x(1),'Dp',p.ActiveMaterialDiffusionCoefficientCathode*10^x(2),'RsurfaceAmbient',x(3),'exitflag',exitflag,'message',output.message,'resnorm',resnorm,'fit_data','Cell02: 0.5C and 1C discharge, first 90% of duration, every second sample','holdout','Cell03 1C and Cell04 1.5C. No holdout data in optimization.','identifiability','Radii/OCP fixed; effective diffusivities fitted. Thermal case capacity and core-surface resistance fixed. EIS was not present in the source dataset.','history',history);
fid=fopen(fullfile(p.root,'results','simscape_parameter_fit.json'),'w');fprintf(fid,'%s',jsonencode(fit,PrettyPrint=true));fclose(fid);
inv=readtable(fullfile(p.root,'data','experiment_inventory.csv'));caps=inv(strcmp(inv.mode,'D') & inv.cycle==2,{'cell','capacity_Ah','duration_s'});writetable(caps,fullfile(p.root,'results','measured_capacity.csv'));
function result=residual(x,details)
 result=[];if details,result=cell(4,1);end
 for j=1:4
  if ~details && j>2,continue;end
  d=data{j};pp=p;pp.SOC0=1;pp.SOCtarget=2;pp.Duration=d.time_s(end);pp.UseExternalCurrent=1;pp.InputCurrent=[d.time_s d.current_charge_A];
  pp.T0=d.surface_C(1)+273.15;pp.Tamb=median(d.ambient_C)+273.15;
  % Characterize measured discharge beyond the proposed charging envelope.
  % These settings apply only to experimental replay, not charging policies.
  pp.StopOnTarget=0;pp.CharacterizationReplay=1;
  pp.ActiveMaterialDiffusionCoefficientAnode=p.ActiveMaterialDiffusionCoefficientAnode*10^x(1);pp.ActiveMaterialDiffusionCoefficientCathode=p.ActiveMaterialDiffusionCoefficientCathode*10^x(2);pp.RsurfaceAmbient=x(3);
  try
   tr=sdo_trace(pp);[ut,ia]=unique(tr.time_s);tr=tr(ia,:);ok=d.time_s<=ut(end)+1e-6;dd=d(ok,:);
   tq=min(dd.time_s,ut(end));v=interp1(ut,tr.voltage_V,tq);ts=interp1(ut,tr.surface_C,tq);
   assert(all(ok),'Insufficient coverage of experimental window');
   if details,result{j}=table(dd.time_s,dd.voltage_V,v,dd.surface_C,ts,'VariableNames',{'time_s','measured_voltage_V','predicted_voltage_V','measured_surface_C','predicted_surface_C'});
   else
    vr=sdo.requirements.SignalTracking('Method','Residuals','Normalize','off','ReferenceSignal',timeseries(dd.voltage_V,tq));
    trq=sdo.requirements.SignalTracking('Method','Residuals','Normalize','off','ReferenceSignal',timeseries(dd.surface_C,tq));
    result=[result;evalRequirement(vr,timeseries(v,tq))/.03/sqrt(height(dd));evalRequirement(trq,timeseries(ts,tq))/sqrt(height(dd))];end %#ok<AGROW>
  catch err
   if details,rethrow(err);end
   result=[result;100*ones(2*height(d),1)]; %#ok<AGROW>
  end
 end
 if ~details,history=[history;[x sum(result.^2)]];end %#ok<AGROW>
end
function cost=objective(design)
 cost=struct('F',residual(design.Value(:)',false));
end
function tr=sdo_trace(pp)
 mdl='BatteryFastCharging';q=prepare_case(pp);
 fields={'SOC0','SOCtarget','Duration','UseExternalCurrent','InputCurrent','T0','Tamb','StopOnTarget','CharacterizationReplay','ActiveMaterialDiffusionCoefficientAnode','ActiveMaterialDiffusionCoefficientCathode','RsurfaceAmbient'};
 params=sdo.getParameterFromModel(mdl,strcat('p.',fields));
 for n=1:numel(fields)
  % Each recorded current waveform has a different length from the nominal
  % placeholder. Reconstruct its parameter with the new dimensions.
  params(n)=param.Continuous(getID(params(n)),double(q.(fields{n})));
 end
 test=sdo.SimulationTest(mdl);test.Parameters=params;
 test=sim(test,'StopTime',num2str(pp.Duration));
 [~,tr]=summarize_case(pp,'',test.LoggedData,mdl);
end

end
