function spikephase = trialSpikeLFPPhase(o,varargin)

% returns the phase of the LFP at the time a spike occurs. This is based on
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
%   onset - time point to onset data to (ie target onset, stimulus onset, etc) default is trial start
%   onsetvector - maybe a way of inputing an optional alingment time points, like
%   saccade times, onseted to start of trial > make sure its in ms from
%   trial start!
%   trind = logical vector to tell which trials to use
%   bn - time bin around onset time
%   method - method for fitlering the LFP - 'GP' for generalized phase,
%   'MT' for multitaper (TBD!)
%   fk - frequency window for filtering the LFP, [min, max], Zac uses [5,
%   40] in his paper.
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
p.addParameter('method','GP',@(x) ischar(x) || isempty(x));
p.addParameter('fk',[5,40]); %, @(x) validateattributes(x,{'numeric'},{'positive','==',2))
p.addParameter('tapers',[0.5,10]); %, @(x) validateattributes(x,{'numeric'},{'positive','==',2))

p.parse(varargin{:});

args = p.Results;

Spike = trialSpike(o,'channels',args.channels,'onset',args.onset,'bn', args.bn, 'onsetvector',args.onsetvector,'trind',args.trind);

switch args.method
    case 'MT'
        error('sorry! i havent written this yet!')
    case 'GP'
    [~, lfpPhase] = trialGP(o,'channels',args.channels,'onset',args.onset,'bn', args.bn, 'onsetvector',args.onsetvector,'trind',args.trind);
end

nCell = length(Spike);
nLFP =  size(lfpPhase,1);
ntr = size(lfpPhase,2);

spikephase = cell(nCell, nLFP);

for icell = 1:nCell
    for ilfp = 1:nLFP
        for itr = 1:ntr
            spiketimes = round(Spike{icell}{itr})'; % spike times to the nearest ms
            spiketimes(spiketimes == 0) = 1; % cant have spiketime = 0
            spikephase{icell,ilfp}{itr} = squeeze(lfpPhase(ilfp,itr,spiketimes))';
        end
    end
end

end

