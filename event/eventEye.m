function [x, y] = eventEye(o, varargin)

% Adapted from trialEye — aligns eye traces to multiple events within each
% trial (e.g. each saccade onset).
%
% Output traces are in the native eye-tracker sample space; use
% o.eye(1).fs to convert to ms.
%
% Input:
%   o = mdbase object with eye data
%
% Optional arguments:
%   eventonsets  - cell array {1 x nTrials}, each cell a vector of event
%                  onset times in ms from trial start
%   trind        - logical trial-selection vector (default: o.complete)
%   bn           - [pre post] time window in ms relative to each event
%                  onset (default: [0 1000])
%   removeBlinks - remove blink artefacts via rmBlinks (default: true)
%
% Output:
%   x - cell array {1 x nTr}, each cell is [nevents x nSamples]
%   y - cell array {1 x nTr}, each cell is [nevents x nSamples]
%
% 2026-06-15 - Maureen Hagan <maureen.hagan@monash.edu>

p = inputParser();
p.KeepUnmatched = true;
p.addParameter('eventonsets',  [],   @(x) ~isempty(x));
p.addParameter('trind',        []);
p.addParameter('bn',           [0, 1000]);
p.addParameter('removeBlinks', true, @(x) islogical(x));

p.parse(varargin{:});
args = p.Results;

if isempty(args.eventonsets)
    error('please provide the events you want the eye trace aligned to')
end

if isempty(args.trind)
    if isprop(o, 'complete'), trind = o.complete;
    else, trind = true(1, o.numTrials);
    end
else
    trind = args.trind;
end

trials   = find(trind);
numTrial = numel(trials);

samplesperms = o.eye(1).fs / 1e3;
nSamples     = round((diff(args.bn) + 1) * samplesperms);

x = cell(1, numTrial);
y = cell(1, numTrial);

for itr = 1:numTrial
    trial   = trials(itr);
    onsets  = args.eventonsets{trial};
    nevents = numel(onsets);

    d2 = o.eye(trial);
    if args.removeBlinks
        d2 = rmBlinks(d2, 'dt', 0.400, 'interp', true, 'debug', false);
    end
    eyetime = d2.t;  % time vector in seconds

    x{itr} = nan(nevents, nSamples);
    y{itr} = nan(nevents, nSamples);

    for iev = 1:nevents
        onset_s  = (onsets(iev) + args.bn(1)) / 1e3;  % convert ms to s
        [~, startind] = min(abs(eyetime - onset_s));
        stopind = startind + nSamples - 1;
        if stopind <= numel(d2.x)
            x{itr}(iev, :) = d2.x(startind:stopind);
            y{itr}(iev, :) = d2.y(startind:stopind);
        end
    end
end

end
