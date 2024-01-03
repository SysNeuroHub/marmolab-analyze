function [pos,stats] = fitSigmoidPMA(PMA,varargin)
% Fit 4-parameter sigmoid to PMA (phase mean angle?) matrix.
% This minimises phase-error (i.e. circular distance) between sigmoid and
% raw data
%
% INPUTS
% - PMA - 2D or 3D matrix of phase mean angles
% - plotSigmoid - shows sigmoid fits for every channel
% - plotHeat - shows summary heatmap plus inflection points
%
% OUTPUTS
% pos - Sigmoid inflection point for:
% .indiv - individual electrodes
% .indivMed - median(pos.indiv)
% .mu - fit to channel-averaged data
%
% stats - results of F-statistic comparing sigmoid fit with nested model
% (flat line)
% .muP/.indivP - p value of F-test
% .muF/.indivF - F-statistic
% .muConst/.indivConst - constant values used for comparison
%
% Syntax examples
% [pos, stats] = fitSigmoidPMA(PMA);
% [pos, stats] = fitSigmoidPMA(PMA,'plotSigmoid',false,'debug',true);
%
% Reference - https://elifesciences.org/articles/84512
% Nicholas Price, 090623

%% parse arguments...
p = inputParser();
p.KeepUnmatched = true;
p.addParameter('nEst',3);% number of channels at each end to use for estimating plateaus. The larger you can make this, the better.
p.addParameter('plotSigmoid',false);
p.addParameter('plotHeat',false);
p.addParameter('debug',false);
% added below parameters Jan 3 2024, Gretel GB
p.addParameter('shank',0); 
p.addParameter('channelOrder',[]);
p.addParameter('subject','CJ000');
p.addParameter('date',"00/00/00");
p.parse(varargin{:});
pa = p.Results;

if nargin<1 || isempty(PMA) % personalise filename
    load('C:\git\homeless\MeanPhase_210813_sampleData.mat')
    pa.plotSigmoid = true;
    pa.plotHeat = true;
    pa.debug = true;
end

% expect a 2D input. If it's 3D, assume first dimension is different
% phases, so just call this function recursively
if ndims(PMA)==3
    for a = 1:size(PMA,1)
        [pos(a),stats(a)] = fitSigmoidPMA(squeeze(PMA(a,:,:)),'nEst',pa.nEst,'plotSigmoid',pa.plotSigmoid,'plotHeat',pa.plotHeat,'debug',pa.debug,'shank',pa.shank);
    end
    return
elseif ~ismatrix(PMA)
    error('PMA must be dimension 2 or 3');
end

% Remove any rows that are completely NaN otherwise code breaks
% Cannot set to 0 because will skew averages later.
rowsToRemove = all(isnan(PMA),2);
PMA(rowsToRemove,:) = [];

sz = size(PMA);
% assert(sz(1)==sz(2),'Expected a square matrix') % not sure if this is necessary/useful
% assert(all(~isnan(PMA)),'NaN found in PMA. Haven''t checked if that works yet!')
sz = sz(1);

pFinal = zeros(sz,4); % preallocate pFinal in the event that there are rows of NaNs at the end of the data

for b = 1:sz % work through channels
    thisCh = PMA(b,:);

    if (all(~isnan(thisCh)))
        % Circular mean of leftmost and rightmost points
        leftGuess = angle(sum(exp(1i*thisCh(1:pa.nEst))));
        rightGuess = angle(sum(exp(1i*thisCh(end-pa.nEst+1:end))));
        pInit = [round(sz/2) 0.5 leftGuess rightGuess];
        
        opt = optimoptions('lsqnonlin','Display','off'); %,'Display','iter'); %odeset('RelTol',1e-8,'AbsTol',1e-16);
        myObj = @(pa) costFn(logiFun(pa,1:sz), thisCh);
        lb = []; % so far, this seems to converge fine without constraints
        ub = [];

        pFinal(b,:) = lsqnonlin(myObj, pInit,lb,ub,opt); %, mo.lb, mo.ub);
    end
end

%% Circular-average across channels before fitting

muPMA = angle(sum(exp(1i*PMA))); % circular mean across rows 
leftGuess = angle(sum(exp(1i*muPMA(1:pa.nEst))));
rightGuess = angle(sum(exp(1i*muPMA(end-pa.nEst+1:end))));
pInit = [round(sz/2) 0.5 leftGuess rightGuess];

pMu = lsqnonlin(myObj, pInit,lb,ub,opt); %, mo.lb, mo.ub);

