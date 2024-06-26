function Rate = trialRate(o,varargin)

%  Returns the spike rate for a set of trials from an mdbase object over a
%  specified time bin
%
% Input:
%   o = mdbase object with LFP data
%
% Optional arguments:
%   channels - channels to load data for (defaut: o.spike.numChannels)
%   onset - neurostim time point to align data to (ie target onset, stimulus onset, etc) default is trial start
%   onsetvector - a way of inputing an optional alingment time points, like
%   saccade times, aligned to start of trial > make sure its in ms from
%   trial start!
%   trind = logical vector to tell which trials to use
%   bn - time bin around onset time
%
% Output
%   Rate - a vector array of spike rates in spikes/sec for each trial over
%   the specififed time window
%
% 2023-01-10 - Maureen Hagan <maureen.hagan@monash.edu>

% not sure the best way to deal with onsetments. in ns, stimuli and
% behaviours are a bit different. also, saccade times are something
% processed separaetly. to start, this will onset to onset of a simtulus
% and we'll go from there. if no onset given, will onset to firstFrame of
% the trial. 

% also = successful trials arent defined in the marmolab object. so optional
% vector input to account for this.


p = inputParser();
p.KeepUnmatched = true;
p.addParameter('channels',[],@(x) isnumeric(x) || isempty(x)); %validateattributes(x,{'numeric'},{'positive','>=',min(o.spikes.numChannels),'<=',max(o.spikes.numChannels)}));
p.addParameter('onset','',@(x) ischar(x) || isempty(x));
p.addParameter('bn',[0,1000]); %, @(x) validateattributes(x,{'numeric'},{'positive','==',2))
p.addParameter('onsetvector',[]); %,@(x) validateattributes(x,{'numeric'},{'positive','>=',min(o.spikes.numTrials),'<=',max(o.spikes.numTrials)}));
p.addParameter('trind',[]); %, @(x) validateattributes(x,{'logical'}))

p.parse(varargin{:});

args = p.Results;

if isempty(args.channels)
    channels = 1:o.spikes.numChannels;
else
    channels = args.channels;
end

%find which trials to use
if isempty(args.trind)
    if isprop(o,'complete'), trind = o.complete;
    else, trind = true(1,o.spikes.numTrials);
    end
else, trind = args.trind;
end

spikes = trialSpike(o,'onset',args.onset,'trind', trind, 'channels', channels, 'bn',args.bn, 'onsetvector', args.onsetvector);

if numel(spikes) == 1 
    Spikes{1} = spikes;
else
    Spikes = spikes;
end

numChan = numel(Spikes);
numTrial = numel(Spikes{1});
% covert trial spikes to a rate (channels, trials)
Rate = nan(numChan,numTrial);

bn = args.bn;

for ich = 1:numChan
    for itr = 1:numTrial
        ind = Spikes{ich}{itr};
        Rate(ich,itr) = length(ind)./diff(bn).*1e3;
    end
end

if numel(channels) == 1 
    Rate = squeeze(Rate);
end

