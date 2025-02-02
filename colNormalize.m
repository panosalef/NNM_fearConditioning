function Wn = colNormalize(W)
    % Column-normalize so each column sums to 1
    colSum = sum(W,1);
    colSum(colSum==0) = 1;  % avoid /0
    Wn = W ./ colSum;
end