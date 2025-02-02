function act = lateralCompetition(netIn, inhib,x_thr,x_sat)
    % Soft competition: find the winner, subtract a fraction of it from the rest
    [maxVal, iMax] = max(netIn);
    maxAct = rampActivation(maxVal,x_thr,x_sat);
    act = zeros(size(netIn));
    for i = 1:length(netIn)
        if i == iMax
            act(i) = maxAct;
        else
            act(i) = rampActivation(netIn(i) - inhib*maxAct,x_thr,x_sat);
        end
    end
end