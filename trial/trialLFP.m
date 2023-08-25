function [Lfp] = trialLFP(o,varargin)

%  loads lfp data for a trial, onseted to particular trial
%  timepoints
%
% Input:
%   o = mdbase object with LFP data
%
% Optional arguments:
%   channels - channels to load LFP data for (defaut: o.lfp.numChannels)
%   onset - neurostim time point to align data to (ie target onset, stimulus onset, etc) default is trial start
%   onsetvector - a way of inputing an optional alingment time points, like
%   saccade times, aligned to start of trial > make sure its in ms from
%   trial start!
%   trind = logical vector to tell which trials to use
%   bn - time bin around onset time
%
% Output
%   Lfp - the local field potential signal(s) (mV?) in ms [NCH, TRIAL,TIME] or [TRIAL,TIME]
%
% 2023-01-03 - Maureen Hagan <maureen.hagan@monash.edu>

% not sure the best way to deal with onsetments. in ns, stimuli and
% behaviours are a bit different. also, saccade times are something
% processed separaetly. to start, this will onset to onset of a simtulus
% and we'll go from there. if no onset given, will onset to firstFrame of
% the trial. 

% also = successful trials arent defined in the marmlab object. so optional
% vector input to account for this.


p = inputParser();
p.KeepUnmatched = true;
p.addParameter('channels',[],@(x) isnumeric(x) || isempty(x));
p.addParameter('onset','',@(x) ischar(x) || isempty(x));
p.addParameter('bn',[0,1000]); %, @(x) validateattributes(x,{'numeric'},{'positive','==',2))
p.addParameter('onsetvector',[],@(x) validateattributes(x,{'numeric'},{'positive','>=',min(o.lfp.numTrials),'<=',max(o.lfp.numTrials)}));
p.addParameter('trind',[]); 

p.parse(varargin{:});

args = p.Results;

if isempty(args.channels)
    channels = o.lfp.chanIds; 
else
    channels = args.channels;
end

ix = ismember(o.lfp.chanIds,channels);
chan_ind = 1:o.lfp.numChannels;
chan_ind = chan_ind(ix); 

lfps = o.lfp.get; % trials x samples > will need resizing for more than one channel

%find which trials to use
if isempty(args.trind)
    if isprop(o,'complete'), trind = o.complete;
    else, trind = true(1,o.lfp.numTrials);
    end
else, trind = args.trind;
end

% Idea to check lfps variable for NaNs (in trialLFP function)
% [w,l,h] = size(lfps);
% for i = 1:l
%     [w,l,h] = size(lfps);
%     while w > 0  
%         if sum(isnan(lfps(w,l,:))) == 0
%             lowest(i) = width;
%             w = 0;
%         end
%         w = w - 1;
%     end
% end

% get an onset time in ms for each trial
if isempty(args.onsetvector)
    if ~isempty(args.onset)
    	onsets = (o.meta.(args.onset).startTime.time - o.meta.cic.firstFrame.time).*1e3; % onset time to the nearest ms
    else
        onsets = ones(1,o.lfp.numTrials);
    end
else, onsets = args.onsetvector;
end

start = round(onsets(trind)) + args.bn(1); stop = round(onsets(trind)) + args.bn(2);

% error checkpoint: is window bigger than trial time?
if max(stop) > o.lfp.numSamples ||  min(start) < 1
    error('your window is bigger than your trial!') 
end

% if numel(chan_ind) == 1
%     Lfp(1,:,:) = lfps(start:stop,trind)';
% else
    Lfp = nan(numel(chan_ind), sum(trind), diff(args.bn)+1);
    for ich = 1:numel(chan_ind)
        ch = chan_ind(ich);
        trlfp = squeeze(lfps(:,trind,ch))';
        Lfp(ich,:,:) = trlfp(:,start:stop); 
    end
% end

end

