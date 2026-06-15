function [gpLFP, gpPhi] = eventGP(o, varargin)

% Adapted from trialGP — generalized phase representation of LFP aligned
% to multiple events within each trial.
%
% Implements the Generalized Phase method of Davis & Muller (2020)
% https://doi.org/10.1038/s41586-020-2802-y
% Requires the generalized-phase toolbox: https://github.com/mullerlab/generalized-phase
%
% Calls eventLFP and applies bandpass filtering + generalized phase per
% channel per trial, across all events in that trial.
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
%   fk          - [fmin fmax] frequency range in Hz for bandpass (default: [5 40])
%   fs          - sampling rate in Hz (default: 1e3)
%
% Output:
%   gpLFP - cell array {nCh x nTr}, each cell is [nevents x nSamples]
%   gpPhi - same size as gpLFP, generalized phase angle in radians
%
% 2026-06-15 - Maureen Hagan <maureen.hagan@monash.edu>

p = inputParser();
p.KeepUnmatched = true;
p.addParameter('channels',    [], @(x) isnumeric(x) || isempty(x));
p.addParameter('bn',          [0, 1000]);
p.addParameter('eventonsets', []);
p.addParameter('trind',       []);
p.addParameter('fk',          [5, 40], @isnumeric);
p.addParameter('fs',          1e3,     @isnumeric);

p.parse(varargin{:});
args = p.Results;

if numel(args.fk) ~= 2
    error('fk must be a two-element vector [fmin fmax]')
end

Lfp = eventLFP(o, 'channels', args.channels, 'bn', args.bn, ...
    'eventonsets', args.eventonsets, 'trind', args.trind);

if ~iscell(Lfp), Lfp = {Lfp}; end

nCh = size(Lfp, 1);
nTr = size(Lfp, 2);

gpLFP = cell(nCh, nTr);
gpPhi = cell(nCh, nTr);

filter_order = 4;
lp = 0;

for ich = 1:nCh
    for itr = 1:nTr
        seg = Lfp{ich, itr};   % [nevents x nSamples]
        if isempty(seg), continue; end
        filtered = bandpass_filter(seg, args.fk(1), args.fk(2), filter_order, args.fs);
        phi      = generalized_phase(filtered, args.fs, lp);
        gpLFP{ich, itr} = filtered;
        gpPhi{ich, itr} = angle(phi);
    end
end

if nCh == 1
    gpLFP = squeeze(gpLFP);
    gpPhi = squeeze(gpPhi);
end

end
