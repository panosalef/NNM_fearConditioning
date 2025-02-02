function patts = make2byOverlap(nFreqs)
    % Creates an nFreqs x (nFreqs+1) matrix.
    % Each row i has 1 in column i and i+1.
    patts = zeros(nFreqs, nFreqs+1);
    for i = 1 : nFreqs
        patts(i, i)   = 1;
        patts(i, i+1) = 1;
    end
end