pos.indiv = pFinal(:,1);
pos.indivMed = median(pos.indiv);
pos.mu = pMu(1);

%% Statistics
% Use F-test to compare sigmoid fits with a flat line
% the best-fit flat line is just the circular mean of all the data
% Using Should really use packaged f-test
dfConst = sz - 1; % degrees of freedom
dfSig = sz - 4; % 4 parameters

stats.muConst = angle(sum(exp(1i*muPMA)));
stats.indivConst = angle(sum(exp(1i*PMA),2)); 

% preallocate might be useful?
% stats.indivP = zeros(sz,sz);
% stats.indivF = zeros(sz,1);

[stats.muP, stats.muF] = ftest(muPMA, stats.muConst,logiFun(pMu,1:sz), dfConst, dfSig);
% [stats.muP, stats.muF] = ftest(length(muPMA), ,length(logiFun(pMu,1:sz)), dfConst, dfSig);
for a = 1:length(PMA)
    [stats.indivP(a,:), stats.indivF(a)] = ftest(PMA(a,:), stats.indivConst(a),logiFun(pFinal(a,:),1:sz), dfConst, dfSig);
end


%% PLOTTING

%% Sigmoids for a single frequency
if pa.plotSigmoid
    figure
    xx = 1:sz;
    nX = ceil(sqrt(sz));
    nY = ceil(sz/nX);
    sgtitle("") % may need to know array and shank number from plotDataDive()
    
%     for b = 1:sz
    for b = 1:length(pFinal)
        subplot(nX,nY,b)
        plot(xx, squeeze(PMA(b,:)),'ro-','markerfacecolor','r')
        hold on
        plot(xx, logiFun(pFinal(b,:),xx),'b')
        plot([1 sz], stats.indivConst(b)*[1 1],'m:') % to visualise comparison of sigmoid fit vs horizontal line - sometimes identical (p = 1)
        plot(pos.indiv(b)*[1 1],[-pi pi],'k','linewidth',2) % so does pos.indiv contain the transition point - looks like yes
        plot([0 sz],[-pi -pi; 0 0; pi pi],'k')
        axis([0 sz -pi pi])
        set(gca,'ytick',[-pi 0 pi],'yticklabel',{'-\pi','0','\pi'})
        
        %         axis off
        %         title("Ch"+b);
        title("Ch"+channelOrder(b)+ " - " + ptext(stats.indivP(b)))
    end
end


%%
if pa.plotHeat
    figure
    subplot(6,1,1:4)
    imagesc(PMA)
    hold on
    for b = 1:sz
        plot(pFinal(b,1)*[1 1],[b-0.5 b+0.5],'r','linewidth',2)
    end
    ax = axis;
    axis(ax+[0 0 0 1])
    plot(pos.indivMed*[1 1],ax(4)+[0 1],'m','linewidth',3)
    text(pos.indivMed+0.2,ax(4)+0.5,'median')
    caxis([-pi pi])
    colorbar('East')
    
    subplot(6,1,5)
    imagesc(muPMA)
    hold on
    plot(pos.mu*[1 1],[0.5 1.5],'w','linewidth',4)
    plot(pos.mu*[1 1],[0.5 1.5],'k','linewidth',2)
    plot(pos.indivMed*[1 1],[0.5 1.5],'m','linewidth',2)
    xl = xlim;
    
    subplot(6,1,6)
    plot(muPMA)
    hold on
    plot(pos.mu*[1 1],[-pi pi],'k','linewidth',3)
    plot(pos.indivMed*[1 1],[-pi pi],'m','linewidth',2)
    title(sprintf('Mean p=%0.2f', stats.muP))
    title("Mean - " + ptext(stats.muP))

    xlim(xl)
    legend('Mean Ch Response','Mean Ch inflection','Indiv ch median');
    legend boxoff
    
end

%%
if pa.debug
    keyboard
end


function y = logiFun(p,depth)
% Define our custom sigmoid (logistic) function
% p == [A B C D];
% A = center point
% B = slope
% C = left plateau
% D = right plateau
% y = (D-C) / (1+exp(B*(A-x)) + C;

y = (p(4)-p(3)) ./ (1+exp(p(2)*(p(1)-depth))) +p(3);

function y = flatFun(p,depth)
y = p(1);


function cost = costFn(obs,mod)
%
% -obs & mod - vectors of observed and modelled phases in RADIANS
% for lsqnonlin, cost is a vector

cost = angle(exp(1i*obs)./exp(1i*mod)); % smallest (signed) difference between phases
