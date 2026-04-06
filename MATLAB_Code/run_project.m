close all; clc; clear;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% Run this to generate results   %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic;            % Start timer to track how long it takes to run code
% Constants
NB     = 2;     % Number of buses
NR     = 3;     % Number of routes
NP     = 15;    % Number of passengers
NL     = 12;     % Number of bus_stands / locations
N      = 20;    % Number of time_steps, goes from 0 - 24
k_1    = 1;
k_2    = 2;

l_s = [1 2 3 4 5]; % bus stands

% %%%%%%%%%%%%%% Manual Passenger Data Generation %%%%%%%%%%%%
% X1 = 2;   Y1 = 3;   I1 = 0;   J1 = 10;
% X2 = 2;   Y2 = 3;   I2 = 0;   J2 = 5;
% X3 = 5;   Y3 = 3;   I3 = 0;   J3 = 10;
% X4 = 5;   Y4 = 3;   I4 = 0;   J4 = 10;
% X5 = 2;   Y5 = 3;   I5 = 0;   J5 = 5;
% X6 = 2;   Y6 = 5;   I6 = 0;   J6 = 2;
% X7 = 1;   Y7 = 2;   I7 = 0;   J7 = 10;
% X8 = 1;   Y8 = 2;   I8 = 0;   J8 = 10;
% X9 = 1;   Y9 = 3;   I9 = 0;   J9 = 10;
% X10 = 3;  Y10 = 1;  I10 = 0;  J10 = 5;
% X11 = 3;  Y11 = 5;  I11 = 7;  J11 = 15;
% X12 = 3;  Y12 = 5;  I12 = 7;  J12 = 15;
% X13 = 4;  Y13 = 2;  I13 = 8;  J13 = 20;
% X14 = 4;  Y14 = 2;  I14 = 8;  J14 = 22;
% X15 = 4;  Y15 = 2;  I15 = 8;  J15 = 22;
% X16 = 3;  Y16 = 4;  I16 = 10; J16 = 22;
% X17 = 5;  Y17 = 3;  I17 = 10; J17 = 22;
% X18 = 5;  Y18 = 3;  I18 = 10; J18 = 22;
% X19 = 5;  Y19 = 3;  I19 = 10; J19 = 22;
% X20 = 5;  Y20 = 3;  I20 = 11; J20 = 22;
% 
% X = {X1};%, X2};%, X3, X4, X5, X6, X7, X8, X9, X10};%, X11, X12, X13, X14, X15, X16, X17, X18, X19, X20};
% Y = {Y1};%, Y2};%, Y3, Y4, Y5, Y6, Y7, Y8, Y9, Y10};%, Y11, Y12, Y13, Y14, Y15, Y16, Y17, Y18, Y19, Y20};
% I = {I1};%, I2};%, I3, I4, I5, I6, I7, I8, I9, I10};% I11, I12, I13, I14, I15, I16, I17, I18, I19, I20};
% J = {J1};%, J2};%, J3, J4, J5, J6, J7, J8, J9, J10};%, J11, J12, J13, J14, J15, J16, J17, J18, J19, J20};

% %%%%%%%%%%%%%% Passenger Data Generation Function %%%%%%%%%%%%
mode.demandLevel = 'high';
mode.deadlineLevel = 'loose';
[X, Y, I, J, Tmin] = generate_passengers_structured(NP, N, l_s, mode, 3);

% Convert to row cell arrays
X = num2cell(X');
Y = num2cell(Y');
I = num2cell(I');
J = num2cell(J');

save('X11.mat', 'X')
save('Y11.mat', 'Y')
save('I11.mat', 'I')
save('J11.mat', 'J')


% Bus Capacity
C1 = 4;  c1 = 1;
C2 = 2;  c2 = 0.5;

% Number of Elements
n_w_bRt_minus = NB * (NR + 1) * (N + 1);
n_w_bRt_plus = NB * (NR + 1) * (N + 1);
n_x_blt_minus = NB * NL * (N + 1);
n_x_blt_plus = NB * NL * (N + 1);

n_y_ibt_minus = NP * NB * (N + 1);
n_y_ibt_plus = NP * NB * (N + 1);

n_z_ist_minus = NP * NL * (N + 1);
n_z_ist_plus = NP * NL * (N + 1);

n_Beta_i = NP;

C = {C1, C2};
c = {c1, c2};

%%%%%%%%%%%%% Check if Passenger Departure Stands are Valid %%%%%%%%%%%%%%%
for i = 1:length(X)
    
    invalidVals = X{i}(~ismember(X{i}, l_s));
    
    if ~isempty(invalidVals)
        error('X{%d} contains invalid value(s): %s', ...
              i, mat2str(unique(invalidVals)));
    end
    
end

%%%%%%%%%%%%% Check if Passenger Destinations are Valid %%%%%%%%%%%%%%%
for i = 1:length(Y)
    
    invalidVals = Y{i}(~ismember(Y{i}, l_s));
    
    if ~isempty(invalidVals)
        error('Y{%d} contains invalid value(s): %s', ...
              i, mat2str(unique(invalidVals)));
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%% Define Routes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
R_{1} = [1 6 2 7 8 3 9 1];
R_{2} = [1 10 4 5 11 1];
R_{3} = [1 11 5 12 2 6 1];

% Number of columns in A
A_columns = n_w_bRt_minus + n_w_bRt_plus + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + n_z_ist_minus + n_z_ist_plus;
Beta_columns = n_w_bRt_minus + n_w_bRt_plus + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + n_z_ist_minus + n_z_ist_plus;
z_idx     = n_w_bRt_minus + n_w_bRt_plus + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus + n_z_ist_minus;

[Ain, bin]  = inequality_constraints(X, Y, I, J, C, R_, NB, NR, NP, NL, l_s, N, k_1, k_2);
[Aeq, beq]  = equality_constraints(X, I, NB, NR, NP, NL, l_s, N);
Cob         = objective_function(NB, NR, NP, N, c, A_columns, Beta_columns);

%%%%%%%%%%%%%%%%%%%%%%% INTEGER LINEAR PROGRAM %%%%%%%%%%%%%%%%%%%%%%%

w1 = 0.2;  % Weight for row 1
w2 = 0.8;  % Weight for row 2

Cob_combined = w1 * Cob(1, :) + w2 * Cob(2, :);

decision_variables = size(Cob_combined, 2);         
number_of_integer_variables = 1: decision_variables;

lb = zeros(decision_variables, 1);                 % lower bounds
lb((decision_variables + 1) - NP: end) = -Inf; 

ub = ones(decision_variables, 1);                  % upper bounds
ub((decision_variables + 1) - NP: end) = Inf;      % Beta_i is not a binary value

options = optimoptions('intlinprog', 'Display', 'iter', 'MaxTime', 36000);

elapsed_time  = toc;
fprintf('Elapsed time: %.4f seconds\n', elapsed_time);
[x_opt, fval] = intlinprog(Cob_combined, number_of_integer_variables, Ain, bin, Aeq, beq, lb, ub, options);

elapsed_time  = toc;
fprintf('Elapsed time: %.4f seconds\n', elapsed_time);

clear functions;
%% Run map plotting function to generate animation
map_plotting(NB, NR, NP, NL, N, C, I, Y, l_s, R_, x_opt);


