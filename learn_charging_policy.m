function summary=learn_charging_policy(p,episodes)
% Reproducible exploratory Q-learning directly on the protected Simscape plant.
if nargin<1,p=project_parameters();end
if nargin<2,episodes=100;end
rng(42,'twister');actions=[1.5 2.5 3.5 5 7.5];
obs=rlFiniteSetSpec(1:1024);act=rlFiniteSetSpec(actions);
qtable=rlTable(obs,act);critic=rlQValueFunction(qtable,obs,act);
opts=rlQAgentOptions('SampleTime',p.RLsampleTime,'DiscountFactor',.995);
opts.EpsilonGreedyExploration.Epsilon=.9;opts.EpsilonGreedyExploration.EpsilonMin=.05;
opts.EpsilonGreedyExploration.EpsilonDecay=5e-5;opts.CriticOptimizerOptions.LearnRate=.15;
chargingAgent=rlQAgent(critic,opts);assignin('base','chargingAgent',chargingAgent);
mdl=build_rl_model(p);
env=rlSimulinkEnv(mdl,[mdl '/RL Agent'],obs,act,'UseFastRestart','off');
env.ResetFcn=@resetEpisode;
trainingOptions=rlTrainingOptions('MaxEpisodes',episodes,'MaxStepsPerEpisode',ceil(p.Duration/p.RLsampleTime),...
 'Verbose',true,'Plots','none','StopTrainingCriteria','EpisodeCount','StopTrainingValue',episodes,...
 'UseParallel',false,'SimulationStorageType','none');
trainingStats=train(chargingAgent,env,trainingOptions);
save(fullfile(p.root,'results','learned_policy.mat'),'chargingAgent','trainingStats','trainingOptions','actions');
% Greedy evaluation retains the shutdown tail in the same full plant.
chargingAgent.UseExplorationPolicy=false;assignin('base','chargingAgent',chargingAgent);
pp=p;pp.UseExternalCurrent=1;
out=sim(make_simulation_input(pp,mdl));[m,tr]=summarize_case(pp,'rl_replay',out,mdl);
writetable(tr(:,{'time_s','soc','core_C','electrolyte_min_mol_m3','requested_current_A'}),fullfile(p.root,'results','rl_policy_replay.csv'));
summary=struct('algorithm','Reinforcement Learning Toolbox tabular Q-learning','engine','Direct Simulink/Simscape Battery plant',...
 'seed',42,'episodes',episodes,'observations','16 SOC x 8 core-temperature x 8 minimum-electrolyte bins',...
 'actions_A',actions,'sample_time_s',p.RLsampleTime,'nominal_evaluation',m,...
 'claim','Exploratory finite-budget policy; no superiority or convergence claim.');
write_json(fullfile(p.root,'results','rl_summary.json'),summary);
trainingTable=table(trainingStats.EpisodeIndex(:),trainingStats.EpisodeReward(:),...
 trainingStats.EpisodeSteps(:),trainingStats.AverageReward(:),...
 'VariableNames',{'episode','reward','steps','average_reward'});
writetable(trainingTable,fullfile(p.root,'results','rl_training.csv'));
function in=resetEpisode(in)
 pp=p;pp.SOC0=.1+.3*rand;temps=[15 25 35];pp.T0=273.15+temps(randi(3));pp.Tamb=pp.T0;pp.UseExternalCurrent=1;
 in=in.setVariable('p',prepare_case(pp),'Workspace',mdl);
 in=in.setModelParameter('StopTime',num2str(pp.Duration));
end
end
