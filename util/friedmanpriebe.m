function [latencyEstimate,peakEstimate,pPoisson,baseRate,responseRate] = friedmanpriebe(spikeCount,varargin)
% Latency estimation using the method described by Friedman and Priebe in
% J Neurosci Methods 83:185 (1998).
%
% The idea is that the spike count around an onset can be described as a
% Poisson process with low rate up until the latency, then a Poisson
% process with a high rate up until the peak rate, and then some lower
% level again.
% For the Cumulative number of spikes this means that it should be a
% slow linear increase followed by a rapid linear increase followed by
% another slow (or just different) linear increase. This is the model  that is fit to the data,
% and the best(ML) fit is used to determine the latency. F&L provide a
% maximum likelihood estimator for this problem, I simply implemented that
% here in Matlab. The ML calculation is done brute force for a range of
% combinations of the (assumed) latency (theta) and time to sustained (kappa)
% to estimate a 2D Likelihood function. This results in a best theta for each
% kappa.
%
% To esimtat the final latency, I then find the kappa for which the
% variance of the likelihood (for all theta) is smallest. In other words,
% this is the kappa for which the theta is most tightly constrained. Given
% this kappa, I then pick the most likely theta.
%
% INPUT
% spikeCount =  Number of spikes in each millisecond. The first entry in
%               this vector is considered time zero.
% minTheta   = The first index in spikeCount at which a response may have
%               started.
% maxTheta   = The last entry in spikeCount at which a response may have
%               started.
% maxKappa   =  Last index at which the peak of the response could be
% 
% delta       =  The minimum time between response onset and sustained
%                   onset.
% responseSign = Set to 1 to detect only increases in firing
%                Set to -1 to detect only decreases in firing
%                Set to 0 to detect both increases and decreases in firing.
% graphics     = Set to true to show a graph of the procedure.
%
%OUTPUT
% latencyEstimate = The estimated latency in milliseconds.
% peakEstimate    = Estimation of the time at which the response goes
%                       from the transient level to the sustained
% pPoisson              = p-value of the test whether the response in the estimated 
%                   window between latency and peak is significantly
%                   different from the response in the window before the
%                   response onset. (Assuming Poisson firing).
% baseRate        = firing rate in before onset
% responseRate     = firing rate in the window from onset to peak.
%
% BK - Oct 2009
p =inputParser;
p.addParameter('minTheta',2,@isnumeric);
p.addParameter('maxTheta',length(spikeCount)-2,@isnumeric);
p.addParameter('maxKappa',length(spikeCount)-1,@isnumeric);
p.addParameter('delta',1,@isnumeric);
p.addParameter('responseSign',0,@(x) (ismember(x,[-1 0 1])));
p.addParameter('graphics',false,@islogical);
p.parse(varargin{:});


thetas = p.Results.minTheta:p.Results.maxTheta; 
    
% A. Calculate the likelihood for all theta,kappa.
% Equation 2, p 188.
ll = NaN(p.Results.maxTheta,p.Results.maxKappa);
for theta = thetas
    l1 = lambda1(spikeCount,theta);
    thetaTerm = -l1.*(theta+1) + log(l1)*sum(spikeCount(1:(theta+1))) - sum(log(locfactorial(spikeCount(1:(theta+1)))));
    for kappa = (theta+p.Results.delta):p.Results.maxKappa
        l2  = lambda2(spikeCount,theta,kappa);
        kappaTerm = -l2*(kappa-theta) + log(l2).*sum(spikeCount((theta+2):(kappa+1))) - sum(log(locfactorial(spikeCount((theta+2):(kappa+1)))));
        ll(theta,kappa) = thetaTerm + kappaTerm;
    end
end

if all(isnan(ll(:)))
    latencyEstimate=NaN;
    peakEstimate=NaN;
    pPoisson=NaN;
    baseRate=NaN;
    responseRate=NaN;
    return
end
% B. Determine the best theta per kappa by fitting lines to the cumulative for
% the best theta for each kappa, and then finding the kappa for which the
% difference in slope before and after theta is maximal. 
% This is not quite what F&P do; as far as I understand their description,
% they do this fit for eveyy theta and kappa and then find the steepest
% one, but that does not make much sense as it would completely ignore the
% LL estimated above. I also tried an alternative algorithm that just
% determined the variance of the LL for every kappa and took the one with
% the least variance. (This mimicks what is on p189, top right). That
% worked fine too, but the fitting procedure done here additionally gives
% me rates, and a significance test (See below).
[~,thetaEstimate] = max(ll,[],1);
thetaEstimate(all(isnan(ll),1))=NaN;
kappas = find(~isnan(thetaEstimate));
nrKappas = length(kappas);
baseParms = NaN(2,nrKappas);
responseParms = NaN(2,nrKappas);
cumulative = cumsum(spikeCount);
for k=1:nrKappas
    tBase = (1:(thetaEstimate(kappas(k))+1))';
    if length(tBase) <3 ; continue;end
    [baseParms(:,k)] = polyfit(tBase, cumulative(tBase),1);    
    tResponse = ((thetaEstimate(kappas(k))+2):(kappas(k)+1))';
    if length(tResponse) <3 ; continue;end
    [responseParms(:,k)] = polyfit (tResponse,cumulative(tResponse),1);
  
