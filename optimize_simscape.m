function best=optimize_simscape()
% Constrained derivative-free optimization against the actual Simscape model.
p=project_parameters();history=struct([]);bestScore=inf;bestX=[];bestM=[];
x0=[1 2/3 1/3 .4 .65];
A=[-1 1 0 0 0;0 -1 1 0 0;0 0 0 1 -1];b=[0;0;-.05];
lb=[.15 .15 .15 .25 .45];ub=[1 1 1 .60 .77];
opts=optimoptions('patternsearch','Display','iter','MaxFunctionEvaluations',40,'MaxIterations',18,'MeshTolerance',.025,'InitialMeshSize',.1,'UseCompletePoll',true);
[xx,score,flag,output]=patternsearch(@objective,x0,A,b,[],[],lb,ub,[],opts); %#ok<ASGLU>
assert(~isempty(bestX),'No feasible Simscape profile was found.');
p.Istages=7.5*[bestX(1:3) bestX(3)];p.SOCswitch=[bestX(4:5) .79];
[m,~]=run_case(p,'optimized');
best=struct('method','patternsearch on Simscape simulations','best_normalized_x',bestX,'currents_A',p.Istages,'switch_soc',p.SOCswitch,'metrics',m,'exitflag',flag,'message',output.message,'evaluations',numel(history),'claim','Best feasible evaluated candidate; no global optimality claim.');
save(fullfile(p.root,'results','simscape_optimization.mat'),'best','history');
fid=fopen(fullfile(p.root,'results','simscape_optimization.json'),'w');fprintf(fid,'%s',jsonencode(best,PrettyPrint=true));fclose(fid);
fid=fopen(fullfile(p.root,'results','simscape_optimization_history.json'),'w');fprintf(fid,'%s',jsonencode(history,PrettyPrint=true));fclose(fid);
function cost=objective(x)
 pp=p;pp.Istages=7.5*[x(1:3) x(3)];pp.SOCswitch=[x(4:5) .79];
 try
  [mm,~]=run_case(pp,'');cost=mm.duration_s;
  if ~mm.feasible,cost=1e5+1e4*max(0,pp.SOCtarget-mm.final_soc);end
  if mm.feasible && cost<bestScore,bestScore=cost;bestX=x;bestM=mm;end %#ok<NASGU>
  rec=struct('x',x,'objective',cost,'feasible',mm.feasible,'error','');
 catch err
  cost=1e6;rec=struct('x',x,'objective',cost,'feasible',false,'error',err.message);
 end
 history=[history;rec]; %#ok<AGROW>
end
end
