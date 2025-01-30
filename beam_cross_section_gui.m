function beam_cross_section_gui
    % Declare nodes and connections in the base workspace
    % Initialize variables to store nodes and connections
    global nodes;  % Array to store node coordinates
    global connections;  % Cell array to store connections

    nodes = [];
    connections = {};

    % Create the main figure
    fig = uifigure('Name', 'Beam Cross-Section Designer', 'Position', [100 100 800 600]);
    
    % Axes for visualization with the origin at the center
    ax = uiaxes(fig, 'Position', [50 150 700 400]);
    title(ax, 'Cross-Section Viewer');
    xlabel(ax, 'X (mm)');
    ylabel(ax, 'Y (mm)');
    grid(ax, 'on');
    hold(ax, 'on');
    ax.XLim = [-100, 100]; % Example limits (adjust as needed)
    ax.YLim = [-100, 100]; % Example limits (adjust as needed)
    ax.XAxisLocation = 'origin';
    ax.YAxisLocation = 'origin';
    
    % Create UI elements for adding nodes and connections
    uilabel(fig, 'Text', 'Add Node (x, y):', 'Position', [50 70 100 20]);
    nodeInput = uieditfield(fig, 'text', 'Position', [150 70 150 22]);
    uibutton(fig, 'Text', 'Add Node', ...
        'Position', [310 70 80 22], ...
        'ButtonPushedFcn', @(btn, event) addNode(nodeInput, ax));
    
    uilabel(fig, 'Text', 'Add Connection (n1, n2, t):', 'Position', [50 30 160 20]);
    connectionInput = uieditfield(fig, 'text', 'Position', [210 30 150 22]);
    uibutton(fig, 'Text', 'Add Connection', ...
        'Position', [370 30 120 22], ...
        'ButtonPushedFcn', @(btn, event) addConnection(connectionInput, ax));
    
    uibutton(fig, 'Text', 'Export Data', ...
        'Position', [550 50 100 30], ...
        'ButtonPushedFcn', @(btn, event) exportData());

    % Function to add a node
    function addNode(nodeInput, ax)

        
        % Parse input for node coordinates
        coords = str2num(nodeInput.Value); %#ok<ST2NM>
        if isempty(coords) || length(coords) ~= 2
            uialert(ax.Parent, 'Please enter valid coordinates in the format: x, y', 'Invalid Input');
            return;
        end
        
        % Add node and initialize empty connections for the new node
        nodes = [nodes; coords];
        connections{end + 1} = []; % Initialize empty connection array for the new node
        nodeNumber = size(nodes, 1); % Node index
        
        % Display the new node on the plot
        plot(ax, coords(1), coords(2), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
        text(ax, coords(1), coords(2), sprintf('%d', nodeNumber), ...
             'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
        
        % Clear input field after adding node
        nodeInput.Value = ''; 
    end
    
    % Function to add a connection
    function addConnection(connectionInput, ax)
        % Access the nodes and connections variables

        % Parse the connection input
        connection = str2num(connectionInput.Value); %#ok<ST2NM>
        if isempty(connection) || length(connection) ~= 3
            uialert(ax.Parent, 'Please enter valid connection data in the format: n1, n2, t', 'Invalid Input');
            return;
        end
        
        % Extract node numbers and thickness
        n1 = connection(1);
        n2 = connection(2);
        thickness = connection(3);
        
        % Validate node indices
        if n1 > size(nodes, 1) || n2 > size(nodes, 1) || n1 < 1 || n2 < 1
            uialert(ax.Parent, 'Invalid node numbers! Make sure they exist.', 'Invalid Input');
            return;
        end
        
        % Add the connection to both nodes
        connections{n1} = [connections{n1}, [n2; thickness]];
        connections{n2} = [connections{n2}, [n1; thickness]]; % Bi-directional connection
        
        % Draw the connection line
        node1 = nodes(n1, :);
        node2 = nodes(n2, :);
        line(ax, [node1(1), node2(1)], [node1(2), node2(2)], 'Color', 'b', 'LineWidth', thickness);
        
        % Display connection thickness
        midPoint = (node1 + node2) / 2; % Midpoint for text placement
        text(ax, midPoint(1), midPoint(2), sprintf('t=%.1f', thickness), ...
            'VerticalAlignment', 'top', 'HorizontalAlignment', 'center', 'Color', 'b');
        
        % Clear input field after adding connection
        connectionInput.Value = ''; 
    end
    
    % Export Data Function
    function exportData()
        % Access the nodes and connections variables

        
        % Check if nodes are available to export
        if isempty(nodes)
            uialert(gcf, 'No data to export!', 'Error');
            return;
        end
        
        % Prepare data for export
        % Export nodes
        exportNodes = nodes;  % Nodes coordinates
        % Export connections
        exportConnections = connections;  % Cell array of connections
        
        % Convert connections data to required format
        connMat = [];
        for i = 1:length(exportConnections)
            conn = exportConnections{i};
            if ~isempty(conn)
                connMat = [connMat, [i * ones(1, size(conn, 2)); conn]];
            end
        end
        % Save the data to the workspace
        assignin('base', 'nodes', exportNodes);
        assignin('base', 'connections', connMat);
        
        % Optionally, display message confirming export
        uialert(gcf, 'Data has been exported to the workspace.', 'Export Successful');
    end
end



% Coordinates of points
%points = [0, 0; 1, 0; 1, 1; 0, 1; -1, 1; -1, 0];

% Connectivity (edges as pairs of point indices)
%edges = [1, 2; 2, 3; 3, 4; 4, 5; 5, 6; 4, 1; 6, 1];%