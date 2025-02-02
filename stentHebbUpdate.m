function Wout = stentHebbUpdate(Win, preAct, postAct, eta)
    % Implements the update rule:
    % w_s' = w_s + eta * a_r * a_s  if a_s > mean(a_s)
    % w_s' = w_s                   otherwise
    
    % Calculate average presynaptic activation
    preAvg = mean(preAct);
    
    % Create a mask for presynaptic neurons where a_s > a_avg
    mask = preAct > preAvg;  % Logical array (1 where condition is true)
    
    % Calculate the weight update only for active connections
    dW = eta * ((mask .* preAct)' * postAct);  % Mask presynaptic activations
    
    % Apply the update
    Wout = Win + dW;
    
    % Normalize weights (column-wise)
    Wout = colNormalize(Wout);
end
