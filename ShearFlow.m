% Test Inputs
    % Node coordinates: [x1, y1; x2, y2; ...]
    %nodes = [-200,-50;0,-25;100,-50;100,50;0,25;-200,50];
    
    % Connections: {(boom1)[1st conneced boom, second connected boom...; 1st connection thickness, second connection thickness...], 
    % (boom2)[1st connected boom, 2nd connected boom...;1st connection thickness, second connection thickness...]...}
    %connections = {[2,6;2,1],[1,3,5;2,2,3],[2,4;2,1],[3,5;1,2],[2,4,6;3,2,2],[1,5;1,2]};
    % Should get answers of:
    % Ixx = 1.9749e+06
    % B = [184.63, 431.18, 102.56, 102.56, 431.18, 184.63]

% Function + Read Me
    % Inputs:
    %   nodes - Nx2 array of node coordinates: [x1, y1; x2, y2; ...].
    %
    %   connections - Cell array where each cell contains connected node indices for a node: {(boom1)[1st conneced boom, 
    %   second connected boom...; 1st connection thickness, second connection thickness...], 
    %   (boom2)[1st connected boom, 2nd connected boom...;1st connection thickness, second connection thickness...]...}.
    %
    %
    % Outputs:
    %   Ixx - Second moment of area for the idealised cross section.
    %
    %   B - Array individual boom areas.
function [Ixx,B] = ShearFlow(nodes,connections)
% Utilities
    % Transposing the nodes array into an easier to use (but harder to
    % input) array
    nodes = transpose(nodes);

    % Initial util values
    numberOfConnections = sum(cellfun(@length, connections))/2; % Total number of connections
    numberOfNodes = length(nodes);
    NeutAxis = 0; % Can be changed if need be, assumed to be in the y-axis
    
    %Extracting geometric data from connections array
    NodeData = zeros(numberOfNodes,8);
    for i = 1:numberOfNodes
        c = connections(i);
        m = cell2mat(c);
        %SpareRBlock = zeros(1,8);
        r = reshape(m,1,[]);
        %Make the array a 1x8
        n = length(r);
        if n < 8
            p = [r, zeros(1,8 - n)];
        else
            p=rl;
        end
        %p = padarray(r, [0, 8 - length(r)], 0, 'post');
        NodeData(i,:) = p;
        %NodeData(i) = reshape(cell2mat(connections(i)) ,1,[]);
    end

% Error Checks
    %Check that there is only one neutral axis
    if size(NeutAxis) ~= 1
        error('The neutral axis should be a single number')
    end

    % Checks for the correct number of thicknesses
    %if numberOfNodes ~= length(thicknesses)
        %error('The number of nodes must math the number of thicknesses')
    %end
    
    % Checks that each row of NodeData is divisible by 2
    for i = 1:numberOfNodes
        if mod(NodeData(:,i),2) ~= 0
            error('There is an error with the node data structure')
        end
    end

    % Checks that the number of collums in NodeData is equal to number of
    % nodes
    if height(NodeData) ~= numberOfNodes
        error('There are more nodes in NodeData than the number of nodes')
    end

    % Checks for the number of connections
    if numberOfConnections > (numberOfNodes+1)
        error('The number of connections cannot be greater than the number of nodes + 1')
    end
    
    % Checks that each connection has a thickness
    %if length(thicknesses) ~= numberOfConnections
        %error('The number of connections and thickness must match')
    %end

% Calculations
    % Boom Areas
    b = zeros(numberOfNodes,4);
    B = zeros(numberOfNodes,1);

    % Cycles through each node
    for i = 1:numberOfNodes
        % Obtaining current nodes data
        IntermediateNodeData = NodeData(i,:);
        % Finding the last non-zero index of the array
        LastNonZeroIndex = find(IntermediateNodeData ~= 0, 1, 'last');
        % Slicing off the zeros
        CalcNode = IntermediateNodeData(1:LastNonZeroIndex);
        % Number of connections
        NodeConnections = length(CalcNode)/2;

        % Cycles through each connection
        for j = 1:NodeConnections
            %Index for the destination node, contained within CalcNode
            %array
            DestNodePointer = 2*j - 1;
            % Makes sure that the calc node is the correct length
            if mod(length(CalcNode),2) ~= 0
                error('Wrong calculation node length')
            end
            % Calculates the length of the connection
            Length = hypot((nodes(1,i)-nodes(1,CalcNode(DestNodePointer))),(nodes(2,i)-nodes(2,CalcNode(DestNodePointer))));
            % Obtains the thickness from the calcNode array
            Thicc = CalcNode(1,DestNodePointer + 1);
            % Inputs current connection area into an array, ready to be
            % summed
            b(i,j) = ((Length*Thicc)/6)*(2+(nodes(2,CalcNode(DestNodePointer))/(nodes(2,i))));
        end
        % Summs the connection areas into a boom area for each node
        B(i) = sum(b(i,:));
    end
    % Transpose B for ease of use
    B = transpose(B);
    
    %Calculating Ixx
    % Creates an array of ixx for each node before summing them together
    ixx = zeros(numberOfNodes);
    for i = 1:numberOfNodes
        ixx(i) = B(i) * nodes(2,i)^2;
    end
    InterIxx = sum(ixx,1);
    Ixx = sum(InterIxx);
end



