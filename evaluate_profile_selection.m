function summary=evaluate_profile_selection()
% Verify the selector against previously executed full-plant cases.
p=project_parameters();r=readtable(fullfile(p.root,'results','simscape_robustness.csv'));selected=table;
for temp=[15 25 35]
 for soc=[.1 .2 .4]
  [~,decision]=select_tested_profile(soc,temp);type=1+strcmp(decision.profile,'optimized');
  d=r(r.temperature_C==temp & r.initial_soc==soc & r.profile==type,:);assert(height(d)==1 && d.feasible,'Selected profile lacks a feasible matching test.');selected=[selected;d]; %#ok<AGROW>
 end
end
writetable(selected,fullfile(p.root,'results','recommended_policy_grid.csv'));
summary=struct('tested_conditions',height(selected),'all_selected_feasible',all(selected.feasible),'fast_selected',sum(selected.profile==2),'baseline_fallbacks',sum(selected.profile==1),'evidence','Selection from existing executed full-plant scenarios; not nine additional simulations.','scope','Exact nominal-cell initial SOC / ambient grid. No continuous-domain safety claim.');
fid=fopen(fullfile(p.root,'results','recommended_policy_grid.json'),'w');fprintf(fid,'%s',jsonencode(summary,PrettyPrint=true));fclose(fid);
end
