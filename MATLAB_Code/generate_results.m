function [labels, result] = generate_results(x_opt, starting_index, n_variable_minus, n_variable_plus, element_number, total_number, N, variable_plotted)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% This function extracts decision variable assignments %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Inputs:
% x_opt             - result from optimization algorithm
% starting_index    - 0 if generating w_bRt, n_w_bRt_minus + n_w_bRt_plus if
%                     generating x_blt, n_w_bRt_minus + n_w_bRt_plus + ...
%                     n_x_blt_minus + n_x_blt_plus if generating y_ibt and 
%                     n_w_bRt_minus + n_w_bRt_plus + n_x_blt_minus + ...
%                     n_x_blt_plus + n_y_blt_minus + n_y_blt_plus if
%                     generating z_ist
% n_variable_minus  - e.g n_wbRt_minus
% n_variable_plus   - e.g n_wbRt_plus
% element_number    - e.g for bus number 1 input 1
% total_number      - NB if generating for a bus or NP if it's a passenger
% N                 - final time step
% variable_plotted  - e.g "w_bRt", "x_blt", "z_ist", "y_ibt"

    % Sum of the indices
    sum_indices = n_variable_minus + n_variable_plus;
    
    % Extract them from x_opt
    variable = x_opt(starting_index + 1: starting_index + sum_indices);
    
    % Find the initial index for time_minus
    variable_minus_initial_index = int32(((element_number - 1) / total_number) * n_variable_minus);
    
    % Find the final index for time_minus
    variable_minus_final_index = int32((element_number / total_number) * n_variable_minus);
    
    variable_minus_indices = variable(1 + variable_minus_initial_index : variable_minus_final_index);
    
    % Find the initial index for time_plus
    variable_plus_initial_index = int32(n_variable_minus + ((element_number - 1) / total_number) * n_variable_plus);
    
    % Find the final index for time_plus
    variable_plus_final_index = int32(variable_plus_initial_index + ((1 / total_number) * n_variable_plus));
    
    variable_plus_indices = variable(variable_plus_initial_index + 1 : variable_plus_final_index);
    
    % Rearrange to match time format
    rearranged = zeros(length(variable_minus_indices) + length(variable_plus_indices), 1);
    rearranged(1:2:end) = variable_minus_indices;
    rearranged(2:2:end) = variable_plus_indices;
    
    % Find indices with true values
    [row_idx, ~] = find(abs(rearranged - 1) < 1e-6);
    
    times = [];
    parameter = [];
    
    % Total number of time_indices including minus and plus
    time_indices = 2 * (N + 1);
    
    full_parameter = NaN(1, time_indices);
    
    for idx = row_idx'
        r = floor((idx - 1) / time_indices);
        t = mod(idx - 1, time_indices) + 1;
    
        times(end + 1) = t;
    
        if variable_plotted == "w_bRt"
            parameter(end + 1) = r;
        else
            parameter(end + 1) = r + 1;
        end
    
        full_parameter(t) = parameter(end);
    end
    
    labels = reshape([strcat(string(0 : N), "^{-}"); strcat(string(0 : N), "^{+}")], 1, []);
    times   = sort(times);
    result  = full_parameter;

end
