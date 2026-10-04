function [limit,complete,fault,stop,reason,allowExternal,limitsActive]=supervisor_step(z,T,V,psi,ce,Iapplied,stages,sw,t,external,useExternal,p)
%#codegen
% Named states and parameters; reasons are latched through shutdown settling.
% 0 running; 1 completed; 2 V high; 3 T high; 4 anode; 5 electrolyte;
% 6 V low/SOC low; 7 nonfinite measurement. Postprocessor adds 8 timeout.
persistent eventCode eventTime
if isempty(eventCode),eventCode=0;eventTime=0;end
if z<sw(1),requested=stages(1);
elseif z<sw(2),requested=stages(2);
elseif z<sw(3),requested=stages(3);
else,requested=stages(4);end
if useExternal>0.5,requested=external;end
thermal=p.ThermalGain*max(0,p.Tmax-p.ThermalSoftMargin-T);
anode=p.AnodeGain*max(0,psi-p.AnodePotentialMin);
electrolyte=p.ElectrolyteGain*max(0,ce-p.ElectrolyteMin-p.ElectrolyteSoftMargin);
limit=max(0,min([requested,p.Imax,thermal,anode,electrolyte]));
binding=0;
if requested>0,[~,binding]=min([requested,p.Imax,thermal,anode,electrolyte]);end
diagnostic=p.CharacterizationReplay && useExternal>0.5;
allowExternal=useExternal>0.5 && (diagnostic || requested<0);
vmax=p.Vmax+p.VoltageFaultMargin;tmax=p.Tmax+p.TemperatureFaultMargin;
vmin=p.VoltageMin;cefloor=p.ElectrolyteMin;psifloor=p.AnodeFaultMin;
if diagnostic
 vmax=p.DiagnosticVmax;vmin=p.DiagnosticVmin;tmax=p.DiagnosticTmax;
 cefloor=p.DiagnosticCeMin;psifloor=p.DiagnosticAnodeMin;
 limit=max(0,min(requested,p.Imax));binding=0;
end
newCode=0;
if ~all(isfinite([z,T,V,psi,ce,Iapplied])),newCode=7;
elseif V>vmax,newCode=2;
elseif T>tmax,newCode=3;
elseif psi<psifloor,newCode=4;
elseif ce<cefloor,newCode=5;
elseif V<vmin || z<p.SOCmin-1e-3,newCode=6;
elseif p.StopOnTarget && z>=p.SOCtarget,newCode=1;
end
if eventCode==0 && newCode>0,eventCode=newCode;eventTime=t;
elseif eventCode==1 && newCode>1,eventCode=newCode;end
reason=eventCode;complete=eventCode==1;fault=eventCode>1;
if eventCode>0,limit=0;end
settled=abs(Iapplied)<=p.ShutdownCurrentTolerance && t-eventTime>=p.ShutdownMinTime;
stop=eventCode>0 && (settled || t-eventTime>=p.ShutdownMaxTime);
limitsActive=[thermal;anode;electrolyte;requested;binding];
end
