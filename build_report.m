function path=build_report()
% Native MATLAB + Simulink Report Generator. No Python generation dependency.
import mlreportgen.report.*
import mlreportgen.dom.*
p=project_parameters();path=fullfile(p.root,'report','Battery_Fast_Charging_Report.pdf');
rpt=slreportgen.report.Report(path,'pdf');
title=TitlePage;title.Title='Battery Fast Charging Optimization';
title.Subtitle='Revised Simscape model, reproducible studies and verification';
title.Author='Venu Madhav';title.PubDate=char(datetime('now','Format','dd MMM yyyy'));
add(rpt,title);add(rpt,TableOfContents);
chapter=Chapter('Title','Executed results and recommendation');
comparison=readtable(fullfile(p.root,'results','simscape_comparison.csv'));
best=jsondecode(fileread(fullfile(p.root,'results','simscape_optimization.json')));
base=comparison.duration_s(strcmp(comparison.name,'CCCV_baseline'));
adaptive=comparison.duration_s(strcmp(comparison.name,'adaptive'));
add(chapter,Paragraph(sprintf('The baseline takes %.2f minutes; the adaptive request takes %.2f minutes; the best tested staged request takes %.2f minutes. The adaptive reduction relative to the baseline is %.1f%%. These are newly executed simulation results under a shared protection policy.',base/60,adaptive/60,best.metrics.duration_s/60,100*(1-adaptive/base))));
add(chapter,Paragraph(sprintf('The staged-to-adaptive time difference is %.2f seconds. Interpret a tie as evidence that the common derating supervisor dominates the request. It is not evidence of an optimizer advantage. Binding shares are elapsed-time weighted and exclude the shutdown tail.',best.metrics.duration_s-adaptive)));
comparison.minutes=comparison.duration_s/60;
addTable(chapter,comparison(:,{'name','minutes','max_voltage_V','max_core_C','feasible'}));
addFigure(chapter,'simscape_comparison.png');add(rpt,chapter);
chapter=Chapter('Title','Model and protection architecture');
load_system(fullfile(p.root,'BatteryFastCharging.slx'));
checks=jsondecode(fileread(fullfile(p.root,'verification','revision_regressions.json')));
add(chapter,Paragraph(sprintf('Executed regression checks: passed = %d. The forced-voltage-fault trace ends at %.5f A after gated shutdown. Enabled SEI starts at %.3g m. Unequal electrolyte layer counts, inactive-aging telemetry, live limit parameters and the shared external clamp were exercised.',checks.passed,checks.fault_terminal_current_A,checks.initial_enabled_SEI_m)));
diagram=slreportgen.report.Diagram('BatteryFastCharging');diagram.Snapshot.Caption='Generated protected Simscape plant; inspect the source model for block dialogs.';
add(chapter,diagram);diagram=slreportgen.report.Diagram('BatteryFastCharging/Supervisor');add(chapter,diagram);
add(rpt,chapter);
chapter=Chapter('Title','Experiments and native battery diagnostics');
v=readtable(fullfile(p.root,'results','simscape_validation_metrics.csv'));
addTable(chapter,v(:,{'cell','role','current_A','voltage_RMSE_after_mV','temperature_RMSE_C','coverage_fraction'}));
holdout=v(strcmp(v.role,'validation'),:);
for h=1:height(holdout)
 add(chapter,Paragraph(sprintf('%s held-out %.2f A discharge: voltage RMSE changes from %.2f to %.2f mV. Temperature RMSE is %.2f C. The fit is not assumed to improve every held-out rate.',string(holdout.cell(h)),holdout.current_A(h),holdout.voltage_RMSE_before_mV(h),holdout.voltage_RMSE_after_mV(h),holdout.temperature_RMSE_C(h))));
