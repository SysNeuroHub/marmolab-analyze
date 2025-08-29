function spikephase = trialSpikeLFPPhase(o,varargin)

% returns the phase of the LFP (in radians) at the time a spike occurs. This is based on
% the method used in Maureen's paper https://doi.org/10.1038/s41586-022-04631-2

% but is also used to find spike-LFP relationships across depth as shown in
% in Zac Davis' paper: bioRxiv https://doi.org/10.1101/2022.10.26.513932
% this uses the generalized phase method of filtering the LFP. see trialGP
% for more info

% because you get one phase per spike per LFP, the output is a cell array
% number of cells x number of LFPs

% To do > should write something to give the
% option of susbset of channels.

%
% Input:
%   o = mdbase object with Spiking and LFP data
%
% Optional arguments:
%   channels - channels to load LFP data for (defaut: o.lfp.numChannels)
%   onset - neurostim time point to align data to (ie target onset, stimulus onset, etc) default is trial start
%   onsetvector - a way of inputing an optional alingment time points, like
%   saccade times, aligned to start of trial > make sure its in ms from
%   trial start!
%   trind = logical vector to tell which trials to use
%   bn - time bin around onset time
%   method - method for fitlering the LFP - 'GP' for generalized phase,
%   'MT' for multitaper. defaults to 'MT' 
%   fk - for generalized phase - frequency window for filtering the LFP, [min, max], Zac uses [5,
%   40] in his paper. for multitaper, can be a vector of freqencies to
%   test. defaults to 20 hz
%   tapers - [N, W], if using multitaper, need frequency smoothing and time
%   window

%
% Output
%   spikephase - the phase of the LFP at the time of the spike
%
% 2023-01-12 - Maureen Hagan <maureen.hagan@monash.edu>

p = inputParser();
p.KeepUnmatched = true;
p.addParameter('channels',[],@(x) isnumeric(x) || isempty(x));
p.addParameter('onset','',@(x) ischar(x) || isempty(x));
p.addParameter('bn',[0,1000]); %, @(x) validateattributes(x,{'numeric'},{'positive','==',2))
p.addParameter('onsetvector',[],@(x) validateattributes(x,{'numeric'},{'positive','>=',min(o.lfp.numTrials),'<=',max(o.lfp.numTrials)}));
p.addParameter('trind',[]); %, @(x) validateattributes(x,{'logical'}))

% for LFP
p.addParameter('method','MT',@(x) ischar(x) || isempty(x)); % altneratively 'MT'
% parameters for mt filter
p.addParameter('tapers',[0.5,10],@(x) isnumeric(x)); % tapers [time (s), frequency smoothing (Hz)]
p.addParameter('fk',20,@(x) isnumeric(x)); % frequency, can also be a vector
p.addParameter('fs',1e3,@(x) isnumeric(x)); % sampling rate in ms


p.parse(varargin{:});

args = p.Results;

[spike, chan_ind, unit_ind] = trialSpike(o,'channels',args.channels,'onset',args.onset,'bn', args.bn, 'onsetvector',args.onsetvector,'trind',args.trind);

% hack for kilosorted data... this is sort of ugly. maybe we want to change this later. right
% now, make a 'multiunit' for each channel - should still be cleaner
% because its sorted? 
Spike = cell(1,numel(args.channels));
ntr = numel(spike{1});
if sum(unit_ind > 1) % kilosorted data with more than one spike per channel
    uni_chan = unique(chan_ind);
    for ich = 1:numel(args.channels)
        for itr = 1:ntr
            Spike{ich} = cell(1,ntr);
            if ismember(ich,uni_chan)
                tmp = spike(chan_ind == ich);
                for iunit = 1:numel(tmp)
                    Spike{ich}{itr} = [Spike{ich}{itr} spike{iunit}{itr}];
                end
            end
        end
    end
else
    Spike = spike;
end

switch args.method
    case 'MT'
        [~, lfpPhase] = trialmtLFP(o,'channels',args.channels,'onset',args.onset,'bn', args.bn, 'onsetvector',args.onsetvector,'trind',args.trind, 'tapers',args.tapers,'fk',args.fk,'fs',args.fs);
        nFreq = numel(args.fk);
    case 'GP'
        [~, lfpPhase] = trialGP(o,'channels',args.channels,'onset',args.onset,'bn', args.bn, 'onsetvector',args.onsetvector,'trind',args.trind,'fk',args.fk,'fs',args.fs);
        nFreq = 1;
end



if nFreq == 1, lfpPhase = reshape(lfpPhase, [1, size(lfpPhase,1), size(lfpPhase,2), size(lfpPhase,3)]); end

nCell = length(Spike);
nLFP =  size(lfpPhase,2);
ntr = size(lfpPhase,3);

% spikephase = cell(nCell, nLFP);
spikephase = cell(nFreq, nCell, nLFP);

for ifreq = 1:nFreq
    for icell = 1:nCell
        for ilfp = 1:nLFP
            for itr = 1:ntr
                spiketimes = round(Spike{icell}{itr})'; % spike times to the nearest ms
                spiketimes(spiketimes == 0) = 1; % cant have spiketime = 0
                spikephase{ifreq,icell,ilfp}{itr} = squeeze(lfpPhase(ifreq,ilfp,itr,spiketimes))';
            end
        end
    end
end

end

