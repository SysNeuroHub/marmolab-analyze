function [Spike] = trialSpike(o,varargin)

%  loads spike data across trials, onseted to particular trial
%  timepoints
%
% Input:
%   o = mdbase object with LFP data
%
% Optional arguments:
%   channels - channels to load LFP data for (defaut: o.lfp.numChannels)
%   onset - time point to onset data to (ie target onset, stimulus onset, etc) default is trial start
%   onsetvector? - maybe a way of inputing an optional alingment, like
%   saccade times
%   trind = logical vector to tell which trials to use
%   bn - time bin around onset time
%
% Output
%   spike - a cell array of spike times in ms for each trial
%
% 2023-01-05 - Maureen Hagan <maureen.hagan@monash.edu>

% not sure the best way to deal with onsetments. in ns, stimuli and
% behaviours are a bit different. also, saccade times are something
% processed separaetly. to start, this will onset to onset of a simtulus
% and we'll go from there. if no onset given, will onset to firstFrame of
% the trial. 

% also = successful trials arent defined in the marmolab object. so optional
% vector input to account for this.


p = inputParser();
p.KeepUnmatched = true;
p.addParameter('channels',[],@(x) isnumeric(x) || isempty(x));
p.addParameter('units',[],@(x) isnumeric(x) || isempty(x));
p.addParameter('onset','',@(x) ischar(x) || isempty(x));
p.addParameter('bn',[0,1000]); %, @(x) validateattributes(x,{'numeric'},{'positive','==',2))
p.addParameter('onsetvector',[],@(x) validateattributes(x,{'numeric'},{'positive','>=',min(o.spikes.numTrials),'<=',max(o.spikes.numTrials)}));
p.addParameter('trind',[]); %, @(x) validateattributes(x,{'logical'}))

p.parse(varargin{:});

args = p.Results;

if isempty(args.channels)
    args.channels = 1:o.spikes.numChannels;
end

% get indexes for all channels/units
tmp = squeeze(any(cellfun(@(x) ~isempty(x),o.spikes.spk),2));
[all_units,all_channels] = ind2sub(size(tmp),find(tmp));
chanlist = o.spikes.chanIds(all_channels);
ix = ismember(chanlist,args.channels);

chan_ind = all_channels(ix); unit_ind = all_units(ix);

% find the overalp with requested channels

%find which trials to use
if isempty(args.trind)
    if isprop(o,'complete'), trind = o.complete;
    else, trind = true(1,o.spikes.numTrials);
    end
else, trind = args.trind;
end

% get an onset time in ms for each trial
if isempty(args.onsetvector)
    if ~isempty(args.onset)
    	onsets = o.meta.(args.onset).startTime.time - o.meta.cic.firstFrame.time; % onset time to the nearest s
    else
        onsets = ones(1,o.spikes.numTrials);
    end
else, onsets = args.onsetvector;
end
onsets = onsets(trind);

Spike = cell(1,numel(chan_ind));

trials = 1:o.spikes.numTrials;
trials = trials(trind);
bn = args.bn./1e3;

for ich = 1:numel(chan_ind)
    channel = chan_ind(ich);
    unit = unit_ind(ich);
    Spike{ich} = cell(1,sum(trind));
    for itr = 1:numel(trials)
        trial = trials(itr);
        start = onsets(itr) + bn(1);
        timestamps = o.spikes.spk{unit,trial,channel} - start;
        Spike{ich}{itr} = timestamps(timestamps > 0 & timestamps < diff(bn)).*1e3; % convert to ms at the last minute 
        % can do better with channels - deal with later
    end
end

if numel(chan_ind) == 1 
    Spike = Spike{1};
end

end

