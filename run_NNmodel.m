%% Fear Conditioning Model with 2-by Overlap Inputs
rng('default'); rng(0);  % For reproducibility

%----------------------- Model Structure -----------------------%
nFreqs  = 15;  % number of discrete "tone frequencies"
% Module sizes (as in the paper)
nMGv    = 8;
nMGm    = 3;
nCtx    = 8;
nAmy    = 3;

% US weights (fixed).  They provide additive activation to MGm & Amy
wUS_MGm = 0.4;
wUS_Amy = 0.4;

% Lateral inhibition factor (0 = no competition, 1 = winner-take-all)
inhibFactor = 0.2;
% Learning rate
eta = 0.1;


% Activation function params
x_thr = 0;
x_sat = 1;

%------------------ Construct Overlapping Inputs --------------%
% make2byOverlap(nFreqs) returns an nFreqs x (nFreqs+1) matrix
% so each row has exactly two 1’s, e.g. row i -> columns i and i+1.
freqPatterns = make2byOverlap(nFreqs);
% That means each row is length = nFreqs+1. For nFreqs=15, row length = 16.

%------------------- Initialize Weights Randomly --------------%
% Because each input pattern is 1 x (nFreqs+1), we need
% the input->MGv and input->MGm weight matrices to have (nFreqs+1) rows:
W_in_MGv  = rand(nFreqs+1,  nMGv);
W_in_MGm  = rand(nFreqs+1,  nMGm);

% The rest remain the same shape as before:
W_MGv_Ctx = rand(nMGv,      nCtx);
W_MGm_Ctx = rand(nMGm,      nCtx);
W_MGm_Amy = rand(nMGm,      nAmy);
W_Ctx_Amy = rand(nCtx,      nAmy);

% Normalize columns so sum of each column = 1
W_in_MGv    = colNormalize(W_in_MGv);
W_in_MGm    = colNormalize(W_in_MGm);
W_MGv_Ctx   = colNormalize(W_MGv_Ctx);
W_MGm_Ctx   = colNormalize(W_MGm_Ctx);
W_MGm_Amy   = colNormalize(W_MGm_Amy);
W_Ctx_Amy   = colNormalize(W_Ctx_Amy);

%% -------------------- PHASE 1: Development ---------------------%
% Present all freq patterns multiple times WITHOUT the US
nEpochs_dev = 100;
for ep = 1:nEpochs_dev
    order = randperm(nFreqs);
    for fIdx = order
        % freqPatterns(fIdx,:) is 1 x (nFreqs+1)
        inp = freqPatterns(fIdx,:);
        
        % Forward pass
        mgv_net = inp * W_in_MGv;  % (1 x (nFreqs+1)) * ((nFreqs+1) x nMGv) => (1 x nMGv)
        mgv_act = lateralCompetition(mgv_net, inhibFactor,x_thr,x_sat);
        
        mgm_net = inp * W_in_MGm;  % => (1 x nMGm)
        mgm_act = lateralCompetition(mgm_net, inhibFactor,x_thr,x_sat);
        
        ctx_net = mgv_act * W_MGv_Ctx + mgm_act * W_MGm_Ctx; % => (1 x nCtx)
        ctx_act = lateralCompetition(ctx_net, inhibFactor,x_thr,x_sat);
        
        amy_net = mgm_act * W_MGm_Amy + ctx_act * W_Ctx_Amy; % => (1 x nAmy)
        amy_act = lateralCompetition(amy_net, inhibFactor,x_thr,x_sat);
        
        % Hebbian updates
        W_in_MGv   = stentHebbUpdate(W_in_MGv,   inp,     mgv_act, eta);
        W_in_MGm   = stentHebbUpdate(W_in_MGm,   inp,     mgm_act, eta);
        W_MGv_Ctx  = stentHebbUpdate(W_MGv_Ctx,  mgv_act, ctx_act, eta);
        W_MGm_Ctx  = stentHebbUpdate(W_MGm_Ctx,  mgm_act, ctx_act, eta);
        W_MGm_Amy  = stentHebbUpdate(W_MGm_Amy,  mgm_act, amy_act, eta);
        W_Ctx_Amy  = stentHebbUpdate(W_Ctx_Amy,  ctx_act, amy_act, eta);
    end
