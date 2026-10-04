function summary=battery_diagnostics()
% Native MathWorks parsing, cycle features and measured IC/DV diagnostics.
% These characterization cycles do not constitute a longitudinal life test.
p=project_parameters();inventory=table;featureTables=cell(3,1);curveFeatures=table;
for ci=1:3
 cellName=sprintf('LGM50_cell%02d',ci+1);
 raw=readtable(fullfile(p.root,'data','raw',[cellName '.csv']),...
  'NumHeaderLines',13,'VariableNamingRule','preserve');
 mode=string(raw.Md);current=abs(raw.('Current [A]'));
 current(mode=="D")=-current(mode=="D");current(mode=="R")=0;
 data=table(seconds(raw.('Test Time [s]')),current,raw.('Voltage [V]'),...
  raw.('Cycle C'),raw.Step,raw.('Temperature Cell [degC]'),...
  'VariableNames',{'Time','Current','Voltage','Cycle','Step','Temperature'});
 parser=batteryTestDataParser(data,TimeVariable="Time",CurrentVariable="Current",...
  VoltageVariable="Voltage",CycleIndexVariable="Cycle",StepIndexVariable="Step",...
  TemperatureVariable="Temperature",Tolerance=5e-5);
 segmented=segmentData(parser);
 writetable(segmented,fullfile(p.root,'results',[cellName '_native_segments.csv']));
 extractor=batteryTestFeatureExtractor(CyclingPhase="Both",Statistics=true,...
  CycleCumulative=true,CC=true,CV=true,CCCV=true,IC=true,DV=true,DT=true);
 features=extract(extractor,parser);featureTables{ci}=features;
 writetable(features,fullfile(p.root,'results',[cellName '_native_features.csv']));
 groups=unique([data.Cycle data.Step],'rows');
 for gi=1:size(groups,1)
  take=data.Cycle==groups(gi,1) & data.Step==groups(gi,2);d=data(take,:);
  elapsed=seconds(d.Time-d.Time(1));md=mode(find(take,1));
  capacity=0;if height(d)>1,capacity=trapz(elapsed,abs(d.Current))/3600;end
  row=table(string(cellName),groups(gi,1),groups(gi,2),md,height(d),elapsed(end),...
   capacity,median(d.Current),...
   'VariableNames',{'cell','cycle','step','mode','points','duration_s','capacity_Ah','current_charge_A'});
  inventory=[inventory;row]; %#ok<AGROW>
  processed=table(elapsed,d.Current,d.Voltage,d.Temperature,raw.('Temperature Chamber [degC]')(take),...
   'VariableNames',{'time_s','current_charge_A','voltage_V','surface_C','ambient_C'});
  writetable(processed,fullfile(p.root,'data','processed',sprintf('%s_cycle%d_step%d_%s.csv',cellName,groups(gi,1),groups(gi,2),md)));
 end
 % The same 0.3C charge in each cell: matched diagnostic, not aging trend.
 d=readtable(fullfile(p.root,'data','processed',[cellName '_cycle4_step19_C.csv']));
 [~,ia]=unique(d.time_s);d=d(ia,:);
 [ic,dv,dt]=batteryDifferentialCurves(d.voltage_V',d.current_charge_A',d.surface_C',seconds(d.time_s'),...
  NoiseTolerance=.01,PreSmoothingMethod='movmean',PreSmoothingWindowSize=5,...
  PostSmoothingMethod='gaussian',PostSmoothingWindowSize=15,NumInterpolatedPoints=500);
 writetable(ic,fullfile(p.root,'results',[cellName '_IC.csv']));
 writetable(dv,fullfile(p.root,'results',[cellName '_DV.csv']));
 writetable(dt,fullfile(p.root,'results',[cellName '_DT.csv']));
 good=isfinite(ic.IC) & isfinite(ic.interpolatedVoltage);
 [voltage,ix]=unique(ic.interpolatedVoltage(good));curve=ic.IC(good);curve=curve(ix);
 feat=batteryDifferentialCurveFeatures(curve,voltage);feat.cell=string(cellName);
 curveFeatures=[curveFeatures;feat]; %#ok<AGROW>
end
writetable(inventory,fullfile(p.root,'data','experiment_inventory.csv'));
writetable(curveFeatures,fullfile(p.root,'results','measured_IC_features.csv'));
save(fullfile(p.root,'results','native_battery_features.mat'),'featureTables','curveFeatures');
f=figure('Visible','off');hold on;
for ci=1:3
 cellName=sprintf('LGM50_cell%02d',ci+1);d=readtable(fullfile(p.root,'results',[cellName '_IC.csv']));
 plot(d.interpolatedVoltage,d.IC,'DisplayName',cellName);
end
xlabel('Voltage (V)');ylabel('Incremental capacity (Ah/V)');grid on;legend('Location','best');
title('Measured matched-rate charge diagnostics; not a cycle-life validation');
exportgraphics(f,fullfile(p.root,'figures','measured_IC.png'),'Resolution',180);close(f);
summary=struct('engine','Predictive Maintenance Toolbox','cells',3,'step_rows',height(inventory),...
 'diagnostic','Cycle 4 step 19 charge; 500 points, 5-point moving mean and 15-point Gaussian smoothing',...
 'limitation','Cross-cell characterization; no measured longitudinal aging or validated SOH inference.');
write_json(fullfile(p.root,'results','battery_diagnostics.json'),summary);
end
