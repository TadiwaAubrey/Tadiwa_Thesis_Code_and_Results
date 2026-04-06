function [X, Y, I, J, Tmin] = generate_passengers_structured(NP, N, l_s, mode, seed)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% This function randomly generates passenger demand data %%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Inputs:
    %   NP    = number of passengers
    %   N     = final time step
    %   mode  = struct with fields:
    %           .demandLevel   = 'low', 'medium', or 'high'
    %           .deadlineLevel = 'loose', 'moderate', or 'tight'
    %   seed  = random seed for reproducibility
    %
    % Outputs:
    %   X     = origin stand
    %   Y     = destination stand
    %   I     = passenger arrival time at origin
    %   J     = desired arrival time at destination
    %   Tmin  = minimum stand-to-stand travel time
    
    %%%%%%%%%%% Check if user passed a value for seed %%%%%%%%%%
    if nargin >= 5
        rng(seed); 
    end

    stands = l_s;
    NS = length(stands);

    %%%%%%%%%%%%%% Build directed stand graph from routes %%%%%%%%%%%%%%%%%
    infVal = 1e6;

    D = infVal * ones(NS, NS);

    for s = 1 : NS
        D(s,s) = 0;
    end

    % R1 = [1 6 2 7 8 3 9 1]
    D(1,2) = 2;
    D(2,3) = 3;
    D(3,1) = 2;

    % R2 = [1 10 4 5 11 1]
    D(1,4) = 2;
    D(4,5) = 1;
    D(5,1) = 2;

    % R3 = [1 11 5 12 2 6 1]
    D(1,5) = 2;
    D(5,2) = 2;
    D(2,1) = 2;

    %%%%%%% Minimum time steps to go from stand X_i to stand Y_i %%%%%%%
    
    % Floyd - Warshall algorithm
    for k = 1 : NS
        for i = 1 : NS
            for j = 1 : NS

                D(i,j) = min(D(i,j), D(i,k) + D(k,j));

            end
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%% Configure distributions %%%%%%%%%%%%%%%%%%%%%%%
    switch lower(mode.demandLevel)
        case 'low'
            originProb = [0.20 0.20 0.20 0.20 0.20];
            destBiasTo1 = 0.20;
            timeProfile = 'uniform';

        case 'medium'
            originProb = [0.25 0.25 0.15 0.15 0.20];
            destBiasTo1 = 0.30;
            timeProfile = 'frontloaded';

        case 'high'
            originProb = [0.30 0.30 0.10 0.10 0.20];
            destBiasTo1 = 0.40;
            timeProfile = 'peaked';

        otherwise
            error('Please input valid demand level.')
    end

    switch lower(mode.deadlineLevel)
        case 'loose'
            slackMin = 0;
            slackMax = 6;

        case 'moderate'
            slackMin = 1;
            slackMax = 3;

        case 'tight'
            slackMin = 0;
            slackMax = 1;

        otherwise
            error('Please input valid deadline level.')
    end

    %%%%%%%%%%%%%%%%%%%%%% Generate passengers %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    X = zeros(NP,1);
    Y = zeros(NP,1);
    I = zeros(NP,1);
    J = zeros(NP,1);
    Tmin = zeros(NP,1);

    for p = 1:NP
        feasiblePassenger = false;

        while ~feasiblePassenger

            % Source bus stand
            x = sample_from_probs(stands, originProb);

            % Destination bus stand
            yCandidates = stands(stands ~= x);

            % Base destination probabilities
            yProb = ones(1, length(yCandidates));
            yProb = yProb / sum(yProb);

            % We want stand 1 to be chosen more often for destinations
            idx1 = find(yCandidates == 1);
            if ~isempty(idx1)
                yProb = (1 - destBiasTo1) * yProb;
                yProb(idx1) = yProb(idx1) + destBiasTo1;
                yProb = yProb / sum(yProb);
            end

            y = sample_from_probs(yCandidates, yProb);

            % Calculate minimum travel time-
            tmin = D(x,y);
            if tmin >= infVal
                continue;
            end

            % Generate I_i
            latestI = N - tmin - slackMin;
            if latestI < 0
                continue;
            end

            i_p = sample_time(latestI, timeProfile);

            % Generate J_i
            earliestJ = i_p + tmin;

            actualSlackMax = min(slackMax, N - earliestJ);
            actualSlackMin = min(slackMin, actualSlackMax);

            if actualSlackMax < 0
                continue;
            end

            if actualSlackMin > actualSlackMax
                actualSlackMin = actualSlackMax;
            end

            delta = randi([actualSlackMin, actualSlackMax]);
            j_p = earliestJ + delta;

            % store everything for output
            X(p) = x;
            Y(p) = y;
            I(p) = i_p;
            J(p) = j_p;
            Tmin(p) = tmin;

            feasiblePassenger = true;
        end
    end
end

%%%%%% Sample one value from a discrete set with probabilities %%%%%%%
function val = sample_from_probs(values, probs)
    cdf = cumsum(probs(:)' / sum(probs));
    r = rand;
    idx = find(r <= cdf, 1, 'first');
    val = values(idx);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%% Generate arrival times %%%%%%%%%%%%%%%%%%%
function t = sample_time(latestI, profile)

    switch lower(profile)
        case 'uniform'
            t = randi([0, latestI]);

        case 'frontloaded'
            % More passengers near earlier times
            weights = (latestI + 1:-1:1);
            probs = weights / sum(weights);
            tVals = 0:latestI;
            t = sample_from_probs(tVals, probs);

        case 'peaked'
            % Stronger concentration near the first third of the horizon
            tVals = 0:latestI;
            center = round(latestI / 3);
            sigma = max(1, latestI / 6);
            weights = exp(-((tVals - center).^2) / (2 * sigma^2));
            probs = weights / sum(weights);
            t = sample_from_probs(tVals, probs);

        otherwise
            error('Unknown time profile.')
    end
end