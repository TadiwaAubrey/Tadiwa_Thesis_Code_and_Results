function Cob = objective_function(NB, NR, NP, N, c, A_columns, Beta_columns)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%% This function generates objective function matrices %%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Inputs:
    %   NB    = number of buses
    %   NR    = number of routes
    %   NP    = number of passengers
    %   N     = final time step
    %   c     = bus operating cost
    %   A_columns = number of columns in Ain
    %   Beta_columns = number of slack variable columns
    %
    % Outputs:
    %   
    %   C_ob   = objective function matrix
    count_f = 1;
    
    Cob = zeros(1, A_columns);
    
    % Bus operating cost
    for b = 1 : NB
        for t = 0 : N
            R = 0;
            w_bRt_index  = ((b - 1) * (NR + 1) * (N + 1)) + (R * (N + 1)) + t + 1;
        
            A_w_bRt_minus_column = w_bRt_index;
            Cob(count_f, A_w_bRt_minus_column(:)) = -c{b};
        end 
    end
    
    count_f = count_f + 1;
    
    % Passenger Travel time cost
    for i = 1 : NP
        Beta_index = i;
    
        A_Beta_index_column = Beta_columns + Beta_index;
    
        Cob(count_f, A_Beta_index_column(:)) = 1;
    
    end

end