function [x, y] = trialEye(o,varargin)

%  loads x and y trace data for a trial, onseted to particular trial
%  timepoints
%
% Input:
%   o = mdbase object with Eye data
%
% Optional arguments:
%   onset - neurostim time point to align data to (ie target onset, stimulus onset, etc) default is trial start
%   onsetvector - a way of inputing an optional alingment time points, like
%   saccade times, aligned to start of trial > make sure its in ms from
%   trial start!
%   trind = logical vector to tell which trials to use
%   bn - time bin around onset time
%
% Output
%   [x,y, fs] - x and y traces in samples! make sure you check sampling
%   rate to project into time
%
% 2025-08-28 - Maureen Hagan <maureen.hagan@monash.edu>

% not sure the best way to deal with onsetments. in ns, stimuli and
% behaviours are a bit different. also, saccade times are something
% processed separaetly. to start, this will onset to onset of a simtulus
% and we'll go from there. if no onset given, will onset to firstFrame of
% the trial. 

% also = successful trials arent defined in the marmlab object. so optional
% vector input to account for this.


p = inputParser();
p.KeepUnmatched = true;
p.addParameter('onset','',@(x) ischar(x) || isempty(x));
p.addParameter('bn',[0,1000]); %, @(x) validateattributes(x,{'numeric'},{'positive','==',2))
p.addParameter('onsetvector',[],@(x) validateattributes(x,{'numeric'},{'positive','>=',min(o.lfp.numTrials),'<=',max(o.lfp.numTrials)}));
p.addParameter('removeBlinks',true,@(x) validateattributes(x,{'logical'},{'nonempty'}));
p.addParameter('trind',[]); % subset of trials to look at - vector with trial numbers

p.parse(varargin{:});

args = p.Results;

%find which trials to use
if isempty(args.trind)
    if isprop(o,'complete'), trind = o.complete;
    else, trind = true(1,o.numTrials);
    end
else, trind = args.trind;
end

% get an onset time in ms for each trial
if isempty(args.onsetvector)
    if ~isempty(args.onset)
    	onsets = (o.meta.(args.onset).startTime.time - o.meta.cic.firstFrame.time).*1e3; % onset time to the nearest ms
    else
        onsets = ones(1,o.numTrials);
    end
else, onsets = args.onsetvector;
end

start = (onsets(trind) + args.bn(1))./1e3; % convert back to seconds for eyetime %stop = round(onsets(trind)) + args.bn(2);

samplesperms = o.eye(1).fs/1e3;
nsamples = round((diff(args.bn)+1)*samplesperms);

x = nan(numel(trind),nsamples);
y = nan(numel(trind),nsamples);
        
        for itrial = 1:numel(trind)
            trial = trind(itrial);
            d2 = o.eye(trial);
            if args.removeBlinks
            d2 = rmBlinks(d2, 'dt', 0.400, 'interp', true, 'debug', false);
            end
            eyetime = d2.t; % eye trace time in ms
            % find the starting sample
            [~, startind] = min(abs(eyetime - start(itrial)));
            stopind = startind + nsamples - 1;

            x(itrial,:) = d2.x(startind:stopind);
            y(itrial,:) = d2.y(startind:stopind);
        end

end

