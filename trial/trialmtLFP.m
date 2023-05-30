function [mtLFP, mtPhi] = trialmtLFP(o,varargin)

% bandpass filtered LFP using multi-taper methods

%  loads lfp data for a trial, onseted to particular trial
%  timepoints, and filters it to a frequency or frequency range based on a
%  given set of tapers
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
% multi taper inputs:
%   tapers - Data tapers in [K,TIME], [N,P,K] or [N,W] form. Defaults to
%   [.5,10] which is a 500 ms window with 10 Hz frequency smoothing.
%     fs - sampling rate in ms. defaults to 1e3
%     fk - frequency or frequency range. defaults to 20 Hz can also be a
%     vector to test multiple frequencies.
% 
%
% Output
%   mtLfp - the filtered LFP
%   mtPhi - phase angle of the LFP
%
% 2023-03-06 - Maureen Hagan <maureen.hagan@monash.edu>

p = inputParser();
p.KeepUnmatched = true;
p.addParameter('channels',[],@(x) isnumeric(x) || isempty(x));
p.addParameter('onset','',@(x) ischar(x) || isempty(x));
p.addParameter('bn',[0,1000]); %, @(x) validateattributes(x,{'numeric'},{'positive','==',2))
p.addParameter('onsetvector',[],@(x) validateattributes(x,{'numeric'},{'positive','>=',min(o.lfp.numTrials),'<=',max(o.lfp.numTrials)}));
p.addParameter('trind',[]);

% parameters for mt filter
p.addParameter('tapers',[0.5,10],@(x) isnumeric(x)); % tapers
p.addParameter('fs',1e3,@(x) isnumeric(x)); % sampling rate in ms
p.addParameter('fk',20,@(x) isnumeric(x)); % frequency. can also be a vector to test a range of frequncies.


p.parse(varargin{:});

args = p.Results;

Lfp = trialLFP(o,'channels',args.channels,'onset',args.onset,'bn', args.bn, 'onsetvector',args.onsetvector,'trind',args.trind);

% multitaper filter
mtLFP = nan(numel(args.fk),size(Lfp,1),size(Lfp,2),size(Lfp,3));
mtPhi = nan(numel(args.fk),size(Lfp,1),size(Lfp,2),size(Lfp,3));
for iF = 1:numel(args.fk)
    for ich = 1:size(Lfp,1)
        mtLFP(iF,ich,:,:) = mtfilter(squeeze(Lfp(ich,:,:)),args.tapers,args.fs,args.fk(iF),0,1);
        mtPhi(iF,ich,:,:) = atan2(imag(squeeze(mtLFP(iF,ich,:,:))),real(squeeze(mtLFP(iF,ich,:,:))));
    end
end

if numel(args.fk) == 1
    mtLFP = squeeze(mtLFP);
    mtPhi = squeeze(mtPhi);
end

end

