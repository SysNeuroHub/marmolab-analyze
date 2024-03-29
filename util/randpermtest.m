function [pval, D, PD] = randpermtest(X1, X2, NPERM, flag)

% computes a random permutation test on the mean of two samples of data (X1 and X2).
% These could be firing rates, reaction times, whatever.
% option to specify number of permutations (NPERM). 1e4 is standard,
% probalby shouldnt be less than 1e3.

% flag: indicates ciruclar data and uses circstat toolbox

% remove nans
X1 = X1(~isnan(X1));
X2 = X2(~isnan(X2));

ntr1 = numel(X1);
ntr2 = numel(X2);

if nargin < 3
    NPERM = 1e4;
end

if nargin < 4
    flag = 0;
end

if ntr1 < 3 || ntr2 <3, error('not enough trials!'); end

if size(X1,1) ~= 1, X1 = X1'; end
if size(X2,1) ~= 1, X2 = X2'; end

GX = [X1,X2]; nGX = size(GX,2);
PD = nan(1,NPERM);

if ~flag
    D = sum(X1)./ntr1 - sum(X2)./ntr2;
    
    for iPerm = 1:NPERM
        NP = randperm(nGX);
        N1 = NP(1:ntr1);
        N2 = NP(ntr1+1:end);
        PX1 = sum(GX(N1))./ntr1;
        PX2 = sum(GX(N2))./ntr2;
        PD(iPerm) = PX1-PX2;
    end
    
    
elseif flag
    D = circ_dist(circ_mean(X1), circ_mean(X2));
    
    for iPerm = 1:NPERM
        NP = randperm(nGX);
        N1 = NP(1:ntr1);
        N2 = NP(ntr1+1:end);
        PD(iPerm) = circ_dist(circ_mean(GX(N1)),circ_mean(GX(N2)));
    end
end
pval = length(find(abs(PD)>abs(D)))./NPERM;


end