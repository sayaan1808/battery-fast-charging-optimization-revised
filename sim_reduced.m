function [trace,m]=sim_reduced(p,policy)
% Fixed-step RK4 reference simulator with an explicit action safety filter.
dt=2;x=[p.SOC0 0 0 p.T0-273.15 p.T0-273.15];trace=zeros(ceil(p.Duration/dt)+1,10);
for k=1:size(trace,1)
 t=(k-1)*dt;request=policy(x,t);lo=0;hi=min(p.Imax,max(0,request));
 for j=1:20
  u=(lo+hi)/2;[~,v,e,sn,sp]=reduced_rhs(x,u,p);
  if v<=p.Vcontrol && e>=p.AnodePotentialMin && sn<.98 && sp>.02 && x(4)<p.Tmax-273.15-1,lo=u;else,hi=u;end
 end
 u=lo;[a,v,e,sn,sp]=reduced_rhs(x,u,p);trace(k,:)=[t x u v e sn];
 if x(1)>=p.SOCtarget || t>=p.Duration,break;end
 b=reduced_rhs(x+dt*a/2,u,p);c=reduced_rhs(x+dt*b/2,u,p);d=reduced_rhs(x+dt*c,u,p);
 x=x+dt*(a+2*b+2*c+d)/6;
end
trace=trace(1:k,:);
m=struct('duration_s',trace(end,1),'final_soc',trace(end,2),'max_voltage_V',max(trace(:,8)),'max_core_C',max(trace(:,5)),'min_anode_potential_V',min(trace(:,9)),'target_reached',trace(end,2)>=p.SOCtarget);
end
