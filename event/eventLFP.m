function [Lfp] = eventLFP(o, varargin)

% Adapted from trialLFP — aligns LFP segments to multiple events within
% each trial (e.g. saccades, stimulus presentations).
%
% Input:
%   o = mdbase object with LFP data
%
% Optional arguments:
%   channels    - channels to load (default: o.lfp.chanIds)
%   eventonsets - cell array {1 x nTrials}, each cell a vector of event
%                 onset times in ms from trial start
%   trind       - logical trial-selection vector (default: o.complete)
%   bn          - [pre post] time window in ms relative to each event onset
%                 (default: [0 1000])
%
% Output:
%   Lfp - cell array {nCh x nTr}, each cell is [nevents x nSamples]
%         NaN rows indicate events too close to a trial edge
%
% 2026-06-15 - Maureen Hagan <maureen.hagan@monash.edu>

p = inputParser();
p.KeepUnmatched = true;
p.addParameter('channels',    [], @(x) isnumeric(x) || isempty(x));
p.addParameter('bn',          [0, 1000]);
p.addParameter('eventonsets', []);
p.addParameter('trind',       []);

p.parse(varargin{:});
args = p.Results;

if isempty(args.eventonsets)
    error('please provide the events you want the LFP aligned to')
end

if isempty(args.channels)
    channels = o.lfp.chanIds;
else
    channels = args.channels;
end

ix       = ismember(o.lfp.chanIds, channels);
chan_ind = find(ix);

lfps = o.lfp.get;   % [nSamples x nTrials x nCh]

if isempty(args.trind)
    if isprop(o, 'complete'), trind = o.complete;
    else, trind = true(1, o.lfp.numTrials);
    end
else
    trind = args.trind;
end

trials   = find(trind);
numTrial = numel(trials);
nSamples = diff(args.bn) + 1;

Lfp = cell(numel(chan_ind), numTrial);

for ich = 1:numel(chan_ind)
    ch = chan_ind(ich);
    for itr = 1:numTrial
        trial   = trials(itr);
        onsets  = args.eventonsets{trial};
        nevents = numel(onsets);
        trlfp   = squeeze(lfps(:, trial, ch));  % [nSamples]
        Lfp{ich, itr} = nan(nevents, nSamples);
        for iev = 1:nevents
            start = round(onsets(iev)) + args.bn(1);
            stop  = start + nSamples - 1;
            if start >= 1 && stop <= numel(trlfp)
                Lfp{ich, itr}(iev, :) = trlfp(start:stop)';
            end
        end
    end
end

if numel(chan_ind) == 1
    Lfp = squeeze(Lfp);
end

end
