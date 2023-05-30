function [latencyEstimate,peakEstimate,pPoisson,baseRate,responseRate] = trialSpikeLatency(o,varargin)

% returns the estimated latency of spiking response using the method described by Friedman and Priebe in
% J Neurosci Methods 83:185 (1998).
% in the lab, this was used in Feizpour (2021) https://doi.org/10.1152/jn.00581.2020

% this is a mdbase wrapper for the function written by Bart - see
% marmolab-analyze/utils/friedmanpreibe.m

%
% Input:
%   o           =   mdbase object with Spiking data
%
% Optional arguments:
% for the mdbase object:
%   channels    =  channels to load spiking data for (defaut: o.lfp.numChannels)
%   onset       =   neursotim time point to align onset data to (ie target onset, stimulus onset, etc) default is trial start
%   onsetvector =   a way of inputing an optional alingment time points, like
%                   saccade times, onseted to start of trial > make sure its in ms from
%                   trial start!
%   trind       =   logical vector to tell which trials to use
%   bn          =   time bin around onset time. for latency estimation, first time bin
%                   is the point at which latency calculation begins, so should start with
%                   0 if you want to start counting from your alignment time (ie target
%                   onset). Defaults to [0,500];
% for the latency estimation:
%   minTheta   =    The first time index at which a response may have
%                   started (in ms). Defaults to 2.
%   maxTheta   =    The last time index at which a response may have
%                   started (in ms). Defaults to bn(2).
%   maxKappa   =    Last index at which the peak of the response could be.
%                   Defaults to bn(2).
%   delta      =    The minimum time between response onset and sustained
%                   onset.
% responseSign =    Set to 1 to detect only increases in firing
%                   Set to -1 to detect only decreases in firing
%                   Set to 0 to detect both increases and decreases in
%                   firing (Default)
%
% Output
% latencyEstimate = The estimated latency in milliseconds.
% peakEstimate    = Estimation of the time at which the response goes
%                       from the transient level to the sustained
% pPoisson        = p-value of the test whether the response in the estimated
%                   window between latency and peak is significantly
%                   different from the response in the window before the
%                   response onset. (Assuming Poisson firing).
% baseRate        = firing rate in before onset
% responseRate    = firing rate in the window from onset to peak.

% 2023-04-24 - Maureen Hagan <maureen.hagan@monash.edu>

p = inputParser();
p.KeepUnmatched = true;
p.addParameter('channels',[],@(x) isnumeric(x) || isempty(x));
p.addParameter('onset','',@(x) ischar(x) || isempty(x));
p.addParameter('bn',[0,500]); %, @(x) validateattributes(x,{'numeric'},{'positive','==',2))
p.addParameter('onsetvector',[],@(x) validateattributes(x,{'numeric'},{'positive','>=',min(o.lfp.numTrials),'<=',max(o.lfp.numTrials)}));
p.addParameter('trind',[]); %, @(x) validateattributes(x,{'logical'}))

p.addParameter('minTheta',2,@isnumeric);
p.addParameter('maxTheta',[]);
p.addParameter('maxKappa',[]);
p.addParameter('delta',1,@isnumeric);
p.addParameter('responseSign',0,@(x) (ismember(x,[-1 0 1])));


p.parse(varargin{:});

args = p.Results;

if isempty(args.channels) % if empty, load everything
    args.channels = o.spikes.chanIds;
end


% get spikes
Spike = trialSpike(o,'channels',args.channels,'onset',args.onset,'bn', args.bn, 'onsetvector',args.onsetvector,'trind',args.trind);

if numel(args.channels) == 1
    Spike{1} = Spike;
end

latencyEstimate = nan(1,numel(args.channels));
peakEstimate = nan(1,numel(args.channels));
pPoisson = nan(1,numel(args.channels));
baseRate = nan(1,numel(args.channels));
responseRate = nan(1,numel(args.channels));

% get estimate for each channel
for ich = 1:numel(args.channels)
    
    % covert spikes to spike counts in 1 ms bins
    spikes = [];
    for itr = 1:length(Spike{ich})
        x = Spike{ich}{itr}';
        spikes = [spikes x];
    end
    e = 0:1:diff(args.bn); % 1 ms bins
    spikecount = histcounts(spikes,e);
    
    if isempty(args.maxTheta)
        args.maxTheta = diff(args.bn) - 2;
    end
    
    if isempty(args.maxKappa)
        args.maxKappa = diff(args.bn) - 1;
    end
    
    [latEst,peakEst,pval,bRate,rRate] = friedmanpriebe(spikecount','minTheta',args.minTheta,'maxTheta',args.maxTheta, ...
        'maxKappa',args.maxKappa,'delta',args.delta,'responseSign',args.responseSign);
    
    latencyEstimate(ich) = latEst;
    peakEstimate(ich) = peakEst;
    pPoisson(ich) = pval;
    baseRate(ich) = bRate;
    responseRate(ich) = rRate;
end

end
