function result=direct_collocation(p)
% Trapezoidal direct collocation on the explicit five-state reduced surrogate.
% A successful optimizer exit is followed by independent RK4 replay and then
% the scheduled current must be replayed in Simscape before acceptance.
N=25;[base,~]=sim_reduced(p,@(~,~)3.0);tf0=base(end,1);
grid=linspace(0,tf0,N)';X0=interp1(base(:,1),base(:,2:6),grid);U0=interp1(base(:,1),base(:,7),grid);
w0=[tf0/3600;X0(:);U0];
% Explicit bound construction keeps MATLAB indexing portable.
XL=repmat([p.SOC0 -.2 -.3 0 0],N,1);XU=repmat([p.SOCtarget+.001 .3 .2 45 45],N,1);
lb=[.15;XL(:);zeros(N,1)];ub=[4;XU(:);p.Imax*ones(N,1)];
options=optimoptions('fmincon','Algorithm','sqp','Display','iter','MaxIterations',220,'MaxFunctionEvaluations',65000,'ConstraintTolerance',1e-5,'OptimalityTolerance',1e-3,'StepTolerance',1e-7);
[w,fval,exitflag,output]=fmincon(@(w)w(1),w0,[],[],[],[],lb,ub,@constraints,options);
[X,U,tf]=unpack(w);[c,ceq]=constraints(w);tt=linspace(0,tf,N)';
T=array2table([tt X U],'VariableNames',{'time_s','soc','anode_lag','cathode_lag','core_C','surface_C','current_A'});
writetable(T,fullfile(p.root,'results','direct_collocation_nodes.csv'));
[replay,rm]=sim_reduced(p,@(~,t)interp1(tt,U,min(t,tf),'linear'));
writematrix(replay,fullfile(p.root,'results','direct_collocation_replay.csv'));
result=struct('method','trapezoidal direct collocation on five-state surrogate','time_s',tf,'exitflag',exitflag,'iterations',output.iterations,'max_constraint',max(c),'max_defect',max(abs(ceq)),'replay',rm,'accepted_surrogate',exitflag>0 && max(c)<1e-4 && max(abs(ceq))<1e-4);
fid=fopen(fullfile(p.root,'results','direct_collocation.json'),'w');fprintf(fid,'%s',jsonencode(result,PrettyPrint=true));fclose(fid);
function [X,U,tf]=unpack(w),tf=3600*w(1);X=reshape(w(2:1+5*N),N,5);U=w(2+5*N:end);end
function [c,ceq]=constraints(w)
 [X,U,tf]=unpack(w);h=tf/(N-1);[D,V,E,SN,SP]=reduced_rhs(X,U,p);
 defect=X(2:end,:)-X(1:end-1,:)-h/2*(D(2:end,:)+D(1:end-1,:));
 defect(:,4:5)=defect(:,4:5)/20;
 initial=X(1,:)-[p.SOC0 0 0 p.T0-273.15 p.T0-273.15];initial(4:5)=initial(4:5)/20;
 ceq=[initial(:);defect(:);X(end,1)-p.SOCtarget];
 c=[V-p.Vcontrol;p.AnodePotentialMin-E;SN-.98;.02-SP];
end
end
