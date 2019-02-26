%Calculate effective height
%INPUTS
    %z -> vector of path height along path
    %G -> Path weighting function
    %L -> Path length
    %Options
        %Path Weighted Average
        %TBD

function z_eff = effScintHeight(z, G, L, varargin)

%TO ADD
    %Add different effective height calculations
    
%make inputs column vectors
if ~iscolumn(z)
    z = z';
end
if ~iscolumn(G)
    G = G';
end

if length(z)~=length(G)
    error('z(u) and G(u) must be the same length')
else
    dL = (L/length(G));
    tmp = trapz(G)*dL;
    W = G./tmp;
    
    tmp = z.*W;
    z_eff = trapz(tmp)*dL;
end