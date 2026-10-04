function path=record_demo()
% Video of recorded simulation traces, not live experiments or screen capture.
p=project_parameters();path=fullfile(p.root,'report','charging_demo.mp4');
names={'CCCV_baseline','adaptive','optimized'};d=cell(3,1);
for k=1:3,d{k}=readtable(fullfile(p.root,'results',['simscape_' names{k} '.csv']));end
v=VideoWriter(path,'MPEG-4');v.FrameRate=10;v.Quality=90;open(v);
f=figure('Visible','off','Position',[50 50 1200 700],'Color','w');
cleanup=onCleanup(@()close(f));
for frame=1:300
 clf(f);tiledlayout(2,2,'Padding','compact');cut=frame/300*max(d{1}.time_s);
 fields={'current_charge_A','voltage_V','soc','electrolyte_min_mol_m3'};
 labels={'Charge current (A)','Terminal voltage (V)','SOC','Minimum electrolyte (mol/m^3)'};
 for j=1:4
  nexttile;hold on;
  for k=1:3
   take=d{k}.time_s<=cut;plot(d{k}.time_s(take)/60,d{k}.(fields{j})(take),'LineWidth',1.8);
  end
  xlim([0 75]);xlabel('Simulation time (minutes)');ylabel(labels{j});grid on;
  if j==1,ylim([0 8]);legend('0.5C CC-CV','Adaptive request','Best staged request','Location','northeast');end
  if j==2,ylim([3.4 4.25]);yline(p.Vmax,'k--');end
  if j==3,ylim([.15 .85]);yline(p.SOCtarget,'k--');end
  if j==4,ylim([0 1100]);yline(p.ElectrolyteMin,'k--');end
 end
 sgtitle(sprintf('Recorded Simscape playback | %.1f min | Adaptive/staged tie: shared limits dominate',cut/60));
 drawnow;pixels=print(f,'-RGBImage','-r100');writeVideo(v,pixels);
end
close(v);
end
