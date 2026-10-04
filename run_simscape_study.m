function result=run_simscape_study()
p=project_parameters();
names={'CCCV_baseline','two_stage','three_stage','four_stage','adaptive'};
currents={[2.5 2.5 2.5 2.5],[5 2.5 2.5 2.5],[7.5 5 2.5 2.5],[7.5 5 3.5 2.5],[7.5 7.5 7.5 7.5]};
switches={[.4 .6 .7],[.55 .65 .72],[.4 .65 .73],[.35 .5 .68],[.4 .6 .7]};
cases=cell(size(names));
for k=1:numel(names)
 pp=p;pp.Istages=currents{k};pp.SOCswitch=switches{k};cases{k}=pp;
end
[result,traces]=run_cases(cases,names);
writetable(struct2table(result),fullfile(p.root,'results','simscape_comparison.csv'));
save(fullfile(p.root,'results','simscape_study.mat'),'result','traces');
f=figure('Visible','off','Position',[100 100 1250 800]);tiledlayout(2,2);
keys={'current_charge_A','voltage_V','soc','core_C'};labs={'Charge current (A)','Terminal voltage (V)','SOC','Core temperature (C)'};
for j=1:4
 nexttile;hold on;for k=1:numel(names),plot(traces{k}.time_s/60,traces{k}.(keys{j}),'LineWidth',1.4);end
 xlabel('Time (min)');ylabel(labs{j});grid on;if j==1,legend(strrep(names,'_',' '),'Location','best');end
end
exportgraphics(f,fullfile(p.root,'figures','simscape_comparison.png'),'Resolution',180);close(f);
% Explicit high-SOC CC-CV run to exercise the taper region.
p=project_parameters();p.SOCtarget=.98;p.Duration=24000;run_case(p,'high_soc_CCCV');
end