end



%% Forward Pass before conditioning
pre_MGv = nan(nMGv,nFreqs);
pre_MGm = nan(nMGm,nFreqs);
pre_Ctx = nan(nCtx,nFreqs);
pre_Amy = nan(nAmy,nFreqs);


for fIdx = 1:nFreqs
    % freqPatterns(fIdx,:) is 1 x (nFreqs+1)
    inp = freqPatterns(fIdx,:);
    
    % Forward pass
    mgv_net = inp * W_in_MGv;  % (1 x (nFreqs+1)) * ((nFreqs+1) x nMGv) => (1 x nMGv)
    mgv_act = lateralCompetition(mgv_net, inhibFactor,x_thr,x_sat);
    
    mgm_net = inp * W_in_MGm;  % => (1 x nMGm)
    mgm_act = lateralCompetition(mgm_net, inhibFactor,x_thr,x_sat);
    
    ctx_net = mgv_act * W_MGv_Ctx + mgm_act * W_MGm_Ctx; % => (1 x nCtx)
    ctx_act = lateralCompetition(ctx_net, inhibFactor,x_thr,x_sat);
    
    amy_net = mgm_act * W_MGm_Amy + ctx_act * W_Ctx_Amy; % => (1 x nAmy)
    amy_act = lateralCompetition(amy_net, inhibFactor,x_thr,x_sat);
    
    pre_MGv(:,fIdx) = mgv_act';
    pre_MGm(:,fIdx) = mgm_act';
    pre_Ctx(:,fIdx) = ctx_act';
    pre_Amy(:,fIdx) = amy_act';
end



