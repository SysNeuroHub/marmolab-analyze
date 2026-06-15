function spikephase = eventSpikeLFPPhase(o, varargin)

% Adapted from trialSpikeLFPPhase — returns the LFP phase at each spike
% time, aligned to multiple events within each trial.
%
% Based on the method in Hagan et al. (2022) https://doi.org/10.1038/s41586-022-04631-2
% and Davis et al. (2022) https://doi.org/10.1101/2022.10.26.513932
%
% Calls eventSpike and eventmtLFP (or eventGP), then looks up the LFP
% phase at the time of each spike within each event window.
%
% Input:
%   o = mdbase object with spiking and LFP data
%
% Optional arguments:
%   channels    - channels to use for both spikes and LFP (default: all)
%   eventonsets - cell array {1 x nTrials}, each cell a vector of event
%                 onset times in ms from trial start
%   trind       - logical trial-selection vector (default: o.complete)
%   bn          - [pre post] time window in ms (default: [0 1000])
%   method      - 'MT' for multitaper (default) or 'GP' for generalized phase
%   tapers      - [N W] for MT method (default: [0.5 10])
%   fk          - frequency (Hz) for MT, or [fmin fmax] for GP (default: 20)
%   fs          - sampling rate in Hz (default: 1e3)
%
% Output:
%   spikephase - cell array {nFreq x nCell x nLFP}
%                spikephase{ifreq, icell, ilfp}{itr}{iev} = vector of LFP
%                phase values (radians) at each spike time in that event
%
% 2026-06-15 - Maureen Hagan <maureen.hagan@monash.edu>

p = inputParser();
p.KeepUnmatched = true;
p.addParameter('channels',    [], @(x) isnumeric(x) || isempty(x));
p.addParameter('eventonsets', []);
p.addParameter('trind',       []);
p.addParameter('bn',          [0, 1000]);
p.addParameter('method',      'MT', @ischar);
p.addParameter('tapers',      [0.5, 10], @isnumeric);
p.addParameter('fk',          20,        @isnumeric);
p.addParameter('fs',          1e3,       @isnumeric);

p.parse(varargin{:});
args = p.Results;

% --- spikes ---
[spike, chan_ind, unit_ind] = eventSpike(o, 'channels', args.channels, ...
    'eventonsets', args.eventonsets, 'trind', args.trind, 'bn', args.bn);

% merge multi-unit per channel (mirrors trialSpikeLFPPhase)
nch   = numel(args.channels);
nTr   = numel(spike{1});
Spike = cell(1, nch);
if any(unit_ind > 1)
    uni_chan = unique(chan_ind);
    for ich = 1:nch
        Spike{ich} = cell(1, nTr);
        if ismember(ich, uni_chan)
            tmp = spike(chan_ind == ich);
            for iunit = 1:numel(tmp)
                for itr = 1:nTr
                    nevents = numel(tmp{iunit}{itr});
                    if numel(Spike{ich}{itr}) < nevents
                        Spike{ich}{itr} = cell(1, nevents);
                    end
                    for iev = 1:nevents
                        Spike{ich}{itr}{iev} = [Spike{ich}{itr}{iev}, tmp{iunit}{itr}{iev}];
                    end
                end
            end
        end
    end
else
    Spike = spike;
end

% --- LFP phase ---
switch args.method
    case 'MT'
        [~, lfpPhase] = eventmtLFP(o, 'channels', args.channels, ...
            'eventonsets', args.eventonsets, 'trind', args.trind, ...
            'bn', args.bn, 'tapers', args.tapers, 'fk', args.fk, 'fs', args.fs);
        nFreq = numel(args.fk);
    case 'GP'
        [~, lfpPhase] = eventGP(o, 'channels', args.channels, ...
            'eventonsets', args.eventonsets, 'trind', args.trind, ...
            'bn', args.bn, 'fk', args.fk, 'fs', args.fs);
        nFreq = 1;
    otherwise
        error('method must be ''MT'' or ''GP''')
end

% wrap single-channel output back into cell for uniform indexing
if ~iscell(lfpPhase), lfpPhase = {lfpPhase}; end

% if nFreq==1, eventmtLFP squeezes the freq dim; restore it for uniform indexing
if nFreq == 1 && strcmp(args.method, 'MT')
    lfpPhase = cellfun(@(x) reshape(x, [1, size(x)]), lfpPhase, 'UniformOutput', false);
end

nCell = numel(Spike);
nLFP  = numel(lfpPhase);          % total LFP channels in output

spikephase = cell(nFreq, nCell, nLFP);

for ifreq = 1:nFreq
    for icell = 1:nCell
        for ilfp = 1:nLFP
            spikephase{ifreq, icell, ilfp} = cell(1, nTr);
            for itr = 1:nTr
                nevents = numel(Spike{icell}{itr});
                spikephase{ifreq, icell, ilfp}{itr} = cell(1, nevents);
                for iev = 1:nevents
                    sptimes = round(Spike{icell}{itr}{iev})';
                    sptimes(sptimes < 1) = 1;
                    % lfpPhase{ilfp} is [nFreq x nevents x nSamples] (MT)
                    % or [nevents x nSamples] (GP)
                    if strcmp(args.method, 'MT')
                        phi_seg = squeeze(lfpPhase{ilfp}(ifreq, iev, :));
                    else
                        phi_seg = squeeze(lfpPhase{ilfp}(iev, :));
                    end
                    sptimes(sptimes > numel(phi_seg)) = numel(phi_seg);
                    spikephase{ifreq, icell, ilfp}{itr}{iev} = phi_seg(sptimes)';
                end
            end
        end
    end
end

end
