% sim = 1;
% 
% % generative process (from task structure)
% 
% task.num_blocks = 2; % number of trials
% task.num_trials = 30; % number of trials
% 
% % whether loss is -40 or -80
% task.block_type(1) = "SL"; %small loss
% task.block_type(2) = "LL"; %large loss
% 
% %true context probabilities by block
% task.true_p_right(1,1:15) = .9;
% task.true_p_right(1,16:30) = .5;
% 
% task.true_p_right(2,1:15) = .5;
% task.true_p_right(2,16:30) = .9;
% 
% %true hint accuracies by block
% task.true_p_a(1,1:15) = .6;
% task.true_p_a(1,16:30) = .8;
% 
% task.true_p_a(2,1:15) = .6;
% task.true_p_a(2,16:30) = .8;
% 
% % parameters
% 
% %initial context and trust priors
% params.p_right = .5;
% params.p_right = .9;
% 
% %learning and forgetting rates
% 
% comment out to allow a/d specific types below
% 
% %params.omega = .2; 
% params.eta = .5;
% 

% 
% % win/loss specific params (only used based on commenting out above)
% 
% params.omega_a_win = .1; params.eta_a_win = .4;
% params.omega_a_loss = .3; params.eta_a_loss = .6;
% 
% params.omega_d_win = .4; params.eta_d_win = .7;
% params.omega_d_loss = .5; params.eta_d_loss = .8;
% 
% %explore-exploit weights
% params.reward_value = 1;
% params.l_loss_value = 1;
% params.state_exploration = 1;
% params.parameter_exploration = 1;
% params.inv_temp = 4;
% 
% %data
% observations.hints = [0 2 1;
%                       1 0 1]; %observations.hints(block,trial) 
% observations.rewards = [1 1 2;
%                         2 1 1];%observations.rewards(block,trial)
% choices(:,:,1) = [3 0;
%                   1 3;
%                   1 2];
% choices(:,:,2) = [1 2;
%                   3 0;
%                   1 2];
% if sim == 0
%     task.num_blocks = size(observations.rewards,1); % number of blocks
%     task.num_trials = size(observations.rewards,2); % number of trials
% end


function [results] = ModelFreeRLModel_TT(task, MDP, params, sim)

% observations.hints = 0 is no hint, 1 is left hint, 2 is right hint
% observations.rewards(trial) 1 is win, 2 is loss
% choices : 1 is advisor, 2 is left, 3 is right
task.num_trials = 30;
task.num_blocks = 12;
observations.hints = nan(1,task.num_trials);
observations.rewards = nan(1,task.num_trials);
choices = nan(task.num_trials,2);

for trial=1:task.num_trials
    trial_info = MDP(trial);
    observations.hints(trial) = trial_info.o(1,2)-1;
    % if selected advisor
    if observations.hints(trial) 
        observations.rewards(trial) = 4 - trial_info.o(2,3); % ryan made win 1, loss 2
        choices(trial,1) = 1;
        choices(trial,2) = trial_info.o(3,3)-1; % left is 2, right 3
    else
        observations.rewards(trial) = 4 - trial_info.o(2,2); % ryan made win 1, loss 2
        choices(trial,1) = trial_info.o(3,2)-1; % left is 2, right 3
        choices(trial,2) = 0;
    end
    
end

params.p_right = .5;
single_omega = 0;
single_eta = 0;
%field = task.field;
field = fieldnames(params);
for i = 1:length(field)
    if strcmp(field{i},'omega')
        params.omega_d_win = params.omega;
        params.omega_d_loss = params.omega;
        params.omega_a_win = params.omega;
        params.omega_a_loss = params.omega;
        params.omega_d = params.omega;
        params.omega_a = params.omega;
        single_omega = 1;
    elseif strcmp(field{i},'eta')
        params.eta_d_win = params.eta;
        params.eta_d_loss = params.eta;
        params.eta_a_win = params.eta;
        params.eta_a_loss = params.eta;
        params.eta_d = params.eta;
        params.eta_a = params.eta;
        single_eta = 1;
    end
end

for i = 1:length(field)
    if strcmp(field{i},'omega_d') & single_omega ~= 1
        params.omega_d_win = params.omega_d;
        params.omega_d_loss = params.omega_d;
    elseif strcmp(field{i},'eta_d') & single_eta ~= 1
        params.eta_d_win = params.eta_d;
        params.eta_d_loss = params.eta_d;
    elseif strcmp(field{i},'omega_a') & single_omega ~= 1
        params.omega_a_win = params.omega_a;
        params.omega_a_loss = params.omega_a;
    elseif strcmp(field{i},'eta_a') & single_eta ~= 1
        params.eta_a_win = params.eta_a;
        params.eta_a_loss = params.eta_a;
    end
