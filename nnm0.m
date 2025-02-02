% Fear Conditioning Neural Network Model (MATLAB Implementation)
clear; clc; close all;

%% Parameters
nFreqs = 15;         % Number of auditory frequencies
nMGm = 5;            % Number of units in MGm/PIN
nMGv = 10;           % Number of units in MGv
nCortex = 10;        % Number of units in Auditory Cortex
nAmygdala = 5;       % Number of units in Amygdala
nUS = 1;             % Nociceptive input unit (US)

learning_rate = 0.1; % Learning rate for Hebbian learning
lateral_inhibition = 0.2; % Inhibition factor

%% Initialize Network Weights (Random Small Values)
W_CS_MGm = rand(nMGm, nFreqs) * 0.1; % Connections from CS to MGm
W_CS_MGv = rand(nMGv, nFreqs) * 0.1; % Connections from CS to MGv
W_MGm_Amygdala = rand(nAmygdala, nMGm) * 0.1; % MGm to Amygdala
W_MGv_Cortex = rand(nCortex, nMGv) * 0.1; % MGv to Cortex
W_Cortex_Amygdala = rand(nAmygdala, nCortex) * 0.1; % Cortex to Amygdala
W_US_Amygdala = ones(nAmygdala, nUS) * 0.4; % Fixed US input

%% Generate Auditory Inputs (CS)
CS_inputs = eye(nFreqs); % Each frequency activates one neuron

%% Preconditioning Phase (Feature Development)
disp('Preconditioning Phase...');
for epoch = 1:100
    for f = 1:nFreqs
        % Activate frequency input
        input_CS = CS_inputs(f, :);
        
        % Compute MGm and MGv activations
        act_MGm = W_CS_MGm * input_CS';
        act_MGv = W_CS_MGv * input_CS';
        
        % Compute Cortex activation
        act_Cortex = W_MGv_Cortex * act_MGv;
        
        % Compute Amygdala activation
        act_Amygdala = W_MGm_Amygdala * act_MGm + W_Cortex_Amygdala * act_Cortex;
        
        % Lateral inhibition (competition)
        act_Amygdala = act_Amygdala - lateral_inhibition * max(act_Amygdala);
        
        % Normalize activity
        act_Amygdala = max(0, act_Amygdala);
        
        % Hebbian Learning (Self-organization)
        W_CS_MGm = W_CS_MGm + learning_rate * (act_MGm * input_CS);
        W_CS_MGv = W_CS_MGv + learning_rate * (act_MGv * input_CS);
        W_MGm_Amygdala = W_MGm_Amygdala + learning_rate * (act_Amygdala * act_MGm');
        W_Cortex_Amygdala = W_Cortex_Amygdala + learning_rate * (act_Amygdala * act_Cortex');
    end
end

%% Conditioning Phase (CS-US Pairing)
disp('Conditioning Phase...');
CS_conditioned = 8; % Select a frequency as CS
US = 1; % Nociceptive input (constant activation)

for epoch = 1:100
    input_CS = CS_inputs(CS_conditioned, :);
    
    % Compute activations
    act_MGm = W_CS_MGm * input_CS';
    act_MGv = W_CS_MGv * input_CS';
    act_Cortex = W_MGv_Cortex * act_MGv;
    act_Amygdala = W_MGm_Amygdala * act_MGm + W_Cortex_Amygdala * act_Cortex + W_US_Amygdala * US;
    
    % Lateral inhibition (competition)
    act_Amygdala = act_Amygdala - lateral_inhibition * max(act_Amygdala);
    act_Amygdala = max(0, act_Amygdala);
    
    % Hebbian Learning
    W_CS_MGm = W_CS_MGm + learning_rate * (act_MGm * input_CS);
    W_CS_MGv = W_CS_MGv + learning_rate * (act_MGv * input_CS);
    W_MGm_Amygdala = W_MGm_Amygdala + learning_rate * (act_Amygdala * act_MGm');
    W_Cortex_Amygdala = W_Cortex_Amygdala + learning_rate * (act_Amygdala * act_Cortex');
end

%% Post-Conditioning Testing
disp('Post-Conditioning Testing...');
responses = zeros(1, nFreqs);

for f = 1:nFreqs
    input_CS = CS_inputs(f, :);
    
    % Compute activations
    act_MGm = W_CS_MGm * input_CS';
    act_MGv = W_CS_MGv * input_CS';
    act_Cortex = W_MGv_Cortex * act_MGv;
    act_Amygdala = W_MGm_Amygdala * act_MGm + W_Cortex_Amygdala * act_Cortex;
    
    % Lateral inhibition (competition)
    act_Amygdala = act_Amygdala - lateral_inhibition * max(act_Amygdala);
    act_Amygdala = max(0, act_Amygdala);
    
    % Store amygdala output response
    responses(f) = sum(act_Amygdala);
end

%% Plot Generalization Gradient
figure;
plot(1:nFreqs, responses, '-o', 'LineWidth', 2);
xlabel('Frequency (CS)');
ylabel('Amygdala Activation');
title('Generalization Gradient After Conditioning');
grid on;
