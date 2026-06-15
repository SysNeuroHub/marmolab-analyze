function [latencyEstimate, peakEstimate, pPoisson, baseRate, responseRate] = eventSpikeLatency(o, varargin)

% Adapted from trialSpikeLatency — estimates response latency when there
% are multiple events per trial (e.g. repeated stimulus presentations).
%
% Aggregates spike times across all events from all trials into a single
% PSTH, then applies the Friedman-Priebe latency estimator
% (Friedman & Priebe, J Neurosci Methods 83:185, 1998).
% See also: marmolab-analyze/utils/friedmanpriebe.m
%
% This treats every event as an independent repeat of the same stimulus.
% If events are heterogeneous (e.g. saccades to different directions),
% consider sub-selecting eventonsets before calling this function.
%
% Input:
%   o = mdbase object with spiking data
%
% Optional arguments:
%   channels    - channels to analyse (default: o.spikes.chanIds)
%   eventonsets - cell array {1 x nTrials}, each cell a vector of event
%                 onset times in ms from trial start
%   trind       - logical trial-selection vector (default: o.complete)
%   bn          - [pre post] time window in ms; latency is estimated from
%                 bn(1) to bn(2). Use [0 500] to start counting from the
%                 event onset (default: [0 500])
%   minTheta    - earliest possible latency in ms (default: 2)
%   maxTheta    - latest possible onset (default: diff(bn)-2)
%   maxKappa    - latest possible peak (default: diff(bn)-1)
%   delta       - minimum gap between onset and peak (default: 1)
%   responseSign - 1 = increases only, -1 = decreases only, 0 = both
%                  (default: 0)
%
% Output:
%   latencyEstimate - [1 x nCh] estimated response latency in ms
%   peakEstimate    - [1 x nCh] estimated time of peak response in ms
%   pPoisson        - [1 x nCh] p-value vs baseline (Poisson test)
%   baseRate        - [1 x nCh] pre-onset firing rate
%   responseRate    - [1 x nCh] firing rate from onset to peak
%
% 2026-06-15 - Maureen Hagan <maureen.hagan@monash.edu>

p = inputParser();
p.KeepUnmatched = true;
p.addParameter('channels',     [], @(x) isnumeric(x) || isempty(x));
p.addParameter('eventonsets',  []);
p.addParameter('trind',        []);
p.addParameter('bn',           [0, 500]);
p.addParameter('minTheta',     2,  @isnumeric);
p.addParameter('maxTheta',     [], @(x) isnumeric(x) || isempty(x));
p.addParameter('maxKappa',     [], @(x) isnumeric(x) || isempty(x));
p.addParameter('delta',        1,  @isnumeric);
p.addParameter('responseSign', 0,  @(x) ismember(x, [-1 0 1]));

p.parse(varargin{:});
args = p.Results;

if isempty(args.eventonsets)
    error('please provide the events you want aligned to')
end

if isempty(args.channels)
    args.channels = o.spikes.chanIds;
end

if isempty(args.maxTheta), args.maxTheta = diff(args.bn) - 2; end
if isempty(args.maxKappa), args.maxKappa = diff(args.bn) - 1; end

% get spikes for all events across all trials
Spike = eventSpike(o, 'channels', args.channels, ...
    'eventonsets', args.eventonsets, 'trind', args.trind, 'bn', args.bn);

if ~iscell(Spike{1})   % single channel — wrap
    Spike = {Spike};
end

nCh = numel(Spike);

latencyEstimate = nan(1, nCh);
peakEstimate    = nan(1, nCh);
pPoisson        = nan(1, nCh);
baseRate        = nan(1, nCh);
responseRate    = nan(1, nCh);

e = 0:1:diff(args.bn);   % 1 ms bins for PSTH

for ich = 1:nCh
    % aggregate spike times across all trials and all events
    allspikes = [];
    for itr = 1:numel(Spike{ich})
        for iev = 1:numel(Spike{ich}{itr})
            allspikes = [allspikes, Spike{ich}{itr}{iev}]; %#ok<AGROW>
        end
    end

    if isempty(allspikes), continue; end

    spikecount = histcounts(allspikes, e);

    [latEst, peakEst, pval, bRate, rRate] = friedmanpriebe(spikecount', ...
        'minTheta',     args.minTheta, ...
        'maxTheta',     args.maxTheta, ...
        'maxKappa',     args.maxKappa, ...
        'delta',        args.delta, ...
        'responseSign', args.responseSign);

    latencyEstimate(ich) = latEst;
    peakEstimate(ich)    = peakEst;
    pPoisson(ich)        = pval;
    baseRate(ich)        = bRate;
    responseRate(ich)    = rRate;
end

end
