function map_plotting(NB, NR, NP, NL, N, C, I, Y_i, l_s, R_, x_opt)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% This function plots the animation %%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Inputs:
%   NB    = number of buses
%   NR    = number of routes
%   NP    = number of passengers
%   NL    = number of locations
%   N     = final time step
%   C     = bus capacity vector
%   I     = passenger arrival at origin bus stand vector
%   Y_i   = passenger final destination
%   l_s   = locations that are bus stands
%   R_    = bus routes
%   x_opt = result from optimization algorithm
%
% Output
% figs that allow you to step through time steps using left and right arrow
% keys

n_w_bRt_minus = NB * (NR + 1) * (N + 1);
n_w_bRt_plus  = NB * (NR + 1) * (N + 1);

n_x_blt_minus = NB * NL * (N + 1);
n_x_blt_plus  = NB * NL * (N + 1);

n_y_ibt_minus = NP * NB * (N + 1);
n_y_ibt_plus  = NP * NB * (N + 1);

n_z_ist_minus = NP * NL * (N + 1);
n_z_ist_plus  = NP * NL * (N + 1);

clear keyHandler; close all; clf;  % Force persistent variables to reset

% Label bus locations as Li and bus stands as Si
nodes = "L" + string(1:NL);       % Define all nodes as Li
nodes(l_s) = "S" + string(l_s);   % Replace bus stands nodes with Si

% Generate edge colors for each route.
routeColors = [
    0.8 0   0               % dark red
    0.9   0.75   0.1        % golden yellow
    0   0.6 0               % dark green
];

from    = [];           % Initialize from nodes
to      = [];           % Initialize to nodes
weights = [];           % Initialize edge weights

for r = 1 : NR
    route   = R_{r};
    nE = length(route) - 1;

    from    = [from, route(1:end-1)];
    to      = [to, route(2:end)];
    weights = [weights, ones(1,length(route)-1)];
end

G = digraph(from, to, weights, nodes);                    % Create graph

%%%%%%%%%%% Automatic Node Placement %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

h1 = plot(G, 'Layout','force', 'NodeColor',[1, 1, 1], 'MarkerSize',25, 'EdgeColor','none', 'NodeLabel', {}); % Plot nodes only

layout(h1, 'force', 'Iterations', 500, 'UseGravity', 'on');

X = h1.XData;  % Save auto-placed node coordinates
Y = h1.YData;  % Save auto-placed node coordinates

xmin = min([X(:); -5]) - 1;
xmax = max([X(:); 6.5]) + 1;
ymin = min([Y(:); -4]) - 1;
ymax = max([Y(:); 4]) + 1;

axis([xmin xmax ymin ymax]);
axis manual

% Default all edges to gray first
edgecolors = repmat([0.7 0.7 0.7], numedges(G), 1);

% Now assign route colors using actual edge indices in G
for r = 1:NR
    route = R_{r};
    fr = route(1:end-1);
    tr = route(2:end);

    idx = findedge(G, fr, tr);   % indices into G.Edges
    edgecolors(idx, :) = repmat(routeColors(r,:), length(idx), 1);
end

h2 = plot(G, 'XData',X, 'YData',Y,'EdgeColor', edgecolors,'LineWidth', 2, 'NodeLabel', {});

nodeColors          = repmat([0 0 1], NL, 1);           % Initialize all nodes as blue 
nodeColors(l_s, :)  = repmat([0 0 0], length(l_s), 1);  % Overwrite colors for (l_s) as black 

h2.ArrowSize = 16;          % Increase arrow head size
h2.NodeColor = nodeColors;  % Apply colors to nodes 
h2.MarkerSize = 25;         % Define node size
h2.EdgeAlpha = 1;

% Node Label Properties
for i = 1:NL
    text(X(i), Y(i), nodes(i), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'middle', ...
        'Color', 'w', ...
        'FontSize', 14, ...
        'FontName', 'Arial', ...
        'FontWeight', 'bold', ...
        'Tag', 'nodeLabel');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%% BUS MOVEMENT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hold on;
axis equal;
axis off;

plot(-4.5,  -3.8, 'o', 'Color', [0.95 0.95 0.95], 'MarkerSize', 1, 'MarkerFaceColor', 'w');
plot(6,  3.8, 'o', 'Color', [0.95 0.95 0.95], 'MarkerSize', 1, 'MarkerFaceColor', 'w');

