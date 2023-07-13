function str = ptext(p,thresh,sig)
% str = ptext(p,thresh,sig)
% returns a string for displaying p-values
%
% INPUTS
% p = p-value (e.g. from t-test)
% thresh = threshold p-value (default 0.01). 
%   Values <thresh return a string 'p<0.01'
% sig = # of significant figures for rounding (default 2)
%   e.g. input p 0.05266 returns 'p=0.053';
%
% NP Aug2009

if nargin<2, thresh = 0.01; end
if nargin<3, sig = 2; end

if p<thresh
    str = ['p<' num2str(thresh,1)];
else
    str = ['p=' num2str(p,sig)];
end
    