end
add(chapter,Paragraph('In particular, deterioration on a higher-rate holdout limits transfer of the fitted parameters to fast charging. Full window coverage is a reproducibility check, not an accuracy acceptance criterion. High-rate charging remains experimentally unvalidated.'));
addFigure(chapter,'simscape_validation.png');addFigure(chapter,'heldout_charge_validation.png');
ic=readtable(fullfile(p.root,'results','measured_IC_features.csv'));
addTable(chapter,ic(:,{'cell','peak','peakLocation','area'}));addFigure(chapter,'measured_IC.png');
add(chapter,Paragraph('Matched low-rate IC curves compare three characterized cells. Peak differences are not a measured aging trajectory and do not validate the simulated lithium-inventory proxy.'));
add(rpt,chapter);
chapter=Chapter('Title','Operating grid, numerical checks and aging');
grid=readtable(fullfile(p.root,'results','simscape_robustness.csv'));
add(chapter,Paragraph(sprintf('%d of %d operating-grid cases meet the configured charging feasibility checks. Failed cases remain visible in the result table and cannot be counted as completed charges.',sum(grid.feasible),height(grid))));
grid.minutes=grid.duration_s/60;addTable(chapter,grid(:,{'temperature_C','initial_soc','profile','minutes','termination_reason','feasible'}));
addFigure(chapter,'robustness.png');addFigure(chapter,'aging_comparison.png');
add(chapter,Paragraph('The six-cycle aging comparison is an uncalibrated model sensitivity. Enabled degradation is reproducible; neither this table nor IC features establish a lifetime improvement.'));
add(rpt,chapter);
chapter=Chapter('Title','Advanced algorithms and reproducibility');
rl=jsondecode(fileread(fullfile(p.root,'results','rl_summary.json')));
add(chapter,Paragraph(sprintf('Reinforcement Learning Toolbox trained %d episodes directly on the full plant using seed %d. Greedy evaluation took %.2f minutes; feasible = %d. Training statistics and the agent are saved in results/learned_policy.mat.',rl.episodes,rl.seed,rl.nominal_evaluation.duration_s/60,rl.nominal_evaluation.feasible)));
addFigure(chapter,'electrochemical_margins.png');
status=jsondecode(fileread(fullfile(p.root,'verification','pipeline_status.json')));
st=struct2table(status);addTable(chapter,st(:,{'step','executed','wall_seconds'}));
add(chapter,Paragraph('Read verification/final_checks.json and revision_regressions.json for assertions. A pipeline stage is executed only after returning successfully. Optional MPC is not implemented. Historical outputs are excluded from this report.'));
add(rpt,chapter);
% Editable methods are shared with the exported Markdown report.
lines=splitlines(string(fileread(fullfile(p.root,'report','methods.md'))));
chapter=Chapter('Title','Methods, scope and references');
for k=1:numel(lines)
 text=char(strtrim(lines(k)));if isempty(text) || startsWith(text,'# '),continue;end
 if startsWith(text,'## '),add(chapter,Heading1(text(4:end)));else,add(chapter,Paragraph(text));end
end
add(rpt,chapter);close(rpt);
fid=fopen(fullfile(p.root,'report','Battery_Fast_Charging_Report.md'),'w');
fprintf(fid,'# Battery Fast Charging Optimization: executed revision\n\n');
fprintf(fid,'Baseline: %.2f min. Adaptive: %.2f min. Best staged: %.2f min. Adaptive reduction: %.1f%%. The staged and adaptive requests tie under common protection; no optimizer advantage is established.\n\n',base/60,adaptive/60,best.metrics.duration_s/60,100*(1-adaptive/base));
fprintf(fid,'%d/%d operating-grid cases were feasible. RL trained %d full-plant episodes (seed %d); greedy evaluation: %.2f min, feasible = %d.\n\n',sum(grid.feasible),height(grid),rl.episodes,rl.seed,rl.nominal_evaluation.duration_s/60,rl.nominal_evaluation.feasible);
for h=1:height(holdout)
 fprintf(fid,'%s held-out %.2f A discharge: voltage RMSE %.2f to %.2f mV; temperature RMSE %.2f C.\n\n',string(holdout.cell(h)),holdout.current_A(h),holdout.voltage_RMSE_before_mV(h),holdout.voltage_RMSE_after_mV(h),holdout.temperature_RMSE_C(h));
end
fprintf(fid,'Higher-rate holdout deterioration limits transfer to fast charging. High-rate charging and cycle-life improvement remain experimentally unvalidated.\n\nDetailed tables: [comparison](../results/simscape_comparison.csv), [validation](../results/simscape_validation_metrics.csv), [operating grid](../results/simscape_robustness.csv).\n\n');
fprintf(fid,'%s',fileread(fullfile(p.root,'report','methods.md')));fclose(fid);
write_json(fullfile(p.root,'verification','report_build.json'),struct('engine','MATLAB/Simulink Report Generator','pdf','report/Battery_Fast_Charging_Report.pdf','created',char(datetime('now'))));
function addTable(ch,t)
 header=strrep(t.Properties.VariableNames,'_',' ');body=table2cell(t);
 for a=1:numel(body)
  if isnumeric(body{a}) || islogical(body{a}),body{a}=sprintf('%.4g',body{a});else,body{a}=char(string(body{a}));end
 end
 ft=FormalTable(header,body);ft.Style={FontSize('8pt'),Border('solid'),RowSep('solid'),ColSep('solid'),Width('100%')};
 ft.Header.Style={Bold(true),BackgroundColor('#E5EDF4')};add(ch,ft);
end
function addFigure(ch,name)
 file=fullfile(p.root,'figures',name);assert(isfile(file),'Missing figure: %s',name);
 info=imfinfo(file);width=6.1;height=width*info.Height/info.Width;
 if height>5.8,width=width*5.8/height;height=5.8;end
 image=Image(file);image.Width=sprintf('%.3fin',width);
 image.Height=sprintf('%.3fin',height);add(ch,image);
end
end
