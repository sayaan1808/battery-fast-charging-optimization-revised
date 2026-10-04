function [dx,v,eta,thetaN,thetaP]=reduced_rhs(x,u,p)
% Five-state optimization surrogate: SOC, two diffusion lags, core and case T.
% This is an explicit reduced approximation, not the Simscape SPM block.
F=96485.33212;R=8.314462618;A=p.ElectrodePlateArea;
z=x(:,1);dn=x(:,2);dp=x(:,3);Tc=x(:,4)+273.15;Ts=x(:,5);
xn=p.MinimumStoichiometryAnode+z*(p.MaximumStoichiometryAnode-p.MinimumStoichiometryAnode);
xp=p.MaximumStoichiometryCathode-z*(p.MaximumStoichiometryCathode-p.MinimumStoichiometryCathode);
thetaN=xn+dn;thetaP=xp+dp;
sn=min(.999,max(.001,thetaN));sp=min(.999,max(.001,thetaP));
Un=@(s)1.9793*exp(-39.3631*s)+.2482-.0909*tanh(29.8538*(s-.1234))-.04478*tanh(14.9159*(s-.2769))-.0205*tanh(30.4444*(s-.6103));
Up=@(s)-.8090*s+4.4875-.0428*tanh(18.5138*(s-.5542))-17.7326*tanh(15.7890*(s-.3117))+17.5842*tanh(15.9308*(s-.3120));
an=3*p.ActiveMaterialVolumeFractionAnode/p.ParticleRadiusAnode;
ap=3*p.ActiveMaterialVolumeFractionCathode/p.ParticleRadiusCathode;
i0n=6.48e-7*exp(35000/R*(1/298.15-1./Tc)).*sqrt(1000*p.MaximumConcentrationAnode^2.*sn.*(1-sn));
i0p=3.42e-6*exp(17800/R*(1/298.15-1./Tc)).*sqrt(1000*p.MaximumConcentrationCathode^2.*sp.*(1-sp));
en=-2*R*Tc/F.*asinh(u./(2*A*p.ThicknessAnode*an.*i0n));
ep= 2*R*Tc/F.*asinh(u./(2*A*p.ThicknessCathode*ap.*i0p));
Re=(p.ThicknessAnode/(3*p.ElectrolyteVolumeFractionAnode^1.5)+p.ThicknessSeparator/p.ElectrolyteVolumeFractionSeparator^1.5+p.ThicknessCathode/(3*p.ElectrolyteVolumeFractionCathode^1.5))/(A*p.ElectrolyteConductivity)+p.CurrentCollectorResistance;
v=Up(sp)-Un(sn)+ep-en+u*Re;eta=Un(sn)+en;
Dn=p.ActiveMaterialDiffusionCoefficientAnode*exp(p.ActiveMaterialDiffusionActivationEnergyAnode/R*(1/298.15-1./Tc));
Dp=p.ActiveMaterialDiffusionCoefficientCathode*exp(p.ActiveMaterialDiffusionActivationEnergyCathode/R*(1/298.15-1./Tc));
taun=p.ParticleRadiusAnode^2./(15*Dn);taup=p.ParticleRadiusCathode^2./(15*Dp);
dcn=u/(F*A*p.ThicknessAnode*p.ActiveMaterialVolumeFractionAnode*p.MaximumConcentrationAnode);
dcp=-u/(F*A*p.ThicknessCathode*p.ActiveMaterialVolumeFractionCathode*p.MaximumConcentrationCathode);
Q=u.*(v-(Up(xp)-Un(xn)));Q=max(Q,0);
qcs=(x(:,4)-Ts)/p.RcoreSurface;qsa=(Ts-(p.Tamb-273.15))/p.RsurfaceAmbient;
dx=[u/(3600*p.Q_Ah),dcn-dn./taun,dcp-dp./taup,(Q-qcs)/p.BatteryThermalMass,(qcs-qsa)/p.Csurface];
end
