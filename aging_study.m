function result=aging_study()
% Six continuous cycles with built-in R2026a SEI and plating states.
% Demonstration parameters are not calibrated to LG M50 cycle-life data.
p=project_parameters();p.EnableAging=true;
result=table;
for strategy={'CCCV_baseline','optimized'}
 tr=readtable(fullfile(p.root,'results',['simscape_' strategy{1} '.csv']));
 [tt,ia]=unique(tr.time_s);ii=tr.current_charge_A(ia);
 % Resample applied current onto a 2 s replay grid, preserving the last point.
 t=unique([0:2:tt(end) tt(end)])';i=interp1(tt,ii,t);q=trapz(t,i);
 blockt=[t;t(end)+[.001;60;60.001;60+q/2.5;60+q/2.5+.001;120+q/2.5]];
 blocki=[i;0;0;-2.5;-2.5;0;0];cycleEnd=blockt(end);
 T=[];I=[];
 for cy=1:6
  if cy==1,j=1:numel(blockt);else,j=2:numel(blockt);end
  T=[T;blockt(j)+(cy-1)*cycleEnd];I=[I;blocki(j)]; %#ok<AGROW>
 end
 pp=p;pp.UseExternalCurrent=1;pp.InputCurrent=[T I];pp.SOCtarget=2;pp.StopOnTarget=false;pp.CharacterizationReplay=true;pp.Duration=T(end);
 [~,out]=run_case(pp,['aging_' strategy{1}]);
 assert(abs(out.sei_m(1)-5e-9)<1e-12,'SEI initialization mismatch.');
 assert(out.time_s(end)>=pp.Duration-1,'Aging replay stopped before all cycles finished.');
 Aint=3*p.ActiveMaterialVolumeFractionAnode/p.ParticleRadiusAnode*p.ThicknessAnode*p.ElectrodePlateArea;
 for cy=1:6
  j=find(out.time_s<=cy*cycleEnd,1,'last');
  lostSEI=max(0,out.sei_m(j)-out.sei_m(1))/9.585e-5*Aint*2;
  lostMol=lostSEI+out.irreversible_plating_mol(j);
  estimatedSOH=1-lostMol*96485.33212/(3600*p.Q_Ah);
  rr=table(string(strategy{1}),cy,out.time_s(j),out.sei_m(j),out.irreversible_plating_mol(j),estimatedSOH,'VariableNames',{'strategy','cycle','time_s','sei_m','irreversible_plating_mol','lithium_inventory_SOH_proxy'});
  result=[result;rr]; %#ok<AGROW>
 end
end
writetable(result,fullfile(p.root,'results','aging_summary.csv'));
f=figure('Visible','off');hold on;
for name=unique(result.strategy)',d=result(result.strategy==name,:);plot(d.cycle,100*d.lithium_inventory_SOH_proxy,'-o','DisplayName',name);end
xlabel('Cycle');ylabel('Lithium-inventory SOH proxy (%)');legend('Location','best');grid on;title('Uncalibrated degradation sensitivity - not a lifetime prediction');exportgraphics(f,fullfile(p.root,'figures','aging_comparison.png'),'Resolution',180);close(f);

end
