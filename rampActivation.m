function act = rampActivation(x, x_thr, x_sat)
    
    act = zeros(size(x));  % Initialize activation with zeros
    
    % Apply the piecewise function
    act(x > x_thr & x < x_sat) = x(x > x_thr & x < x_sat) - x_thr;
    act(x >= x_sat) = x_sat;
end