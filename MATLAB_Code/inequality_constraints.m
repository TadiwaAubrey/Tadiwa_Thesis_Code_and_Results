function [Ain, bin] = inequality_constraints(X, Y, I, J, C, R_, NB, NR, NP, NL, l_s, N, k_1, k_2)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% This function randomly generates inequality constraints %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Inputs:
    %   X     = origin bus stand vector
    %   Y     = destination bus stand vector
    %   I     = passenger arrival time at origin vector
    %   J     = passenger desired arrival time  at destination vector
    %   NB    = number of buses
    %   NR    = number of routes
    %   NP    = number of passengers
    %   NL    = number of locations
    %   l_s   = locations that are bus stands
    %   N     = final time step
    %   k_1   = early arrival reward
    %   k_2   = late arrival penalty
    %
    % Outputs:
    %   
    %   A_in  = inequality constraint matrix
    %   b_in  = RHS inequality constraint vector


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
    
    count = 1;  % Initialize number of rows
    
    %%%%%%%%%%%%%%%%%%%%%%%%%% Number of Ain rows %%%%%%%%%%%%%%%%%%%%%%%%%
    total_route_links = sum(cellfun(@(r) length(r) - 1, R_));
    num_genR          = 2 * NB * N * total_route_links;
    num_c_17          = NB * N;
    num_c_18          = NB * N;
    num_c_19          = NB * (N + 1);
    num_c_20          = NB * (N + 1);
    num_c_21          = NB * NR * (N + 1);
    num_c_22          = NB * NR * (N + 1);
    num_c_23          = NB * NR * (N + 1);
    num_c_24          = NB * NP * (N + 1);
    num_c_25          = NB * NP * (N + 1);
    num_c_26          = NB * NP * (N + 1);
    num_c_27          = NB * NP * (N + 1);
    num_c_28          = NB * NP * NL * (N + 1);
    num_c_29          = NP * NL * (N + 1);
    num_c_30          = NP * (N + 1);
    num_c_31          = sum(cellfun(@(n) n, I));
    
    num_constraints = sum([ ...
        num_genR, num_c_17, num_c_18, num_c_19, num_c_20, num_c_21,...
        num_c_22, num_c_23, num_c_24, num_c_25, num_c_26, num_c_27,...
        num_c_28, num_c_29, num_c_30, num_c_31, 2 * NP
    ]);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Preallocate Ain %%%%%%%%%%%%%%%%%%%%%%%%%%
    Ain = zeros(num_constraints, A_columns);
    bin = zeros(num_constraints, 1);
    
    %%%%%%%%%%%%%%%%%%%%%% Generalized Route Constraints %%%%%%%%%%%%%%%%%
    % x_{b,R_r(k),t^-} - x_{b,R_r(k-1),(t-1)^+} + w_{br(t-1)^+} \le 1 ...
    % \quad \forall t, \forall b, \forall r, \forall k \ge 1
    % -x_{b,R_r(k),t^-} + x_{b,R_r(k-1),(t-1)^+} + w_{br(t-1)^+} \le 1...
    % \quad \forall t, \forall b, \forall r, \forall k \ge 1

    for r = 1 : NR
        for t = 0 : N - 1
            for b = 1 : NB
                for l = 2 : length(R_{r})
                    x_bltplus1_index = ((b - 1) * NL * (N + 1)) + ((R_{r}(l) - 1) * (N + 1)) + (t + 1) + 1;
                    x_bl_pt_index = ((b - 1) * NL * (N + 1)) + ((R_{r}(l - 1) - 1) * (N + 1)) + t + 1;
                    w_bRt_index  = ((b - 1) * (NR + 1) * (N + 1)) + (r * (N + 1)) + t + 1;
                    
                    A_x_bltplus1_minus_column = n_w_bRt_minus  + n_w_bRt_plus + x_bltplus1_index;
                    A_x_bl_pt_plus_column = n_w_bRt_minus  + n_w_bRt_plus + n_x_blt_minus + x_bl_pt_index;
                    A_w_bRt_plus_column = n_w_bRt_minus + w_bRt_index;
            
                    Ain(count, A_x_bltplus1_minus_column(:)) = 1;
                    Ain(count, A_x_bl_pt_plus_column(:)) = -1;
                    Ain(count, A_w_bRt_plus_column(:)) = 1;
            
                    bin(count, 1) = 1;
                    
                    count = count + 1;
                    
                    A_x_bltplus1_minus_column = n_w_bRt_minus  + n_w_bRt_plus + x_bltplus1_index;
                    A_x_bl_pt_plus_column = n_w_bRt_minus  + n_w_bRt_plus + n_x_blt_minus + x_bl_pt_index;
                    A_w_bRt_plus_column = n_w_bRt_minus + w_bRt_index;
            
                    Ain(count, A_x_bltplus1_minus_column(:)) = -1;
                    Ain(count, A_x_bl_pt_plus_column(:)) = 1;
                    Ain(count, A_w_bRt_plus_column(:)) = 1;
                    
                    bin(count, 1) = 1;
        
                    count = count + 1;
                end
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%% Constraint 17 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Force bus to remain at central bus stand if assigned to idle state
    % x_b1(t+1)^- - x_b1t^+ - (1 - w_b0t^+) \le 0
    [b_grid, t_grid] = ndgrid(1 : NB, 0 : N - 1);
    
    % Compute all indices at once
    x_b1tplus1_index = ((b_grid - 1) * NL * (N + 1)) + ((1 - 1) * (N + 1)) + (t_grid + 1) + 1;
    x_b1t_index      = ((b_grid - 1) * NL * (N + 1)) + ((1 - 1) * (N + 1)) + t_grid + 1;
    w_b0t_index      = ((b_grid - 1) * (NR + 1) * (N + 1)) + (0 * (N + 1)) + t_grid + 1;
    
    % Compute all Ain columns
    A_x_b1tplus1_minus_column17 = n_w_bRt_minus  + n_w_bRt_plus + x_b1tplus1_index;
    A_x_b1t_plus_column17       = n_w_bRt_minus  + n_w_bRt_plus + n_x_blt_minus + x_b1t_index;
    A_w_b0t_plus_column17       = n_w_bRt_minus  + w_b0t_index;
    
    % Compute the Ain_row_indices
    row_idx17 = (count : (count + num_c_17 - 1));
    row_idx17 = row_idx17(:);
    
    % Fill Ain (use linear indexing)
    Ain(sub2ind(size(Ain), row_idx17, A_x_b1tplus1_minus_column17(:))) = 1;
    Ain(sub2ind(size(Ain), row_idx17, A_x_b1t_plus_column17(:)))       = -1;
    Ain(sub2ind(size(Ain), row_idx17, A_w_b0t_plus_column17(:)))       = 1;
    
    % Fill bin
    bin(row_idx17, 1) = 1;
    
    % Update counter
    count = count + num_c_17;
    
    %%%%%%%%%%%%%%%%%%%%%%%%% Constraint 18 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Force bus to remain at central bus stand if assigned to idle state
    % x_b1(t+1)^- + x_b1t^+ - (1 - w_b0t^+) \le 0
    row_idx18 = (count : (count + num_c_18 - 1));
    row_idx18 = row_idx18(:);
    
    % Fill Ain (use linear indexing)
    Ain(sub2ind(size(Ain), row_idx18, A_x_b1tplus1_minus_column17(:))) = -1;
    Ain(sub2ind(size(Ain), row_idx18, A_x_b1t_plus_column17(:)))       = 1;
    Ain(sub2ind(size(Ain), row_idx18, A_w_b0t_plus_column17(:)))       = 1;
    
    % Fill bin
    bin(row_idx18, 1) = 1;
    
    % Update counter
    count = count + num_c_18;
    
    %%%%%%%%%%%%%%%%%%%%%%%%% Constraint 19 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Bus capacity constraint at t^-
    % \sum_{i = 1}^{N_P} y_{ibt^-} \le C_b, \quad\forall b, \forall t,
    for b = 1 : NB
        for t = 0 : N
            for i = 1 : NP
                y_ibt_index = ((i - 1) * NB * (N + 1)) + ((b - 1) * (N + 1)) + t + 1;
    
                A_y_ibt_minus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + y_ibt_index;
    
                Ain(count, A_y_ibt_minus_column(:)) = 1;
    
            end
            bin(count, 1) = C{b};
            count = count + 1;
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 20 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Bus capacity constraint at t^+
    % \sum_{i = 1}^{N_P} y_{ibt^+} \le C_b, \quad \forall b, \forall t
    for b = 1 : NB
        for t = 0 : N
            for i = 1 : NP
                y_ibt_index = ((i - 1) * NB * (N + 1)) + ((b - 1) * (N + 1)) + t + 1;
    
                A_y_ibt_plus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + y_ibt_index;
    
                Ain(count, A_y_ibt_plus_column(:)) = 1;
    
            end
            bin(count, 1) = C{b};
            count = count + 1;
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 21 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Bus route assignments can only change at the central depot
    % w_{brt^+} \le w_{brt^-} + x_{b1t^-} \quad \forall b, \forall r \ne 0, \forall t
    % Generate all combinations of b, R, t
    [b_grid21, R_grid21, t_grid21] = ndgrid(1 : NB, 1 : NR, 0 : N);  % R starts at 1
    
    % Compute indices
    w_bRt_index = ((b_grid21 - 1) * (NR + 1) * (N + 1)) + (R_grid21 * (N + 1)) + t_grid21 + 1;
    x_b1t_index = ((b_grid21 - 1) * NL * (N + 1)) + (0 * (N + 1)) + t_grid21 + 1;
    
    % Compute Ain columns
    A_w_bRt_minus_column = w_bRt_index;
    A_w_bRt_plus_column  = n_w_bRt_minus + w_bRt_index;
    A_x_b1t_minus_column = n_w_bRt_minus + n_w_bRt_plus + x_b1t_index;
    
    % Rows in Ain for this block
    row_idx21 = count : (count + num_c_21 - 1);
    row_idx21 = row_idx21(:);
    
    % Fill Ain using linear indexing
    Ain(sub2ind(size(Ain), row_idx21, A_w_bRt_plus_column(:)))  = 1;
    Ain(sub2ind(size(Ain), row_idx21, A_w_bRt_minus_column(:))) = -1;
    Ain(sub2ind(size(Ain), row_idx21, A_x_b1t_minus_column(:))) = -1;
    
    % Fill bin (all zeros)
    bin(row_idx21, 1) = 0;
    
    % Update counter
    count = count + num_c_21;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 22 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Bus required to transition to idle state after completing a route
    % w_{brt^+} \le 1 + w_{b0t^-} - x_{b1t^-} \quad \forall b, \forall r \ne 0, \forall t
    w_b0t_index = ((b_grid21 - 1) * (NR + 1) * (N + 1)) + (0 * (N + 1)) + t_grid21 + 1;
    A_w_b0t_minus_column = w_b0t_index;
    
    % Rows in Ain for this block
    row_idx22 = count : (count + num_c_22 - 1);
    row_idx22 = row_idx22(:);
    
    % Fill Ain using linear indexing
    Ain(sub2ind(size(Ain), row_idx22, A_w_bRt_plus_column(:)))  = 1;
    Ain(sub2ind(size(Ain), row_idx22, A_w_b0t_minus_column(:))) = -1;
    Ain(sub2ind(size(Ain), row_idx22, A_x_b1t_minus_column(:))) = 1;
    
    % Fill bin (all zeros)
    bin(row_idx22, 1) = 1;
    
    % Update counter
    count = count + num_c_22;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 23 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Bus route assignments can only change at the central depot
    % w_{brt^+} \ge w_{brt^-} - x_{b1t^-} \quad \forall b, \forall r \ne 0, \forall t
    % Rows in Ain for this block
    row_idx23 = count : (count + num_c_23 - 1);
    row_idx23 = row_idx23(:);
    
    % Fill Ain using linear indexing
    Ain(sub2ind(size(Ain), row_idx23, A_w_bRt_plus_column(:)))  = -1;
    Ain(sub2ind(size(Ain), row_idx23, A_w_bRt_minus_column(:))) = 1;
    Ain(sub2ind(size(Ain), row_idx23, A_x_b1t_minus_column(:))) = -1;
    
    % Fill bin (all zeros)
    bin(row_idx23, 1) = 0;
    
    % Update counter
    count = count + num_c_23;
    
    % %%%%%%%%%%%%%%%%%%%%%%%%% Constraint 24 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Passenger can only board a bus if they and the bus are at the same 
    % bus stand.
    % y_{ibt^+} \le y_{ibt^-} + 1 + \sum_{s=1}^{N_S}...
    % \frac{s}{N_S} x_{bl_st^-} - \sum_{s=1}^{N_S} ...
    % \frac{s}{N_S} z_{il_st^-} \quad \forall b, \forall i, \forall t
    for i = 1 : NP
        for b = 1 : NB
            for t = 0 : N
                for l = 1 : NL
                   x_blt_index = ((b - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
                   A_x_blt_minus_column = n_w_bRt_minus  + n_w_bRt_plus + x_blt_index;
    
                   z_ist_index = ((i - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
                   A_z_ist_minus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + z_ist_index;
    
                   Ain(count, A_x_blt_minus_column(:)) = l;
                   Ain(count, A_z_ist_minus_column(:)) = -l;
                end
    
                y_ibt_index = ((i - 1) * NB * (N + 1)) + ((b - 1) * (N + 1)) + t + 1;
    
                A_y_ibt_plus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + y_ibt_index;
                A_y_ibt_minus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + y_ibt_index;
    
                Ain(count, A_y_ibt_plus_column(:)) = NL;
                Ain(count, A_y_ibt_minus_column(:)) = -NL;
    
                bin(count, 1) = NL;
    
                count = count + 1;
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 25 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Passenger can only board a bus if they and the bus are at the same 
    % bus stand.
    % y_{ibt^+} \le y_{ibt^-} + 1 - \sum_{s=1}^{N_S}...
    % \frac{s}{N_S} x_{bl_st^-} + \sum_{s=1}^{N_S}...
    % \frac{s}{N_S} z_{il_st^-} \quad \forall b, \forall i, \forall t
    for i = 1 : NP
        for b = 1 : NB
            for t = 0 : N
                for l = 1 : NL
                   x_blt_index = ((b - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
                   A_x_blt_minus_column = n_w_bRt_minus  + n_w_bRt_plus + x_blt_index;
    
                   z_ist_index = ((i - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
                   A_z_ist_minus_column = n_w_bRt_minus + n_w_bRt_plus...
                                          + n_x_blt_minus + n_x_blt_plus...
                                          + n_y_ibt_minus + n_y_ibt_plus...
                                          + z_ist_index;
    
                   Ain(count, A_x_blt_minus_column(:)) = -l;
                   Ain(count, A_z_ist_minus_column(:)) = l;
                end
    
                y_ibt_index = ((i - 1) * NB * (N + 1)) + ((b - 1) * (N + 1)) + t + 1;
    
                A_y_ibt_plus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + y_ibt_index;
                A_y_ibt_minus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + y_ibt_index;
    
                Ain(count, A_y_ibt_plus_column(:)) = NL;
                Ain(count, A_y_ibt_minus_column(:)) = -NL;
    
                bin(count, 1) = NL;
    
                count = count + 1;
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 26 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Passenger can only disembark a bus if the bus is lcoated at a bus
    % stand
    % y_{ibt^+} \le y_{ibt^-} + \sum_{s=1}^{N_s} x_{bl_st^-} \quad...
    % \forall b, \forall i, \forall t
    for i = 1 : NP
        for b = 1 : NB
            for t = 0 : N
                for l = 1 : NL
                   x_blt_index = ((b - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
                   A_x_blt_minus_column = n_w_bRt_minus  + n_w_bRt_plus + x_blt_index;
    
                   Ain(count, A_x_blt_minus_column(:)) = -1;
                end
    
                y_ibt_index = ((i - 1) * NB * (N + 1)) + ((b - 1) * (N + 1)) + t + 1;
    
                A_y_ibt_plus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + y_ibt_index;
                A_y_ibt_minus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + y_ibt_index;
    
                Ain(count, A_y_ibt_plus_column(:)) = 1;
                Ain(count, A_y_ibt_minus_column(:)) = -1;
    
                bin(count, 1) = 0;
    
                count = count + 1;
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 27 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Passenger can only disembark a bus if the bus is lcoated at a bus
    % stand
    % y_{ibt^+} \ge y_{ibt^-} - \sum_{s=1}^{N_s} x_{bl_st^-} \le 0 \quad...
    % \forall b, \forall i, \forall t
    for i = 1 : NP
        for b = 1 : NB
            for t = 0 : N
                for l = 1 : NL
                   x_blt_index = ((b - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
                   A_x_blt_minus_column = n_w_bRt_minus  + n_w_bRt_plus + x_blt_index;
    
                   Ain(count, A_x_blt_minus_column(:)) = -1;
                end
    
                y_ibt_index = ((i - 1) * NB * (N + 1)) + ((b - 1) * (N + 1)) + t + 1;
    
                A_y_ibt_plus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + y_ibt_index;
                A_y_ibt_minus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + y_ibt_index;
    
                Ain(count, A_y_ibt_plus_column(:)) = -1;
                Ain(count, A_y_ibt_minus_column(:)) = 1;
    
                bin(count, 1) = 0;
    
                count = count + 1;
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 28 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Enforces the conditions that allow a passenger to be assigned to bus
    % stand s
    % z_{ist^+} \le \frac{1}{2} x_{bl_st^-} + \frac{1}{2} y_{ibt^-} + ...
    % \sum_{\substack{b'=1 \\ b' \ne b}}^{N_B} y_{ib't^-} + z_{ist^-}...
    % \quad \forall b, \forall s, \forall i, \forall t
    for i = 1 : NP
        for l = 1 : NL
            for b = 1 : NB
                for t = 0 : N
                    x_blt_index = ((b - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
                    A_x_blt_minus_column = n_w_bRt_minus  + n_w_bRt_plus + x_blt_index;
    
                    z_ist_index = ((i - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
                    A_z_ist_minus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + z_ist_index;
                    A_z_ist_plus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + n_z_ist_minus + z_ist_index;
    
                    y_ibt_index = ((i - 1) * NB * (N + 1)) + ((b - 1) * (N + 1)) + t + 1;
                    A_y_ibt_minus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + y_ibt_index;
    
                    b_p = setdiff(1 : NB, b);
                    for d = b_p
                        y_idt_index = ((i - 1) * NB * (N + 1)) + ((d - 1) * (N + 1)) + t + 1;
                        A_y_idt_minus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + y_idt_index;
    
                        Ain(count, A_y_idt_minus_column(:)) = -2;
                    end
    
                    Ain(count, A_y_ibt_minus_column(:)) = -1;
                    Ain(count, A_x_blt_minus_column(:)) = -1;
                    Ain(count, A_z_ist_minus_column(:)) = -2;
                    Ain(count, A_z_ist_plus_column(:)) = 2;
    
                    bin(count, 1) = 0;
    
                    count = count + 1;
                end
            end
        end
    end
                
    %%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 29 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % A passenger must remain at a bus stand if no bus is present there
    % z_{ist^+} \ge -\sum_{b = 1}^{N_B} x_{bl_st^-} + z_{ist^-}  \quad...
    % \forall s, \forall i, \forall t.
    for i = 1 : NP
        for l = 1 : NL
            for t = 0 : N
                for b = 1 : NB
                   x_blt_index = ((b - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
                   A_x_blt_minus_column = n_w_bRt_minus  + n_w_bRt_plus + x_blt_index;
    
                   Ain(count, A_x_blt_minus_column(:)) = -1;
                end
    
                z_ist_index = ((i - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
                A_z_ist_minus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + z_ist_index;
                A_z_ist_plus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + n_z_ist_minus + z_ist_index;
    
                Ain(count, A_z_ist_minus_column(:)) = 1;
                Ain(count, A_z_ist_plus_column(:)) = -1;
    
                bin(count, 1) = 0;
    
                count = count + 1;
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 30 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Once a passenger arrives at their final bus stand, they cannot leave
    % z_{iY_it^-} - z_{iY_it^+} \le 0 \quad \forall i, \forall t.
    for i = 1 : NP
        l = Y{i};
        for t = 0 : N
           z_ist_index = ((i - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
           A_z_ist_minus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + z_ist_index;
           A_z_ist_plus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + n_z_ist_minus + z_ist_index;
    
           Ain(count, A_z_ist_minus_column(:)) = 1;
           Ain(count, A_z_ist_plus_column(:)) = -1;
    
           bin(count, 1) = 0;
            
           count = count + 1;
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%% Constraint 31 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Passenger stays at origin bus stand until it is time to appear in the
    % system
    % z_{iX_it^+} - z_{iX_it^-} = 0 \quad \forall i, \forall t...
    % \in\left\{0, 1, \dots, I_i - 1\right\}
    for i = 1 : NP
        l = X{i};
        N_limit = I{i} - 1;
        for t = 0 : N_limit
           z_ist_index = ((i - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
           A_z_ist_minus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + z_ist_index;
           A_z_ist_plus_column = n_w_bRt_minus + n_w_bRt_plus  + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + n_z_ist_minus + z_ist_index;
    
           Ain(count, A_z_ist_minus_column(:)) = -1;
           Ain(count, A_z_ist_plus_column(:)) = 1;
    
           bin(count, 1) = 0;
            
           count = count + 1;
        end
    end
    
    %%%%%%%%%%%%%%% Objective Function Constraint 1 %%%%%%%%%%%%%%%%%%%%%%
    % Early passenger passenger travel time cost
    % - k_1\sum_{t = 0}^{N} z_{iY_it^+} - \beta_i \le - k_1(N+1 - J_i),  \quad \forall i
    z_idx       = n_w_bRt_minus + n_w_bRt_plus + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + n_z_ist_minus;
    Beta_columns = n_w_bRt_minus + n_w_bRt_plus + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + n_z_ist_minus + n_z_ist_plus;
    
    for i = 1 : NP
        for t = 0 : N
            l = Y{i};
            j = J{i};
            z_ist_index = ((i - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
    
            A_z_ist_plus_column = z_idx + z_ist_index;
            
            Ain(count, A_z_ist_plus_column(:)) = -k_1;     
        end
    
        A_Beta_column                      = Beta_columns + i;
        Ain(count, A_Beta_column(:))       = - 1;
    
        bin(count, 1) = -k_1 * (N + 1 - j);
    
        count = count + 1;
    end

    %%%%%%%%%%%%%%% Objective Function Constraint 2 %%%%%%%%%%%%%%%%%%%%%%
    % Late passenger travel time cost
    % - k_2\sum_{t = 0}^{N} z_{iY_it^+} - \beta_i\le - k_2(N+1 - J_i) ,  \quad \forall i
    for i = 1 : NP
        for t = 0 : N
            l = Y{i};
            j = J{i};
            z_ist_index = ((i - 1) * NL * (N + 1)) + ((l - 1) * (N + 1)) + t + 1;
    
            A_z_ist_plus_column = z_idx + z_ist_index;
            
            Ain(count, A_z_ist_plus_column(:)) = - k_2;
            
        end
        A_Beta_column                      = Beta_columns + i;
        Ain(count, A_Beta_column(:))       = - 1;
    
        bin(count, 1) = -k_2 * (N + 1 - j);
    
        count = count + 1;
    end

end