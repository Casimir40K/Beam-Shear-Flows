function [Ixx, B] = BoomAreas(nodes, connections)

nNodes = length(nodes);
B = zeros(nNodes,1);

for i = 1:nNodes
    attachedNodes = (connections(1,:)==i); %Finds the nodes attached to the current boom anf gives a logical response
    trimmedConnections = connections(1:2,:); % Cuts of the thickness row
    trimmedConnections = find(attachedNodes)'; % Gives the collumn numbers of the attached booms
    nConnections = length(trimmedConnections); % number of connections for loop purposes
    currentNodeLocation = nodes(i,:); % Coordinate location of the current boom
    for j = 1:nConnections
        connectionIndex = trimmedConnections(j);
        connectedNodeIndex = connections(2,connectionIndex);
        connectedNodeLocation = nodes(connectedNodeIndex,:);
        l = norm(currentNodeLocation - connectedNodeLocation);
        t = connections(3,connectionIndex);
        sigma = connectedNodeLocation(2)/currentNodeLocation(2);
        B(i) = B(i) + ((l*t)/6)* (2 + sigma);
    end
end

Ixx = sum(B .* (nodes(:,2).^2));
