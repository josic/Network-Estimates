function [ x , var] = NetEst2( C, L)

% NetEst2 does a few time saving things with the goal of determining
% whether or not the connection is optimal, including:
% 1. layer checks to see
% if the optimal estimate is even possible, and if not, ending the
% computation there and throwing variance = 1 + 1/L(1)
% 2. if there is only one agent in the second layer, it's automatically
% optimal, so skip the comp. and spit out variance 1/L(1).

%% Explanation
%NetEst Calculates estimates given the connection matrix, and for now
%assuming equal variance of 1 for the top layer.

%C is the matrix of connections:
%column i tells you who agent i sends info to
%C_ji = 1 if i -> j and 0 otherwise

%L is the vector that tell you how many agents are in each layer. L(i) is
%the number of agents in layer i, so L = [L(1) L(2) ... L(num of layers)]
%It is possible to determine this from a well formatted connection matrix
%but easier to explicitly input than to code.

%% Example
%It's good to test this on 
%C = ConnectionMatrix(8,[1 4],[2 4 5],[3 5],[4 6],[5 7],[6 8],[7 8])
%L = [3 2 2 1]

if L(2) == 1
    x = 1;
    var = 1/L(1);
else
%% Constants
N = sum(L);             %total number of agents
I = zeros(N,N);         %initial info matrix
K = length(L);          %number of layers


%this gives the matrix whose column i tell you who agent i receives info from
TC = transpose(C);

%% Computation of layers 1 and 2
%The first and second layers are easy to compute without requiring covariance matrix inversion
%, so we do those and leave the third and on layers to an algorithm which uses covariance
%matrices


%We read the info matrix as the matrix of weights each agent gives to other
%agents. So the first L(1) entries of column i tell you how agent i weights
%the first layer agents and this tells us when we have an optimal network
%because the final row will have the first L(1) entries all equal to 1/L(1)



nonopt = 0;
%first check for if reduced to 3 layer is possibly optimal
if rank( C(L(1)+1:L(1)+L(2) ,1:L(1)) )  < rank([C(L(1)+1:L(1)+L(2) ,1:L(1)); ones(1,L(1)) ])
        nonopt = 1;
        x = 0;
        var = 1 + (1/L(1));
        %C(L(1)+1:L(1)+L(2) ,1:L(1))
end
    
%define the info matrix for the second layer
for k = 1:L(2)
    for j = 1:L(1)  %only need to add numbers for the top layer entries
        I(j,k + L(1)) = TC(j ,k+L(1))/sum(TC(:,k+L(1)));
        %sum(TC(:,k+L(1))) is the number of top layer agents who send
        %estimate to this layer 2 agent.
        %this will always be nonzero because we assume the agent receives
        %input from at least one of the top layer agents
    end
end

if nonopt == 0
%define the info matrix for the top layer
for k = 1:L(1)
    I(k,k) = 1;
end
%%Induction Computation
m = L(1); %layer induction constant


%defining for the rest of the layers
for k = 3:K   %starting at layer k = 3 and going till layer k = K the bottom
    for v = (m+L(k-1)+1):(m+L(k-1)+L(k))   %going through each agent of layer k
        
        %the matrix of layer 1 weights that layer k-1 is using
        P = I(1:L(1),m+1:m+L(k-1));
        
        %the column for agent i of layer k telling us who it's receiving 
        %info from
        r = TC(m+1:m+L(k-1),v);
        
        %J to index going to each elt of the previous layer and asking if they are
        %sending info
        %R = number of people who send info to the agent
        % we use to index the matrix we'll use to build the covariance matrix
        J = length(r);  % Can replace with J = L(k-1) to not waste on length calc
        R = sum(r);
        
        %setting up the matrices we use to build the covariance matrix WF
        Q = zeros(L(1),R);
        WF = zeros(R,R);
        
        %used to enter in the proper weights
        nextcol = 1;


        %Goes through the people in the layer above. If they are giving this agent
        %info, then adds their weights to the matrix Q.
        for i = 1:J
            if r(i) == 1
                Q(:,nextcol) = P(:,i);
                nextcol = nextcol +1;
            end 
        end
        
        %So Q is the matrix which tells you the layer 1 weights from each input
        for i = 1:R
            for j = 1:R
                WF(i,j) = transpose(Q(1:L(1),i))*Q(1:L(1),j);
            end
        end

        %WF is the RxR covariance matrix, which may be singular
        %Check if it's singular, and if it is de-singularize it, where we
        %keep track of what we removed from WF
        

        %         rank(WF) isitsing = singcheck(WF); cond(WF);
        %         %<-- for debugging
        
        
        if singcheck(WF) == 1    % checks if the matrix is singular
            [WF, removed] = desing(WF);  % if it is singular, run the desingularization
        end

        if k == K
            finalcov = WF;
        end
%          WF might have been resized;
        inR = R;   %inR = original number of inputs
        [R, ~] = size(WF);  %R = number of independent inputs
        
        %IWF = inv(WF);    %replaced inv(WF) below with /WF

        b = (ones(1,R)/WF)*ones(R,1); % the sum of the entries of the inverse of the reduced covariance matrix

        
        weights = (ones(1,R)/WF)/b;  % this comes out of min. var. est. 
                                     % theory for how to get the optimal 
                                     % estimate given covaried inputs
        
        fillw = zeros(1,inR);  % now turn the weights for the independent 
                               % inputs into weights for all inputs
        
        %we have to add in some zeros if we reduced the covariance matrix
        if R < inR
            p = 1;
            q = 1;
            for fillspot = 1:inR
                if fillspot == removed(p)
                    fillw(fillspot) = 0;
                    if p == length(removed)
                        removed(p) = 0;
                    else
                        p = p + 1;
                    end
                else
                    fillw(fillspot) = weights(q);
                    q = q + 1;
                end
            end    
            weights = fillw;
        end
        
        
        est = zeros(L(1),1);
        
        for l = 1:inR
            est = est + weights(l)*Q(:,l);
        end
        I(1:L(1),v) = est;
        
        recw = 1;
        for p = 1:J
            if r(p) == 1
                I(m+p,v) = weights(recw);
                recw = recw + 1;
            end
        end
            
        %sum(weights);
        
    end

    m = m + L(k-1); %for layer induction
    
end

%% Debugging and Results
%Some debugging output:
% WF
% inv(WF)
% sum(sum(inv(WF)))
% 1/sum(sum(inv(WF)))
% finalcov
% inv(finalcov)

var = 1/sum(sum(inv(finalcov)));  %determinant for the final agent's covariance matrix
    %this is the result that the variance 1/the sum of the info matrix
    %entries
    
    %the equal (1) variance network is optimal when var = 1/L(1)
        
x = I;  %the info matrix is returned as the x output argument
end

end

end  %of function

