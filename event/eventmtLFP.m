function [mtLFP, mtPhi] = eventmtLFP(o, varargin)

% Adapted from trialmtLFP — multitaper-filtered LFP aligned to multiple
% events within each trial.
%
% Calls eventLFP and applies mtfilter per channel, per trial, across all
% events in that trial (treating each event as an independent segment).
%
% Input:
%   o = mdbase object with LFP data
%
% Optional arguments:
%   channels    - channels to load (default: o.lfp.chanIds)
%   eventonsets - cell array {1 x nTrials}, each cell a vector of event
%                 onset times in ms from trial start
%   trind       - logical trial-selection vector (default: o.complete)
%   bn          - [pre post] time window in ms (default: [0 1000])
%   tapers      - [N W] multitaper params: window duration (s) and
%                 bandwidth (Hz) (default: [0.5 10])
%   fs          - sampling rate in Hz (default: 1e3)
%   fk          - frequency or vector of frequencies to filter at (Hz)
%                 (default: 20)
%
% Output:
%   mtLFP - cell array {nCh x nTr}, each cell is [nFreq x nevents x nSamples]
%   mtPhi - same size as mtLFP, phase angle in radians
%
% 2026-06-15 - Maureen Hagan <maureen.hagan@monash.edu>

p = inputParser();
p.KeepUnmatched = true;
p.addParameter('channels',    [], @(x) isnumeric(x) || isempty(x));
p.addParameter('bn',          [0, 1000]);
p.addParameter('eventonsets', []);
p.addParameter('trind',       []);
p.addParameter('tapers',      [0.5, 10], @isnumeric);
p.addParameter('fs',          1e3,       @isnumeric);
p.addParameter('fk',          20,        @isnumeric);

p.parse(varargin{:});
args = p.Results;

Lfp = eventLFP(o, 'channels', args.channels, 'bn', args.bn, ...
    'eventonsets', args.eventonsets, 'trind', args.trind);

% wrap scalar output (single channel) back into a cell for uniform handling
if ~iscell(Lfp), Lfp = {Lfp}; end

nCh    = size(Lfp, 1);
nTr    = size(Lfp, 2);
nFreq  = numel(args.fk);

mtLFP = cell(nCh, nTr);
mtPhi = cell(nCh, nTr);

for ich = 1:nCh
    for itr = 1:nTr
        seg = Lfp{ich, itr};          % [nevents x nSamples]
        if isempty(seg), continue; end
        nevents  = size(seg, 1);
        nSamples = size(seg, 2);
        mtLFP{ich, itr} = nan(nFreq, nevents, nSamples);
        mtPhi{ich, itr} = nan(nFreq, nevents, nSamples);
        for iF = 1:nFreq
            filtered = mtfilter(seg, args.tapers, args.fs, args.fk(iF), 0, 1);
            mtLFP{ich, itr}(iF, :, :) = filtered;
            mtPhi{ich, itr}(iF, :, :) = atan2(imag(filtered), real(filtered));
        end
    end
end

if nFreq == 1
    mtLFP = cellfun(@(x) squeeze(x), mtLFP, 'UniformOutput', false);
    mtPhi = cellfun(@(x) squeeze(x), mtPhi, 'UniformOutput', false);
end

if nCh == 1
    mtLFP = squeeze(mtLFP);
    mtPhi = squeeze(mtPhi);
end

end
