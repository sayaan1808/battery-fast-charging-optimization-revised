function p = project_parameters()
% Chen et al. 2020 LG M50; thermal boundary and study limits are assumptions.
% Source: doi:10.1149/1945-7111/ab9050; PyBaMM Chen2020 parameter set.
p.root=fileparts(fileparts(mfilename('fullpath')));
p.Q_Ah=5; p.SOC0=.2; p.SOCtarget=.8; p.T0=298.15; p.Tamb=298.15;
p.Vcontrol=4.195; p.Vmax=4.2; p.Tmax=318.15; p.Imax=7.5;
p.AnodePotentialMin=.020; p.ElectrolyteMin=100; p.Ts=.5;
p.Istages=[2.5 2.5 2.5 2.5]; p.SOCswitch=[.4 .6 .7];
p.Duration=12000; p.Shells=12;
p.LayersAnode=12;p.LayersSeparator=12;p.LayersCathode=12;
p.UseExternalCurrent=0;p.InputCurrent=[0 0;24000 0];
% Istages is the sole staged-current input. ProfileData is derived per run.
p.EnableAging=false;p.InitialSEI=5e-9;
p.CharacterizationReplay=0;p.StopOnTarget=1;
p.ImaxDischarge=7.5;p.ActuatorTau=2;
p.ThermalGain=2;p.ThermalSoftMargin=1;
p.AnodeGain=100;p.AnodeFaultMin=-.005;
p.ElectrolyteGain=.02;p.ElectrolyteSoftMargin=100;
p.VoltageFaultMargin=0;p.TemperatureFaultMargin=0;
p.VoltageMin=2.0;p.SOCmin=0;
p.DiagnosticVmax=4.25;p.DiagnosticVmin=2.0;
p.DiagnosticTmax=333.15;p.DiagnosticCeMin=1;p.DiagnosticAnodeMin=-.05;
p.ShutdownCurrentTolerance=.01;p.ShutdownMinTime=.5;p.ShutdownMaxTime=20;
p.MaxStep=1;p.RelTol=1e-5;p.AbsTol=1e-7;
p.RLsampleTime=10;
p.ThicknessAnode=8.52e-5; p.ThicknessSeparator=1.2e-5;p.ThicknessCathode=7.56e-5;
p.ElectrodePlateArea=.065*1.58;p.ParticleRadiusAnode=5.86e-6;p.ParticleRadiusCathode=5.22e-6;
p.ActiveMaterialVolumeFractionAnode=.75;p.ActiveMaterialVolumeFractionCathode=.665;
p.MaximumConcentrationAnode=33133;p.MaximumConcentrationCathode=63104;
p.MinimumStoichiometryAnode=.02634579027064577;p.MaximumStoichiometryAnode=.910618046652409;
p.MinimumStoichiometryCathode=.2638452245913301;p.MaximumStoichiometryCathode=.853974674630047;
p.ActiveMaterialDiffusionCoefficientAnode=3.3e-14;p.ActiveMaterialDiffusionCoefficientCathode=4e-15;
p.ConductivityAnode=215;p.ConductivityCathode=.18;p.CurrentCollectorResistance=0;
p.ElectrolyteVolumeFractionAnode=.25;p.ElectrolyteVolumeFractionSeparator=.47;p.ElectrolyteVolumeFractionCathode=.335;
% Simscape block uses constant transport coefficients at reference concentration.
p.ElectrolyteConductivity=.1297-2.51+3.329;
p.ElectrolyteDiffusionCoefficient=8.794e-11-3.972e-10+4.862e-10;
p.BruggemanExponentAnode=1.5;p.BruggemanExponentSeparator=1.5;p.BruggemanExponentCathode=1.5;
p.TransferenceNumber=.2594;
% Published exchange-current prefactors include F; Simscape k excludes F.
p.ChargeTransferRateAnode=6.48e-7/96485.33212;p.ChargeTransferRateCathode=3.42e-6/96485.33212;
p.ArrheniusReferenceTemperature=298.15;
% Positive 1e-6 J/mol satisfies block assertions while approximating zero Ea.
p.ActiveMaterialDiffusionActivationEnergyAnode=1e-6;p.ActiveMaterialDiffusionActivationEnergyCathode=1e-6;
p.ElectrolyteDiffusionActivationEnergy=1e-6;p.ElectrolyteConductivityActivationEnergy=1e-6;
p.ConductivityActivationEnergyAnode=1e-6;p.ConductivityActivationEnergyCathode=1e-6;
p.ChargeTransferActivationEnergyAnode=35000;p.ChargeTransferActivationEnergyCathode=17800;
% Core heat capacity from Chen2020 volumetric average; casing capacity additional.
th=[1.2e-5 8.52e-5 1.2e-5 7.56e-5 1.6e-5];
p.BatteryThermalMass=2.42e-5*sum(th.*[8960 1657 397 3262 2700].*[385 700 700 700 897])/sum(th);
p.Csurface=8;p.RcoreSurface=1.5;p.RsurfaceAmbient=6;
p.Sto=linspace(.001,.999,600)';s=p.Sto;
p.Un=1.9793*exp(-39.3631*s)+.2482-.0909*tanh(29.8538*(s-.1234))-.04478*tanh(14.9159*(s-.2769))-.0205*tanh(30.4444*(s-.6103));
p.Up=-.8090*s+4.4875-.0428*tanh(18.5138*(s-.5542))-17.7326*tanh(15.7890*(s-.3117))+17.5842*tanh(15.9308*(s-.3120));
end