routeLegend = gobjects(1,NR);
for r = 1:NR
    routeLegend(r) = plot(nan, nan, 'Color', routeColors(r,:), 'LineWidth', 2);
end

time_steps      = cell(1, NB);   % one cell per bus
bus_movement    = cell(1, NB);
xPos            = cell(1, NB);
yPos            = cell(1, NB);
busMarker       = cell(1, NB);
busHeight       = cell(1, NB);
busWidth        = cell(1, NB);


busHeight       = 0.4;
busWidth        = 0.8;
maxBusWidth     = 0.8;

busColors = lines(NB) * 0.8;
busLegend = gobjects(1,NB);
% Find the location of each bus per each time
for b = 1 : NB
    [time_steps{b}, bus_movement{b}] = generate_results(x_opt, n_w_bRt_plus + n_w_bRt_minus, n_x_blt_minus, n_x_blt_plus, b, NB, N, "x_blt");
    
    %%%%% Stack buses if there are multiple at the same location
    count           = 0;
    
    for q = 1 : b - 1 
        if bus_movement{q}(1) == bus_movement{b}(1) 
            count = count + 1; 
        end 
    end
        
    yOffset = count * (busHeight + 0.01);  % stack buses above each other


    xPos{b}                          = X(bus_movement{b}(1)) - (maxBusWidth - 0.06);      % Initial x position
    yPos{b}                          = Y(bus_movement{b}(1)) + yOffset;                   % Initial y position

    busMarker{b}                     = rectangle('Position', [xPos{b} - busWidth/2, yPos{b} - busHeight/2, busWidth,...
                                       busHeight],'FaceColor', busColors(b,:), 'FaceAlpha', 0.35, 'EdgeColor', 'k', 'LineWidth', 1.5,'Curvature', 0.1);
    busLegend(b) = patch(nan,nan, busColors(b,:),'FaceAlpha', 0.35, 'EdgeColor','k');
end
routeLabels = "Route " + string(1:NR); 
busLabels   = "Bus " + string(1:NB) + " (Cap " + string(C) + ")";

%%%%%%%%%%%%%%%%%%%%%%%%%%%% PASSENGERS LOCATIONS %%%%%%%%%%%%%%%%%%%%%%%%%

time                = cell(1, NP);   % one cell per bus
passenger_location  = cell(1, NP);
passenger_bus       = cell(1, NP);
pXpos               = cell(1, NP);
pYpos               = cell(1, NP);
passengerMarker     = cell(1, NP);
disp(Y_i);
z_ist_index = n_w_bRt_minus + n_w_bRt_plus + n_x_blt_minus + n_x_blt_plus + n_y_ibt_minus + n_y_ibt_plus;
y_ibt_index = n_w_bRt_minus + n_w_bRt_plus + n_x_blt_minus + n_x_blt_plus;

radius          = busWidth / 4 / 2;
pMarker_d       = 2 * radius;
amber           = [1, 0.75, 0];

pyOffset        = 0.05;

passengerText = gobjects(1, NP);  % Preallocate array for text handles



for p = 1 : NP

    [time{p}, passenger_location{p}] = generate_results(x_opt, z_ist_index, n_z_ist_minus, n_z_ist_plus, p, NP, N, "z_ist");
    [time{p}, passenger_bus{p}]      = generate_results(x_opt, y_ibt_index, n_y_ibt_minus, n_y_ibt_plus, p, NP, N, "y_ibt");
    
    % Base passengers coordinates
    baseX       = X(passenger_location{p}(1)) + pyOffset + 0.25;      % Initial x position
    baseY       = Y(passenger_location{p}(1)) + pyOffset;     % Initial y posiion
    
    count = 0;
    for q = 1 : p - 1
        if (X(passenger_location{q}(1)) == X(passenger_location{p}(1))) && (Y(passenger_location{q}(1)) == Y(passenger_location{p}(1)))
            count = count + 1;
        end
    end

    xOffset = count * (pMarker_d + 0.01) + 0.10;

    % Final passenger coordinates
    % Base passengers coordinates
    pXpos{p}        = baseX + xOffset;     % Initial x position
    pYpos{p}        = baseY;
    
    if 1 >= (2*(I{p}) + 1)

        passengerMarker{p} = rectangle('Position', [pXpos{p} - radius, pYpos{p} - radius, pMarker_d, pMarker_d],'FaceColor', 'g',...
                                 'EdgeColor', 'k', 'LineWidth', 1.5,'Curvature', [1 1]);
        passengerText(p)   = text(pXpos{p}, pYpos{p}, string(p),'HorizontalAlignment', 'center', ...
                                 'VerticalAlignment', 'middle', 'FontSize', 10,'Color', 'k', 'Tag', 'PassengerLabel');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%% ANIMATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lgd = legend([routeLegend busLegend], [routeLabels busLabels], 'Location', 'eastoutside', 'FontSize',12);
