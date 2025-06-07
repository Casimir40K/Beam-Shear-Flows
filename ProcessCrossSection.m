function [loopData, arrowData] = ProcessCrossSection(nodes, connections)
    % ProcessCrossSection: Analyzes a beam cross-section to find loops,
    % eliminate redundant loops, visualize the graph, and manage arrow numbering.
    %
    % Inputs:
    % - nodes: Nx2 array of node coordinates [x, y].
    % - connections: 3xM array [startNode; endNode; thickness], where each column is a connection.
    %
    % Outputs:
    % - loopData: Struct array containing details of each loop.
    % - arrowData: Struct array containing details of each arrow.
    % Testing data
    connections = [1,1,2,2,2,3,3,4,4,5,5,5,6,6;2,6,1,3,5,2,4,3,5,4,6,2,5,1;2,3,2,2,4,2,3,3,2,2,2,4,2,3];
    nodes = [40,40;0,40;-40,40;-40,-40;0,-40;40,-40];
    % Step 1: Prepare edges from connections by removing thickness
    edges = connections(1:2,:); % Transpose to get Mx2 format
    edges = transpose(edges);
    edges = unique(sort(edges, 2), 'rows'); % Remove duplicate edges (undirected)

    % Step 2: Create graph and find all cycles
    G = graph(edges(:, 1), edges(:, 2));
    allCycles = allcycles(G); % Replace with custom function if needed
    numCycles = length(allCycles);

    % Step 3: Compute areas of all cycles and store in a struct
    cycleData = struct('nodes', {}, 'area', {}, 'isObsolete', false);
    for i = 1:numCycles
        cycleNodes = allCycles{i};
        cyclePoints = nodes(cycleNodes, :);
        cycleData(i).nodes = cycleNodes;
        cycleData(i).area = cycleArea(cyclePoints);
        cycleData(i).isObsolete = false; % Initialize as not obsolete
    end

    % Sort cycles by area (smallest to largest)
    [~, idx] = sort([cycleData.area]);
    cycleData = cycleData(idx);

    % Step 4: Eliminate redundant cycles
    for i = 1:numCycles
        if cycleData(i).isObsolete
            continue;
        end
        for j = i+1:numCycles
            if cycleData(j).isObsolete
                continue;
            end
            isObsolete = isCycleRedundant(cycleData(j).nodes, cycleData(i).nodes, nodes);
            if isObsolete
                cycleData(j).isObsolete = true;
            end
        end
    end

    % Filter non-redundant cycles
    finalCycles = {cycleData(~[cycleData.isObsolete]).nodes};
    numFinalCycles = length(finalCycles);

    % Step 5: Visualize the graph with cycles
    figure;
    hold on;
    plot(G, 'XData', nodes(:, 1), 'YData', nodes(:, 2), ...
        'NodeColor', 'k', 'EdgeColor', 'k', 'LineWidth', 1);
    title('Cross-Section with Cycles and Arrows');
    axis equal;

    % Prepare to store loop and arrow data
    loopData = struct('centroid', {}, 'nodes', {}, 'number', {}, 'arrows', {});
    arrowData = struct('number', {}, 'inLoop', {}, 'outLoop', {});
    usedNumbers = [];
    arrowCount = 1;

    % Assign loop numbers and plot arrows
    for i = 1:numFinalCycles
        cycleNodes = finalCycles{i};
        cyclePoints = nodes(cycleNodes, :);
        cycleCentroid = mean(cyclePoints, 1);
        loopColour = rand(1, 3);

        % Resolve conflicts in centroid placement
        conflict = true;
        while conflict
            conflict = false;
            for j = 1:i-1
                if norm(cycleCentroid - loopData(j).centroid) < 0.1
                    cycleCentroid = cycleCentroid + 0.05 * randn(1, 2);
                    conflict = true;
                    break;
                end
            end
        end

        % Assign loop number
        % avgIndex = round(mean(cycleNodes));
        % while ismember(avgIndex, usedNumbers)
        %     avgIndex = avgIndex + randi([-5, 5]);
        % end
        % usedNumbers = [usedNumbers, avgIndex];

        % new Loop Number 
        loopIndex = single(i);
        


        % Store loop data
        loopData(i).centroid = cycleCentroid;
        loopData(i).nodes = cycleNodes;
        loopData(i).number = loopIndex;
        loopData(i).arrows = [];

        % Plot arrows and assign numbers
        for j = 1:length(cycleNodes)
            startPoint = cyclePoints(j, :);
            endPoint = cyclePoints(mod(j, length(cycleNodes)) + 1, :);
            arrowDir = endPoint - startPoint;
            inwardShift = 0.1 * (cycleCentroid - startPoint);
            scaledArrowDir = 0.8 * arrowDir;
            arrowBase = startPoint + inwardShift;

            % Plot the arrow
            quiver(arrowBase(1), arrowBase(2), scaledArrowDir(1), scaledArrowDir(2), ...
                0, 'MaxHeadSize', 0.4, 'Color', loopColour, 'LineWidth', 1.5, 'AutoScale', 'off');

            % Store arrow data
            arrowData(arrowCount).number = sprintf('q%d', arrowCount);
            arrowData(arrowCount).inLoop = loopIndex;
            arrowData(arrowCount).outLoop = mod(j, length(cycleNodes)) + 1;
            loopData(i).arrows = [loopData(i).arrows, arrowCount];
            arrowCount = arrowCount + 1;
        end

        % Add loop number at centroid
        text(cycleCentroid(1), cycleCentroid(2), sprintf('%d', loopIndex));
        radius = 2.5;  % Adjust for desired circle size
        hold on;
        rectangle('Position', [cycleCentroid(1)-1.7, cycleCentroid(2)-2.55, 2*radius, 2*radius], ...
          'Curvature', [1, 1], 'EdgeColor', 'k', 'LineWidth', 1);
    end
    hold off;
end

% Function to calculate the area of a polygon
function area = cycleArea(points)
    x = points(:, 1);
    y = points(:, 2);
    area = 0.5 * abs(sum(x .* circshift(y, -1)) - sum(y .* circshift(x, -1)));
end

% Function to check if one cycle is redundant
function isRedundant = isCycleRedundant(bigCycle, smallCycle, nodes)
    bigCyclePoints = nodes(bigCycle, :);
    smallCyclePoints = nodes(smallCycle, :);
    [in, ~] = inpolygon(smallCyclePoints(:, 1), smallCyclePoints(:, 2), ...
                        bigCyclePoints(:, 1), bigCyclePoints(:, 2));
    isRedundant = all(in);
end