%% --------------------- PHASE 2: Conditioning -------------------%
% Choose one frequency as CS (e.g. #8)
CS_index = 8;
nTrials_cond = 100;
for t = 1:nTrials_cond
    inp = freqPatterns(CS_index,:);
    
    mgv_net = inp * W_in_MGv;
    mgv_act = lateralCompetition(mgv_net, inhibFactor,x_thr,x_sat);
    
    % Add US to MGm
    mgm_net = inp * W_in_MGm + wUS_MGm;
    mgm_act = lateralCompetition(mgm_net, inhibFactor,x_thr,x_sat);
    
    ctx_net = mgv_act * W_MGv_Ctx + mgm_act * W_MGm_Ctx;
    ctx_act = lateralCompetition(ctx_net, inhibFactor,x_thr,x_sat);
    
    % Add US to Amy
    amy_net = mgm_act * W_MGm_Amy + ctx_act * W_Ctx_Amy + wUS_Amy;
    amy_act = lateralCompetition(amy_net, inhibFactor,x_thr,x_sat);
    
    % Hebbian updates
    W_in_MGv   = stentHebbUpdate(W_in_MGv,   inp, mgv_act, eta);
    W_in_MGm   = stentHebbUpdate(W_in_MGm,   inp, mgm_act, eta);
    W_MGv_Ctx  = stentHebbUpdate(W_MGv_Ctx,  mgv_act, ctx_act, eta);
    W_MGm_Ctx  = stentHebbUpdate(W_MGm_Ctx,  mgm_act, ctx_act, eta);  % <--- watch for typos
    W_MGm_Amy  = stentHebbUpdate(W_MGm_Amy,  mgm_act, amy_act, eta);
    W_Ctx_Amy  = stentHebbUpdate(W_Ctx_Amy,  ctx_act, amy_act, eta);
end


%% Forward Pass after conditioning
post_MGv = nan(nMGv,nFreqs);
post_MGm = nan(nMGm,nFreqs);
post_Ctx = nan(nCtx,nFreqs);
post_Amy = nan(nAmy,nFreqs);

for fIdx = 1:nFreqs
    % freqPatterns(fIdx,:) is 1 x (nFreqs+1)
    inp = freqPatterns(fIdx,:);
    
    % Forward pass
    mgv_net = inp * W_in_MGv;  % (1 x (nFreqs+1)) * ((nFreqs+1) x nMGv) => (1 x nMGv)
    mgv_act = lateralCompetition(mgv_net, inhibFactor,x_thr,x_sat);
    
    mgm_net = inp * W_in_MGm;  % => (1 x nMGm)
    mgm_act = lateralCompetition(mgm_net, inhibFactor,x_thr,x_sat);
    
    ctx_net = mgv_act * W_MGv_Ctx + mgm_act * W_MGm_Ctx; % => (1 x nCtx)
    ctx_act = lateralCompetition(ctx_net, inhibFactor,x_thr,x_sat);
    
    amy_net = mgm_act * W_MGm_Amy + ctx_act * W_Ctx_Amy; % => (1 x nAmy)
    amy_act = lateralCompetition(amy_net, inhibFactor,x_thr,x_sat);
    
    post_MGv(:,fIdx) = mgv_act';
    post_MGm(:,fIdx) = mgm_act';
    post_Ctx(:,fIdx) = ctx_act';
    post_Amy(:,fIdx) = amy_act';
end

%% FIGURE 3 %%


%% Plot MGm
unitMGm = 1;

% Create the figure
figure;

% Pre-allocate for better organization
[~, best_MGm] = max(pre_MGm(unitMGm,:));

% First subplot: Pre & Post Receptive Fields (RFs)
subplot(2,1,1);
hold on;

% Plot pre-conditioning receptive fields
plot(1:nFreqs, pre_MGm(unitMGm,:), '-o', 'LineWidth', 1.5, 'DisplayName', 'Pre RF');

% Plot post-conditioning receptive fields
plot(1:nFreqs, post_MGm(unitMGm,:), '-s', 'LineWidth', 1.5, 'DisplayName', 'Post RF');

% Highlight the best frequency before conditioning
plot(best_MGm, pre_MGm(unitMGm, best_MGm), 'r*', 'MarkerSize', 10, 'DisplayName', 'Best Freq (Pre)');

% Highlight the conditioned stimulus index
plot(CS_index, pre_MGm(unitMGm, CS_index), 'kx', 'MarkerSize', 10, 'DisplayName', 'CS Index');

% Titles and labels
ylim([0 1])
title('Pre & Post RF', 'FontSize', 14);
xlabel('Frequency (a.u.)', 'FontSize', 12);
ylabel('Activation', 'FontSize', 12);
legend('show', 'Location', 'Best');
grid on;

% Second subplot: Post Minus Pre RF
subplot(2,1,2);
hold on;

% Plot the difference between post and pre receptive fields
plot(1:nFreqs, post_MGm(unitMGm,:) - pre_MGm(unitMGm,:), '-^', 'LineWidth', 1.5, 'DisplayName', 'Post - Pre RF');

% Highlight the best frequency and CS index difference
plot(best_MGm, post_MGm(unitMGm, best_MGm) - pre_MGm(unitMGm, best_MGm), 'r*', 'MarkerSize', 10, 'DisplayName', 'Best Freq Diff');
plot(CS_index, post_MGm(unitMGm, CS_index) - pre_MGm(unitMGm, CS_index), 'kx', 'MarkerSize', 10, 'DisplayName', 'CS Diff');

% Titles and labels
ylim([-1 1])
title('Post minus Pre RF', 'FontSize', 14);
xlabel('Frequency (a.u.)', 'FontSize', 12);
ylabel('Activation Difference', 'FontSize', 12);
% legend('show', 'Location', 'Best');
grid on;

% Add a super title for the figure
sgtitle('MGm Receptive Fields', 'FontSize', 16);


%% Plot Amygdala
unitAmy = 3;

% Create the figure
figure;

% Pre-allocate for better organization
[~, best_Amy] = max(pre_Amy(unitAmy,:));

% First subplot: Pre & Post Receptive Fields (RFs)
subplot(2,1,1);
hold on;

% Plot pre-conditioning receptive fields
plot(1:nFreqs, pre_Amy(unitAmy,:), '-o', 'LineWidth', 1.5, 'DisplayName', 'Pre RF');

% Plot post-conditioning receptive fields
plot(1:nFreqs, post_Amy(unitAmy,:), '-s', 'LineWidth', 1.5, 'DisplayName', 'Post RF');

% Highlight the best frequency before conditioning
plot(best_Amy, pre_Amy(unitAmy, best_Amy), 'r*', 'MarkerSize', 10, 'DisplayName', 'Best Freq (Pre)');

% Highlight the conditioned stimulus index
plot(CS_index, pre_Amy(unitAmy, CS_index), 'kx', 'MarkerSize', 10, 'DisplayName', 'CS Index');

% Titles and labels
ylim([0 1])
title('Pre & Post RF', 'FontSize', 14);
xlabel('Frequency (a.u.)', 'FontSize', 12);
ylabel('Activation', 'FontSize', 12);
legend('show', 'Location', 'Best');
grid on;

% Second subplot: Post Minus Pre RF
subplot(2,1,2);
hold on;

% Plot the difference between post and pre receptive fields
plot(1:nFreqs, post_Amy(unitAmy,:) - pre_Amy(unitAmy,:), '-^', 'LineWidth', 1.5, 'DisplayName', 'Post - Pre RF');

% Highlight the best frequency and CS index difference
plot(best_Amy, post_Amy(unitAmy, best_Amy) - pre_Amy(unitAmy, best_Amy), 'r*', 'MarkerSize', 10, 'DisplayName', 'Best Freq Diff');
plot(CS_index, post_Amy(unitAmy, CS_index) - pre_Amy(unitAmy, CS_index), 'kx', 'MarkerSize', 10, 'DisplayName', 'CS Diff');

% Titles and labels
ylim([-1 1])
title('Post minus Pre RF', 'FontSize', 14);
xlabel('Frequency (a.u.)', 'FontSize', 12);
ylabel('Activation Difference', 'FontSize', 12);
% legend('show', 'Location', 'Best');
grid on;

% Add a super title for the figure
sgtitle('Amygdala Receptive Fields', 'FontSize', 16);




%% Plot MGv
unitMGv = 5;

% Create the figure
figure;

% Pre-allocate for better organization
[~, best_MGv] = max(pre_MGv(unitMGv,:));

% First subplot: Pre & Post Receptive Fields (RFs)
subplot(2,1,1);
hold on;

% Plot pre-conditioning receptive fields
plot(1:nFreqs, pre_MGv(unitMGv,:), '-o', 'LineWidth', 1.5, 'DisplayName', 'Pre RF');

% Plot post-conditioning receptive fields
plot(1:nFreqs, post_MGv(unitMGv,:), '-s', 'LineWidth', 1.5, 'DisplayName', 'Post RF');

% Highlight the best frequency before conditioning
plot(best_MGv, pre_MGv(unitMGv, best_MGv), 'r*', 'MarkerSize', 10, 'DisplayName', 'Best Freq (Pre)');

% Highlight the conditioned stimulus index
plot(CS_index, pre_MGv(unitMGv, CS_index), 'kx', 'MarkerSize', 10, 'DisplayName', 'CS Index');

% Titles and labels
ylim([0 1])
title('Pre & Post RF', 'FontSize', 14);
xlabel('Frequency (a.u.)', 'FontSize', 12);
ylabel('Activation', 'FontSize', 12);
legend('show', 'Location', 'Best');
grid on;

% Second subplot: Post Minus Pre RF
subplot(2,1,2);
hold on;

% Plot the difference between post and pre receptive fields
plot(1:nFreqs, post_MGv(unitMGv,:) - pre_MGv(unitMGv,:), '-^', 'LineWidth', 1.5, 'DisplayName', 'Post - Pre RF');

% Highlight the best frequency and CS index difference
plot(best_MGv, post_MGv(unitMGv, best_MGv) - pre_MGv(unitMGv, best_MGv), 'r*', 'MarkerSize', 10, 'DisplayName', 'Best Freq Diff');
plot(CS_index, post_MGv(unitMGv, CS_index) - pre_MGv(unitMGv, CS_index), 'kx', 'MarkerSize', 10, 'DisplayName', 'CS Diff');

% Titles and labels
ylim([-1 1])
title('Post minus Pre RF', 'FontSize', 14);
xlabel('Frequency (a.u.)', 'FontSize', 12);
ylabel('Activation Difference', 'FontSize', 12);
% legend('show', 'Location', 'Best');
grid on;

% Add a super title for the figure
sgtitle('MGv Receptive Fields', 'FontSize', 16);





%% Plot Cortex
unitCtx = 5;

% Create the figure
figure;

% Pre-allocate for better organization
[~, best_Ctx] = max(pre_Ctx(unitCtx,:));

% First subplot: Pre & Post Receptive Fields (RFs)
subplot(2,1,1);
hold on;

% Plot pre-conditioning receptive fields
plot(1:nFreqs, pre_Ctx(unitCtx,:), '-o', 'LineWidth', 1.5, 'DisplayName', 'Pre RF');

% Plot post-conditioning receptive fields
plot(1:nFreqs, post_Ctx(unitCtx,:), '-s', 'LineWidth', 1.5, 'DisplayName', 'Post RF');

% Highlight the best frequency before conditioning
plot(best_Ctx, pre_Ctx(unitCtx, best_Ctx), 'r*', 'MarkerSize', 10, 'DisplayName', 'Best Freq (Pre)');

% Highlight the conditioned stimulus index
plot(CS_index, pre_Ctx(unitCtx, CS_index), 'kx', 'MarkerSize', 10, 'DisplayName', 'CS Index');

% Titles and labels
ylim([0 1])
title('Pre & Post RF', 'FontSize', 14);
xlabel('Frequency (a.u.)', 'FontSize', 12);
ylabel('Activation', 'FontSize', 12);
legend('show', 'Location', 'Best');
grid on;

% Second subplot: Post Minus Pre RF
subplot(2,1,2);
hold on;

% Plot the difference between post and pre receptive fields
plot(1:nFreqs, post_Ctx(unitCtx,:) - pre_Ctx(unitCtx,:), '-^', 'LineWidth', 1.5, 'DisplayName', 'Post - Pre RF');

% Highlight the best frequency and CS index difference
plot(best_Ctx, post_Ctx(unitCtx, best_Ctx) - pre_Ctx(unitCtx, best_Ctx), 'r*', 'MarkerSize', 10, 'DisplayName', 'Best Freq Diff');
plot(CS_index, post_Ctx(unitCtx, CS_index) - pre_Ctx(unitCtx, CS_index), 'kx', 'MarkerSize', 10, 'DisplayName', 'CS Diff');

% Titles and labels
ylim([-1 1])
title('Post minus Pre RF', 'FontSize', 14);
xlabel('Frequency (a.u.)', 'FontSize', 12);
ylabel('Activation Difference', 'FontSize', 12);
% legend('show', 'Location', 'Best');
grid on;

% Add a super title for the figure
sgtitle('Auditory Cortex Receptive Fields', 'FontSize', 16);


%% FIGURE 4 %%


%% Plot
% Calculate mean responses
behavior_pre = mean(pre_Amy);
behavior_post = mean(post_Amy);

figure;
set(gcf, 'Position', [100, 100, 800, 600]); % Adjust figure size

% Subplot 1: Bar plot for CS index pre and post conditioning
subplot(2,1,1);
bar([1, 2], [behavior_pre(CS_index), behavior_post(CS_index)], 'FaceColor', 'flat');
ylim([0, 1.2]); % Set y-axis limits
xticks([1, 2]);
xticklabels({'Pre', 'Post'});
ylabel('Response', 'FontSize', 12);
grid on;

% Subplot 2: Line plot of generalization gradients
subplot(2,1,2);
hold on;

% Plot pre-conditioning receptive fields
plot(1:nFreqs, behavior_pre, '-o', 'LineWidth', 1.5, 'Color', 'b', 'DisplayName', 'Pre');

% Plot post-conditioning receptive fields
plot(1:nFreqs, behavior_post, '-s', 'LineWidth', 1.5, 'Color', 'r', 'DisplayName', 'Post');

% Highlight the conditioned stimulus index
plot(CS_index, behavior_post(CS_index), 'kx', 'MarkerSize', 10, 'DisplayName', 'CS Freq');

% Customize plot appearance
ylim([0, 1.2]); % Set y-axis limits
xlabel('Frequency (a.u.)', 'FontSize', 12);
ylabel('Response', 'FontSize', 12);
legend('show', 'Location', 'Best');
grid on;

% Add overall title
sgtitle('Amygdala Response', 'FontSize', 16);