lgd.Position = lgd.Position + [-0.14 0 0 0];
lgd.AutoUpdate = 'off';
title("Time step: " + join(string(time_steps{1}(1))), 'FontSize', 14);  % Initial title before pressing any keys

plot(-4.5,  -3.8, 'o','Color', [0.95 0.95 0.95], 'MarkerSize', 1, 'MarkerFaceColor', 'w');
plot(6,  3.8, 'o', 'Color', [0.95 0.95 0.95], 'MarkerSize', 1, 'MarkerFaceColor', 'w');

% Attach key handler
set(gcf,'KeyPressFcn',@(src, event) keyHandler(src, event, bus_movement, passenger_location, passenger_bus, X, Y, busMarker, passengerMarker, passengerText, time_steps, NB, NP, N, I, Y_i));

function keyHandler(~, event, bus_movement, passenger_location, passenger_bus, X, Y, busMarker, passengerMarker,passengerText, time_steps, NB, NP, N, I, Y_i)
    persistent step timeStep tally
    
    if isempty(step)
        step = 1;
    end
    if isempty(timeStep)
        timeStep = 1;   
    end
    if isempty(tally)
        tally = cell(1, NP);
        for p = 1:NP
            tally{p} = zeros(1, (N + 1) * 2);
        end
    end

    busWidth    = 0.8;
    busHeight   = 0.4;
    maxBusWidth = 0.8;
    yOffset     = 0.05;

    %%%%%%%%%%%%%%%%%%% Passenger Marker Constants %%%%%%%%%%%%%%%%%%%%
    radius          = busWidth / 4 / 2;
    pMarker_d       = 2 * radius;
    xOffset         = busWidth;
    pyOffset        = 0.05;
    amber           = [1, 0.75, 0];

    % Move forward/backward
    if strcmp(event.Key,'rightarrow')
        step     = min(step + 1, (N + 1) * 2);      % Cannot go above the total number of timesteps
        timeStep = min(timeStep + 1, (N + 1) * 2);  % Cannot go above the total number of timesteps          
    elseif strcmp(event.Key,'leftarrow')
        step     = max(step - 1, 1);         % cannot go below 1
        timeStep = max(timeStep - 1, 1);     % decrement time
    else
        return;
    end
    
    %%%%%%%% Delete all currently plotted rectangles
    delete(findall(gca, 'Type', 'rectangle'));
    delete(findall(gca, 'Tag', 'PassengerLabel'));

    busColors = lines(NB) * 0.8;

    %%%%%%%%%%%%%%%%%%%%%% Update Bus Position %%%%%%%%%%%%%%%%%%%%%%%%
    for b = 1 : NB
        
        count  = 0;

        for q = 1 : b - 1 
            if bus_movement{q}(step) == bus_movement{b}(step) 
                count = count + 1; 
            end 
        end
        
        yOffset = count * (busHeight + 0.01);  % stack buses above each other

        xPos    = X(bus_movement{b}(step)) - (maxBusWidth - 0.06);
        yPos    = Y(bus_movement{b}(step)) + yOffset;
        
        busMarker{b} = rectangle('Position', [xPos - busWidth/2, yPos - busHeight/2, busWidth,...
                       busHeight],'FaceColor', busColors(b,:), 'FaceAlpha', 0.35, 'EdgeColor', 'k', 'LineWidth', 1.5,'Curvature', 0.1);
        
        pos     = busMarker{b}.Position;          % [xLeft, yBottom, width, height]
        bX(b)   = pos(1) + pos(3)/2;   % xCenter
        bY(b)   = pos(2) + pos(4)/2;   % yCenter

        title("Time step: " + time_steps{1}(timeStep), 'FontSize', 14);
    end

    %%%%%%%%%%%%%%%%%%% Update Passenger Position %%%%%%%%%%%% 
    
    drawnow;

    for p = 1 : NP 
        pyOffset = 0.05; 
        
        if isnan(passenger_location{p}(step)) % Check if passenger is at a bus stand
            
            count = 0; 
            
            for q = 1 : p - 1 
                if passenger_bus{q}(step) == passenger_bus{p}(step) 
                    count = count + 1; 
                end 
            end

            xBusCenters = linspace(bX(passenger_bus{p}(step)) - (busWidth / 2) + radius, bX(passenger_bus{p}(step)) + (busWidth / 2) - radius, 4);
            yBusCenters = linspace(bY(passenger_bus{p}(step)) - (busHeight / 2) + radius, bY(passenger_bus{p}(step)) + (busHeight / 2) - radius, 2);

            
            if count < 4
                pXpos       = xBusCenters(count + 1);       % Define passengerMarker x position
                pYpos       = yBusCenters(1);               % Define passengerMarker y position
            else
                pXpos       = xBusCenters(count - 3);       % Define passengerMarker x position
                pYpos       = yBusCenters(2);               % Define passengerMarker y position
            end
             
            passengerMarker{p} = rectangle('Position', [pXpos - radius, pYpos - radius, pMarker_d, pMarker_d], ... 
                                 'FaceColor', 'g', 'EdgeColor', 'k', 'LineWidth', 1.5, 'Curvature', [1 1]); 
            passengerText(p) = text(pXpos, pYpos, string(p),'HorizontalAlignment', 'center', ... 
                               'VerticalAlignment', 'middle','FontSize', 10,'Color', 'k', 'Tag', 'PassengerLabel');
            continue 
        
        elseif timeStep >= (2*(I{p}) + 1)
            
            count = 0; 
            
            for q = 1 : p - 1 
                if ~isnan(passenger_location{q}(step)) && any(isgraphics(passengerMarker{q})) ...
                        && passenger_location{q}(step) == passenger_location{p}(step) 
                    
                    count = count + 1; 
                end 
            end
                
            xOffset = count * (pMarker_d + 0.01) + 0.35; 
            pXpos   = X(passenger_location{p}(step)) + pyOffset + xOffset; % Define passengerMarker x position 
            pYpos   = Y(passenger_location{p}(step)) + pyOffset;           % Define passengerMarker y position


            if passenger_location{p}(step) == Y_i{p} && tally{p}(step - 1) < 1
                passengerMarker{p} = rectangle('Position', [pXpos - radius, pYpos - radius, pMarker_d, pMarker_d], ... 
                                 'FaceColor', 'r', 'EdgeColor', 'k', 'LineWidth', 1.5, 'Curvature', [1 1]);
                passengerText(p)   = text(pXpos, pYpos, string(p),'HorizontalAlignment', 'center', ... 
                                  'VerticalAlignment', 'middle','FontSize', 10,'Color', 'k', 'Tag', 'PassengerLabel'); 
                
                if step > 1
                    tally{p}(step) = tally{p}(step - 1) + 1;
                else
                    tally{p}(step) = 1;
                end

                disp(tally{p}(step));
            elseif passenger_location{p}(step) == Y_i{p} && tally{p}(step - 1) >= 1
                delete(passengerMarker{p});
                delete(passengerText(p));

                if step > 1
                    tally{p}(step) = tally{p}(step - 1) + 1;
                else
                    tally{p}(step) = 1;
                end
            
            else
                passengerMarker{p} = rectangle('Position', [pXpos - radius, pYpos - radius, pMarker_d, pMarker_d], ... 
                                 'FaceColor', 'g', 'EdgeColor', 'k', 'LineWidth', 1.5, 'Curvature', [1 1]);
                passengerText(p)   = text(pXpos, pYpos, string(p),'HorizontalAlignment', 'center', ... 
                                  'VerticalAlignment', 'middle','FontSize', 10,'Color', 'k', 'Tag', 'PassengerLabel'); 
            end
            
        end 
    end

    % % -------- SAVE FRAME --------
    % ts = string(time_steps{1}(timeStep));
    % 
    % % Convert "5-" → "5_minus", "5+" → "5_plus"
    % fname = ts;
    % fname = replace(fname, "^{+}", "_plus");
    % fname = replace(fname, "^{-}", "_minus");
    % 
    % filename = "figures/S12a_" + fname + ".png";
    % 
    % exportgraphics(gcf, filename, 'Resolution', 300);
end
end
