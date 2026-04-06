function [Aeq, beq] = equality_constraints(X, I, NB, NR, NP, NL, l_s, N)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%% This function randomly generates passenger demand data %%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Inputs:
    %   X     = origin stand
    %   I     = passenger arrival time at origin
    %   NB    = number of buses
    %   NR    = number of routes
    %   NP    = number of passengers
    %   NL    = number of locations
    %   l_s   = locations that are bus stands
    %   N     = final time step
    %
    % Outputs:
    %   
    %   A_eq  = equality constraint matrix
    %   b_eq  = RHS equality constraint vector

    %%%%%%%%%%%%%%%%%%%%%% Number of Elements %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    n_w_bRt_minus = NB * (NR + 1) * (N + 1);
    n_w_bRt_plus  = NB * (NR + 1) * (N + 1);
    
    n_x_blt_minus = NB * NL * (N + 1);
    n_x_blt_plus  = NB * NL * (N + 1);
    
    n_y_ibt_minus = NP * NB * (N + 1);
    n_y_ibt_plus  = NP * NB * (N + 1);
    
    n_z_ist_minus = NP * NL * (N + 1);
    n_z_ist_plus  = NP * NL * (N + 1);
    
    % Number of columns in A
    A_columns = n_w_bRt_minus + n_w_bRt_plus + n_x_blt_minus + n_x_blt_plus +...
                n_y_ibt_minus + n_y_ibt_plus + n_z_ist_minus + n_z_ist_plus + NP;
    
    
    count_eq = 1;
    
    num_c_1 = NB * (N + 1);
    num_c_2 = num_c_1;
    num_c_3 = NB * N * (NR + 1);
    num_c_4 = NB * NL * (N + 1);
    num_c_5 = NB * (N + 1);
    num_c_6 = NB * (N + 1);
    num_c_7 = NP * (N + 1);
    num_c_8 = NP * (N + 1);
    num_c_9 = sum(cellfun(@(x) x + 1, I));
    num_c_10 = NB;
    num_c_11 = NB;
    num_c_12 = NB;
    num_c_13 = NB;
    num_c_14 = NP * NB * N;
    num_c_15 = NP * NL * N;
    
    num_eq_constraints = sum([ ...
        num_c_1, num_c_2, num_c_3, num_c_4, num_c_5, num_c_6, 2 * num_c_7,...
        num_c_8, num_c_9, num_c_10, num_c_11, num_c_12, num_c_13,...
        num_c_14, num_c_15
    ]);
    
    % With fixed routes use this instead to find num_eq_constraints.
    % You will also need to uncomment the last two for loops in this
    % function
    % num_eq_constraints = sum([ ...
    %     num_c_1, num_c_2, num_c_3, num_c_4, num_c_5, num_c_6, num_c_7, num_c_8, ...
    %     num_c_9, num_c_10, num_c_11, num_c_12, num_c_13, num_c_14, num_c_15 + 2 * (N + 1) ...
    % ]);
    
    
    Aeq = sparse(num_eq_constraints, A_columns);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % At any time t-, a bus can only be assigned to one route
    % \sum_{R = 0}^{NR} w_{bRt^-} = 1 \forall b \forall t^-
    
    for b = 1 : NB
        for t = 0 : N
            for R = 0 : NR
                w_bRt_index  = ((b - 1) * (NR + 1) * (N + 1)) + (R * (N + 1)) + t + 1;
                A_w_bRt_minus_column = w_bRt_index;
    
                Aeq(count_eq, A_w_bRt_minus_column(:)) = 1;
            end
            
            beq(count_eq, 1) = 1;
    
            count_eq = count_eq + 1;
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % At any time t+, a bus can only be assigned to one route
    % \sum_{R = 0}^{NR} w_{bRt^+} = 1 \forall b \forall t^+
    for b = 1 : NB
        for t = 0 : N
            for R = 0 : NR
                w_bRt_index  = ((b - 1) * (NR + 1) * (N + 1)) + (R * (N + 1)) + t + 1;
                A_w_bRt_plus_column = n_w_bRt_minus + w_bRt_index;
    
                Aeq(count_eq, A_w_bRt_plus_column(:)) = 1;
            end
            
            beq(count_eq, 1) = 1;
    
            count_eq = count_eq + 1;
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % A bus cannot change its assigned route between (t-1)+ and t-
    % w_{bRt-} - w_{bR(t-1)+} = 0 \forall b \forall l \forall t > 0
    for b = 1 : NB
        for t = 1 : N
            for R = 0 : NR
                w_bRt_index  = ((b - 1) * (NR + 1) * (N + 1)) + (R * (N + 1)) + t + 1;
                A_w_bRt_minus_column = w_bRt_index;
    
                w_bRtminus1_index  = ((b - 1) * (NR + 1) * (N + 1)) + (R * (N + 1)) + (t - 1) + 1;
                A_w_bRtminus1_plus_column = n_w_bRt_minus + w_bRtminus1_index;
    
                Aeq(count_eq, A_w_bRt_minus_column(:)) = 1;
                Aeq(count_eq, A_w_bRtminus1_plus_column(:)) = -1;
    
                beq(count_eq, 1) = 0;
    
                count_eq = count_eq + 1;
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 4 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % x_{blt-} - x_{blt+} = 0 \forall b \forall l \forall t^-
    for b = 1 : NB
        for l = 1 : NL
            for t = 0 : N
                x_blt_index = ((b - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
    
                A_x_blt_minus_column = n_w_bRt_minus  + n_w_bRt_plus + x_blt_index;
                A_x_blt_plus_column = n_w_bRt_minus  + n_w_bRt_plus + + n_x_blt_minus + x_blt_index;
    
                Aeq(count_eq, A_x_blt_minus_column(:)) = 1;
                Aeq(count_eq, A_x_blt_plus_column(:)) = -1;
    
                beq(count_eq, 1) = 0;
    
                count_eq = count_eq + 1;
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 5 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % At any time t- a bus can only be at one location
    % \sum_{l = 1}^{NL} x_{blt^-} = 1 \forall b \forall t^-
    for b = 1 : NB
        for t = 0 : N
            for l = 1 : NL
                x_blt_index = ((b - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
    
                A_x_blt_minus_column = n_w_bRt_minus  + n_w_bRt_plus + x_blt_index;
    
                Aeq(count_eq, A_x_blt_minus_column(:)) = 1;
            end
    
            beq(count_eq, 1) = 1;
    
            count_eq = count_eq + 1;
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 6 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % At any time t- a bus can only be at one location
    % \sum_{l = 1}^{NL} x_{blt^+} = 1 \forall b \forall t^+
    for b = 1 : NB
        for t = 0 : N
            for l = 1 : NL
                x_blt_index = ((b - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
    
                A_x_blt_plus_column = n_w_bRt_minus  + n_w_bRt_plus + n_x_blt_minus + x_blt_index;
    
                Aeq(count_eq, A_x_blt_plus_column(:)) = 1;
            end
    
            beq(count_eq, 1) = 1;
    
            count_eq = count_eq + 1;
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 7 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % At t^- a passenger is either at a bus stand or on a bus
    % \sum_{b=1}^{N_B} y_{ibt^-} + \sum_{s=1}^{N_S} z_{ist^-} = 1 \quad 
    % \forall i, \forall t
    for i = 1 : NP
        for t = 0 : N
            for b = 1 : NB
                y_ibt_index = ((i - 1) * NB * (N + 1)) + ((b - 1) * (N + 1)) + t + 1;
    
                A_y_ibt_minus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + y_ibt_index;
    
                Aeq(count_eq, A_y_ibt_minus_column(:)) = 1;
            end
            for l = 1: NL
                z_ist_index = ((i - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
                
                A_z_ist_minus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + z_ist_index;
          
                Aeq(count_eq, A_z_ist_minus_column(:)) = 1;
            end
    
            beq(count_eq, 1) = 1;
    
            count_eq = count_eq + 1;
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 8 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % At t^- a passenger is either on a bus stand or at a bus
    % \sum_{b=1}^{N_B} y_{ibt^+} + \sum_{s=1}^{N_S} z_{ist^+} = 1 \quad 
    % \forall i, \forall t
    for i = 1 : NP
        for t = 0 : N
            for b = 1 : NB
                y_ibt_index = ((i - 1) * NB * (N + 1)) + ((b - 1) * (N + 1)) + t + 1;
    
                A_y_ibt_plus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + y_ibt_index;
    
                Aeq(count_eq, A_y_ibt_plus_column(:)) = 1;
            end
            for l = 1: NL
                z_ist_index = ((i - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
                
                A_z_ist_plus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + n_z_ist_minus + z_ist_index;
          
                Aeq(count_eq, A_z_ist_plus_column(:)) = 1;
            end
    
            beq(count_eq, 1) = 1;
    
            count_eq = count_eq + 1;
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 9 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % A passenger stays at X_i \forall t \le I_i until it is time for them to
    % show up in the system
    % z_{iX_it-} = 1 \forall i \forall t \le I_i
    for i = 1 : NP
        l = X{i};
        for t = 0 : I{i}
            z_ist_index = ((i - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
                
            A_z_ist_minus_column = n_w_bRt_minus + n_w_bRt_plus  +...
                                   n_x_blt_minus + n_x_blt_plus +...
                                   n_y_ibt_minus + n_y_ibt_plus + z_ist_index;
          
            Aeq(count_eq, A_z_ist_minus_column(:)) = 1;
    
            beq(count_eq, 1) = 1;
            
            count_eq = count_eq + 1;
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 10 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % All buses start at location 1 at time 0
    % x_{b10-} = 1 \forall b
    for b = 1 : NB
        t = 0;
        l = 1;
       
        x_blt_index = ((b - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
    
        A_x_blt_minus_column = n_w_bRt_minus  + n_w_bRt_plus + x_blt_index;
    
        Aeq(count_eq, A_x_blt_minus_column(:)) = 1;
    
        beq(count_eq, 1) = 1;
            
        count_eq = count_eq + 1;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 11 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % All buses' final location at time N- is at location 1
    % x_{b1N-} = 1 \forall b
    for b = 1 : NB
        t = N;
        l = 1;
       
        x_blt_index = ((b - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
    
        A_x_blt_minus_column = n_w_bRt_minus  + n_w_bRt_plus + x_blt_index;
    
        Aeq(count_eq, A_x_blt_minus_column(:)) = 1;
    
        beq(count_eq, 1) = 1;
            
        count_eq = count_eq + 1;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 12 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % No bus is assigned a route at time 0-
    % w_{b00-} = 1 \forall b
    for b = 1 : NB
        t = 0;
        R = 0;
       
        w_bRt_index  = ((b - 1) * (NR + 1) * (N + 1)) + (R * (N + 1)) + t + 1;
        
        A_w_bRt_minus_column = w_bRt_index;
    
        Aeq(count_eq, A_w_bRt_minus_column(:)) = 1;
    
        beq(count_eq, 1) = 1;
            
        count_eq = count_eq + 1;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 13 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % No bus is assigned a route at time N+
    % w_{b0N+} = 1 \forall b
    for b = 1 : NB
        t = N;
        R = 0;
       
        w_bRt_index  = ((b - 1) * (NR + 1) * (N + 1)) + (R * (N + 1)) + t + 1;
        
        A_w_bRt_plus_column = n_w_bRt_minus + w_bRt_index;
    
        Aeq(count_eq, A_w_bRt_plus_column(:)) = 1;
    
        beq(count_eq, 1) = 1;
            
        count_eq = count_eq + 1;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 14 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % If a passenger is on a bus at (t-1)^+, they should should be on the 
    % same bus at t^-
    % y_{ibt^-} - y_{ib(t-1)^+} = 0 \quad \forall i, \forall b, \forall t.
    for i = 1 : NP
        for b = 1 : NB
            for t = 1 : N
                y_ibt_index = ((i - 1) * NB * (N + 1)) + ((b - 1) * (N + 1)) + t + 1;
                y_ibtminus1_index = ((i - 1) * NB * (N + 1)) + ((b - 1) * (N + 1)) + (t - 1) + 1;
    
                A_y_ibt_minus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + y_ibt_index;
                A_y_ibtminus1_plus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + y_ibtminus1_index;
    
                Aeq(count_eq, A_y_ibt_minus_column(:)) = 1;
                Aeq(count_eq, A_y_ibtminus1_plus_column(:)) = -1;
    
                beq(count_eq, 1) = 0;
    
                count_eq = count_eq + 1;
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 14 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % If a passenger is at a bus stand at (t-1)^+, they should should be at the 
    % same bus stand at t^-
    % z_{il_st^-} - z_{il_s(t-1)^+} = 0 \quad \forall i, \forall l_s, \forall t
    for i = 1 : NP
        for l = 1 : NL
            for t = 1 : N
                z_ist_index = ((i - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
                z_istminus1_index = ((i - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + (t - 1) + 1;
                
                A_z_ist_minus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + z_ist_index;
                A_z_istminus1_plus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + n_z_ist_minus + z_istminus1_index;
    
                Aeq(count_eq, A_z_ist_minus_column(:)) = 1;
                Aeq(count_eq, A_z_istminus1_plus_column(:)) = -1;
    
                beq(count_eq, 1) = 0;
    
                count_eq = count_eq + 1;
            end
        end
    end
    
    %%%% No Passenger Delivery at locations
    % Added this because it simplies preventing passengers from being
    % delivered to non-bus stand locations compared to coding the exact 
    % math formulation
    for i = 1 : NP
        for t = 0 : N
            for l = 1: NL
                if ismember(l, l_s)
                    continue
                end
                z_ist_index = ((i - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
                
                A_z_ist_minus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + z_ist_index;
                
                A_z_ist_plus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + n_z_ist_minus + z_ist_index;
          
                Aeq(count_eq, A_z_ist_plus_column(:))  = 1;
                Aeq(count_eq, A_z_ist_minus_column(:)) = 1;
            end
    
            beq(count_eq, 1) = 0;
    
            count_eq = count_eq + 1;
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% Fixed routes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Uncomment this section if the intention is to have fixed routes
    % for b = 1
    %     for t = 0 : N
    %         for R = 1 : NR
    %             if R == 1
    %                 continue
    %             end
    %             w_bRt_index  = ((b - 1) * (NR + 1) * (N + 1)) + (R * (N + 1)) + t + 1;
    %             A_w_bRt_minus_column = w_bRt_index;
    %             A_w_bRt_plus_column = n_w_bRt_minus + w_bRt_index;
    % 
    %             Aeq(count_eq, A_w_bRt_plus_column(:)) = 1;
    %             Aeq(count_eq, A_w_bRt_minus_column(:)) = 1;
    %         end
    %         beq(count_eq, 1) = 0;
    % 
    %         count_eq = count_eq + 1;
    %     end
    % end
    % 
    % for b = 2
    %     for t = 0 : N
    %         for R = 1 : NR
    %             if R == 2
    %                 continue
    %             end
    %             w_bRt_index  = ((b - 1) * (NR + 1) * (N + 1)) + (R * (N + 1)) + t + 1;
    %             A_w_bRt_minus_column = w_bRt_index;
    %             A_w_bRt_plus_column = n_w_bRt_minus + w_bRt_index;
    % 
    %             Aeq(count_eq, A_w_bRt_plus_column(:)) = 1;
    %             Aeq(count_eq, A_w_bRt_minus_column(:)) = 1;
    %         end
    %         beq(count_eq, 1) = 0;
    % 
    %         count_eq = count_eq + 1;
    %     end
    % end

end