end




%Simple three versions

% alpha = 0.5
% beta = 4

% Assuming observations.rewards is a vector
actualreward = [MDP.actualreward]; % Copy the original vector


% Initialize a 3x2x30 zero matrix
action_probs = zeros(3, 2, trial);

qvalue = zeros(3, 2, trial);

for t = 1:trial

exp_values = exp(params.inv_temp * qvalue(:, 1, t));
action_probs(:, 1, t) = exp_values / sum(exp_values);

if choices(t, 1) == 2 || choices(t, 1) == 3
  qvalue(choices(t, 1), 1, t+1) = qvalue(choices(t, 1), 1, t) + params.eta * (actualreward(t) - qvalue(choices(t, 1), 1, t));

    for i = 1:3
        if i ~= choices(t, 1)
            qvalue(i, 1, t+1) = (1-params.omega)*qvalue(i, 1, t);
        end
    end

    qvalue(:, 2, t+1) = (1-params.omega)*qvalue(:, 2, t);

end

if choices(t, 1) == 1 %advice

   exp_valuestwo = exp(params.inv_temp * qvalue(2:3, 2, t));
   action_probs(2:3, 2, t) = exp_valuestwo / sum(exp_valuestwo);

   deltaadvise = actualreward(t) + qvalue(choices(t, 2), 2, t) - qvalue(choices(t, 1), 1, t);
   qvalue(choices(t, 1), 1, t+1) = qvalue(choices(t, 1), 1, t) + params.eta * params.lamgda * deltaadvise;

   %Update the original 
   qvalue(choices(t, 2), 2, t+1) = qvalue(choices(t, 2), 2, t) + params.eta * (actualreward(t) - qvalue(choices(t, 1), 2, t));
   qvalue(choices(t, 2), 1, t+1) = qvalue(choices(t, 2), 1, t) + params.eta * (actualreward(t) - qvalue(choices(t, 2), 1, t));

   for i = 2:3
        if i ~= choices(t, 2)
            qvalue(i, 2, t+1) = (1-params.omega)*qvalue(i, 2, t);
            qvalue(i, 1, t+1) = (1-params.omega)*qvalue(i, 1, t);
        end
    end


end

end



% p_win = 1;
% a_floor = 1;
% context_floor = 1;
% 
% Below is the old active inference code
for block = 1:task.num_blocks
     block = 1;