end
% Find the maximum slope 
dSlopes =(responseParms(1,:) - baseParms(1,:));
if (p.Results.responseSign==0)
    dSlopes= abs(dSlopes);
elseif (p.Results.responseSign ==-1)
    dSlopes = -dSlopes;
end


[~,bestKappaIndex] = max(dSlopes);
bestKappa       = kappas(bestKappaIndex);
bestTheta       = thetaEstimate(kappas(bestKappaIndex));
latencyEstimate = bestTheta-1; % Subtract 1ms because time zero is the first index in spikeCount
peakEstimate    = bestKappa -1;
% C. Do a significance test by determingin whether the counts observed in
% the interval between theta and kappa could be a sample from a Poisson
% distribution with the rate determined by the best fitting linear
% approximation of the cumulative before theta.
pPoisson        = 1- poisscdf(cumulative(bestKappa)-cumulative(bestTheta),baseParms(1,bestKappaIndex)*(bestKappa-bestTheta));
baseRate        = baseParms(1,bestKappaIndex)*1000; % Estimated rates, based on best fit
responseRate    = responseParms(1,bestKappaIndex)*1000;% Estimated rates, based on best fit

if (sign(responseRate-baseRate)*p.Results.responseSign) ==-1
    % Excitation requested but only inhibition found.
    % or Inhibition requested and only excitation found.
    % In this case the least bad slope is found, but this is probably not 
    % what the user is after. 
    warning('sib:friedmanpriebe',['No appropriate response found with sign ' num2str(p.Results.responseSign)])    
end

% D. Debug only - show the process.
if (p.Results.graphics)
%     findfig ('Friedman Priebe Latency Estimation')
findfigs()
    clf
    subplot(2,2,1);
    prob  = ll; %1- (ll./repmat(max(ll,[],1),[size(ll,1) 1]));
    x = p.Results.minTheta:p.Results.maxKappa;
    y = p.Results.minTheta:p.Results.maxTheta;
    imagesc(x,y,prob(y,x))
    ylabel 'Theta'
    xlabel 'Kappa'
    title  'Likelihood'
    colorbar
    
    subplot(2,2,2);
    hold on
    cumulative = cumsum(spikeCount);
    t =length(spikeCount);
    h1= plot(1:t,spikeCount,'b.');
    h2 = plot(1:t,max(spikeCount).*cumulative/max(cumulative),'g'); %Scaled
    h3 = plot([bestTheta+1 bestTheta+1],[0 max(spikeCount)],'r');
    h4  = plot([bestKappa+1 bestKappa+1],[0 max(spikeCount)],'m');
    legend([h1 h2 h3 h4],'Count','Cumulative','Theta','Kappa','Location','NorthWest');
    xlabel 'Time (ms)'
    ylabel 'SpikeCount/Cumulative'
    subplot(2,2,3);
    hold on
    tBase = (1:(thetaEstimate(bestKappa)+1))';   
    bp = polyfit(tBase, cumulative(tBase),1);    
    tResponse = ((thetaEstimate(bestKappa)+2):(bestKappa+1))';
    rp  = polyfit (tResponse,cumulative(tResponse),1);
    plot(tBase,cumulative(tBase),'.b');
    plot(tBase,polyval(bp,tBase),'b')        
     plot(tResponse,cumulative(tResponse),'r.');
     plot(tResponse,polyval(rp,tResponse),'r');
     title (['Latency: ' num2str(latencyEstimate) ' Peak: ' num2str(peakEstimate) 'Before vs After: (red/blue) p=' num2str(pPoisson)])
     xlabel 'Time (ms)'
     ylabel 'Cumulative Spike Count'
    suptitle ('Press any key to continue...')
%     disp('Press any key to continue...')
%      pause
end

end

% Function lambda1 (equation 3)
function v = lambda1(spikecount,theta)
v = sum(spikecount(1:(theta+1)))/(theta+1);
end
% The function lambda_2 (equation 2)
function v = lambda2(spikeCount,theta,kappa)
v= sum(spikeCount((theta+2):(kappa+1)))./(kappa-theta);
end
% Local implementation of factorial to skip time consuming error checking
% and use Stirling approximaton when needed
function v = locfactorial(n)
    useApprox   = n> 20;    
    v(useApprox) = stirling(n(useApprox));
    v(~useApprox) = fastfactorial(n(~useApprox));
end
% Stirling approximation of log(n!) for large n.
function v= stirling(n)
v = n.*log(n) -n +0.5*(log(n)+log(2*pi));
end

function  v= fastfactorial(n)
% Same as Matlab factorial except that it does not check that n is 
% integer, >=0, double and real (this checking takes most of the time).
N = n(:);
n(N>170) = 171;
m = max([1; n(:)]);
N = [1 1 cumprod(2:m)];
v = N(n+1);
end