%     clear Q
%     clear epistemic_value
%     clear pragmatic_value
%     clear novelty_value
%     
%     hint_outcomes(1,1:task.num_trials) = 0;
% 
%     for trial = 1:task.num_trials
%         hint_outcome_vector(:,trial) = [0 0]';
%         dir_context(:,:,trial) = zeros(2,1);
%         p_context(:,:,trial) = zeros(2,1);
%         pp_context(:,:,trial) = zeros(2,1);
%         true_context(:,:,trial) = zeros(2,1);
%         a{1}(:,:,trial) = zeros(2,2);
%         true_A{1}(:,:,trial) = zeros(2,2);
%         A{2}(:,:,trial) = zeros(2,2);
% %       action_probs(:,:,trial) = zeros(3,2);
% %        Q(:,:,trial) = zeros(3,1);
%         epistemic_value(:,:,trial) = zeros(3,1);
%         pragmatic_value(:,:,trial) = zeros(3,1);
%         novelty_value(:,:,trial) = zeros(3,1);
%         p_o_win(:,:,trial) = zeros(2,3);
%         if sim == 1
%             true_context_vector(trial) = find(rand < cumsum([1-task.true_p_right(block,trial) task.true_p_right(block,trial)]'),1)-1;
%         end
%     end
%  
% 
%     d_0 = [1-params.p_right params.p_right]'*context_floor;
%     a_0 =  [params.p_a 1-params.p_a;         % "try left"
%             1-params.p_a params.p_a]*a_floor;% "try right"   
% 
%    actions = zeros(task.num_trials,2);
%     
%     % reward value distribution
%     if task.block_type(block)== "LL"
%         R(:,block) =  spm_softmax([params.reward_value+eps -params.l_loss_value-eps]');
%     else
%         R(:,block) =  spm_softmax([params.reward_value+eps -eps]');
%     end
% 
%     if sim == 0
%         for trial = 1:task.num_trials
%             true_context_vector(trial) = task.true_p_right(block,trial);
%         end
%     end
% 
%     for trial = 1:task.num_trials
%         tp = 1; % initial timepoint
% 
%         
%             
%        
   
    
%     % compute information gain
%     % a_sums{1}(:,:,trial) = [sum(a{1}(:,1,trial)) sum(a{1}(:,2,trial));
%     %                         sum(a{1}(:,1,trial)) sum(a{1}(:,2,trial))];
%     % 
%     % info_gain = .5*((a{1}(:,:,trial).^-1)-(a_sums{1}(:,:,trial).^-1));
% 
% % compute action values (negative EFE)
%         for option = 1:3
%             if option == 1
%                 p_o_hint(:,trial) = A{1}(:,:,1)*p_context(:,:,trial);
%                 true_p_o_hint(:,trial) = true_A{1}(:,:,1)*true_context(:,:,trial);
%                 % novelty_value(option,tp,trial) = .5*dot(A{1}(:,1,trial),info_gain(:,1)) + .5*dot(A{1}(:,2,trial),info_gain(:,1));
%                 % novelty_value(option,tp,trial) = (sum(sum(a{1}(:,:,trial))))^-1;
%                 a_sums{1}(:,:,trial) = [sum(a{1}(:,1,trial)) sum(a{1}(:,2,trial)); sum(a{1}(:,1,trial)) sum(a{1}(:,2,trial))];
%                 info_gain = (a{1}(:,:,trial).^-1) - (a_sums{1}(:,:,trial).^-1);
%                 %marginalize over context state factor (i.e. left better or
%                 %right better)
%                 novelty_for_each_observation = info_gain(:,1)*p_context(1,:,trial) + info_gain(:,2)*p_context(2,:,trial);
%                 novelty_value(option,tp,trial) = sum(novelty_for_each_observation);
%                 epistemic_value(option,tp,trial) = G_epistemic_value(A{1}(:,:,trial),p_context(:,:,trial));
%                 pragmatic_value(option,tp,trial) = 0;
%             elseif option == 2 
%                 p_o_win(:,option,trial) = A{2}(:,:,1)*p_context(:,:,trial);
%                 true_p_o_win(:,option,trial) = A{2}(:,:,1)*true_context(:,:,trial);
%                 novelty_value(option,tp,trial) = 0;
%                 epistemic_value(option,tp,trial) = 0;
%                 pragmatic_value(option,tp,trial) = dot(p_o_win(:,option,trial),R(:,block));
%             elseif option == 3 
%                 p_o_win(:,option,trial) = A{2}(:,:,2)*p_context(:,:,trial);
%                 true_p_o_win(:,option,trial) = A{2}(:,:,2)*true_context(:,:,trial);
%                 novelty_value(option,tp,trial) = 0;
%                 epistemic_value(option,tp,trial) = 0;
%                 pragmatic_value(option,tp,trial) = dot(p_o_win(:,option,trial),R(:,block));
%             end
%             Q(option, tp,trial) = params.state_exploration*epistemic_value(option,tp,trial) + pragmatic_value(option,tp,trial) + params.parameter_exploration*novelty_value(option,tp,trial);
%         end
%     
            
%         % compute action probabilities
%         action_probs(:,tp,trial) = spm_softmax(params.inv_temp*Q(:,tp,trial))';
% 
%         % select actions
%         % note that 1 corresponds to choosing advisor, 2 corresponds to
%         % choosing left bandit, 3 corresponds to choosing right bandit.
%        
% 
%              if actions(trial,tp) == 3 && reward_outcomes(trial) == 1
%                 ppp_context(:,trial) = [0 1]';
%              elseif actions(trial,tp) == 2 && reward_outcomes(trial) == 2
%                 ppp_context(:,trial) = [0 1]';
%              elseif actions(trial,tp) == 2 && reward_outcomes(trial) == 1
%                 ppp_context(:,trial) = [1 0]';
%              elseif actions(trial,tp) == 3 && reward_outcomes(trial) == 2
%                 ppp_context(:,trial) = [1 0]';
%              end
% 
%         % if first action was choosing advisor, update likelihood matrices
%         % before picking pandit
%         elseif actions(trial,1) == 1
%             tp = 2; % second time point
% 
%             % get hint outcome
%             if sim == 1
%                 hint_outcomes(trial) = find(rand < cumsum(true_p_o_hint(:,trial)'),1);
%             else 
%                 hint_outcomes(trial) = observations.hints(block,trial);
%             end
% 
%             hint_outcome_vector(hint_outcomes(trial),trial) = 1;
% 
%             % state belief update
%         
%             pp_context(:,:,trial) = p_context(:,:,trial).*A{1}(:,hint_outcomes(trial),trial)...
%                             /sum(p_context(:,:,trial).*A{1}(:,hint_outcomes(trial),trial),1);
% 
% 
%             for option = 2:3
%                 Q(1, tp,trial) = eps;
%                 if option == 2 
%                     p_o_win(:,option,trial) = A{2}(:,:,1)*pp_context(:,:,trial);
%                     novelty_value(option,tp,trial) = 0;
%                     epistemic_value(option,tp,trial) = 0;
%                     pragmatic_value(option,tp,trial) = dot(p_o_win(:,option,trial),R(:,block));
%                 elseif option == 3 
%                     p_o_win(:,option,trial) = A{2}(:,:,2)*pp_context(:,:,trial);
%                     novelty_value(option,tp,trial) = 0;
%                     epistemic_value(option,tp,trial) = 0;
%                     pragmatic_value(option,tp,trial) = dot(p_o_win(:,option,trial),R(:,block));
%                 end
%                 Q(option, tp,trial) = params.state_exploration*epistemic_value(option,tp,trial) + pragmatic_value(option,tp,trial) + params.parameter_exploration*novelty_value(option,tp,trial);
%             end
%     
%             % compute action probabilities
%             action_probs(:,tp,trial) = [0; spm_softmax(params.inv_temp*Q(2:3,tp,trial))]';
% 
%             
%     
%            
%     
%         end   
% 
%         if reward_outcomes(trial) == 1
%             if actions(trial,1) == 1 
%                 % forgetting part
%                 a{1}(:,:,trial+1) = (a{1}(:,:,trial) - a_0)*(1-params.omega_a_win) + a_0;
%                 % learning part
%                 a{1}(:,:,trial+1) = a{1}(:,:,trial+1) + params.eta_a_win*(ppp_context(:,trial)*hint_outcome_vector(:,trial)')';
%             else
%                 a{1}(:,:,trial+1) = a{1}(:,:,trial);
%             end
%     
%                 % forgetting part
%                 dir_context(:,:,trial+1) = (dir_context(:,:,trial) - d_0)*(1-params.omega_d_win) + d_0;
%                 % learning part
%                 dir_context(:,:,trial+1) = dir_context(:,:,trial+1) + params.eta_d_win*ppp_context(:,trial);
%         elseif reward_outcomes(trial) == 2
%             if actions(trial,1) == 1 
%                 % forgetting part
%                 a{1}(:,:,trial+1) = (a{1}(:,:,trial) - a_0)*(1-params.omega_a_loss) + a_0;
%                 % learning part
%                 a{1}(:,:,trial+1) = a{1}(:,:,trial+1) + params.eta_a_loss*(ppp_context(:,trial)*hint_outcome_vector(:,trial)')';
%             else
%                 a{1}(:,:,trial+1) = a{1}(:,:,trial);
%             end
%     
%             % forgetting part
%             dir_context(:,:,trial+1) = (dir_context(:,:,trial) - d_0)*(1-params.omega_d_loss) + d_0;
%             % learning part
%             dir_context(:,:,trial+1) = dir_context(:,:,trial+1) + params.eta_d_loss*ppp_context(:,trial);
%         end
%     end

%results.observations.hints(block,:) = hint_outcomes;
%results.observations.rewards(block,:) = reward_outcomes;
results.choices(:,:,block) = choices(:,:);
%results.R(:,block) = R(:,block);

if block == 1
    results.input.task = task;
    results.input.params = params;
    results.input.observations = observations;
    results.input.choices = choices;
    results.input.sim = sim;
end


    results.blockwise(block).action_probs = action_probs;
    results.blockwise(block).actions = choices;
%    results.blockwise(block).true_context = true_context;
%    results.blockwise(block).hint_outcomes = hint_outcomes;
%    results.blockwise(block).hint_outcome_vector = hint_outcome_vector;
%    results.blockwise(block).reward_outcomes = reward_outcomes;
%    results.blockwise(block).action_values_Q = Q;
%    results.blockwise(block).epistemic_value = epistemic_value;
%    results.blockwise(block).pragmatic_value = pragmatic_value;
%    results.blockwise(block).state_priors_d = dir_context;
%    results.blockwise(block).norm_priors_d = p_context;
%    results.blockwise(block).norm_posteriors_d_t2 = pp_context;
%    results.blockwise(block).norm_posteriors_d_final = ppp_context;
%    results.blockwise(block).trust_priors_a = a{1};
%    results.blockwise(block).norm_trust_priors_a = A{1};




end

 
 





