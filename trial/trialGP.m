function [gpLFP, gpPhi] = trialGP(o,varargin)

% implementation of the Generalized Phase (GP) method developed by Zac
% Davis and Lyle Muller in their 2020 Nature paper https://doi.org/10.1038/s41586-020-2802-y

% this file has a bunch of dependencies, all helpfully documented by Lyle
% Muller. 
% start here:
% https://github.com/mullerlab/generalized-phase
% and then use the ReadMe file to make sure you have all additional
% dependencies.
% run the demo gp_demo.m to make sure you have everything working

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
%   gpLfp - the filtered LFP
%   gpPhi - generalized phase angle of the LFP
%
% 2023-01-12 - Maureen Hagan <maureen.hagan@monash.edu>

p = inputParser();
p.KeepUnmatched = true;
p.addParameter('channels',[],@(x) isnumeric(x) || isempty(x));
p.addParameter('onset','',@(x) ischar(x) || isempty(x));
p.addParameter('bn',[0,1000]); %, @(x) validateattributes(x,{'numeric'},{'positive','==',2))
p.addParameter('onsetvector',[],@(x) validateattributes(x,{'numeric'},{'positive','>=',min(o.lfp.numTrials),'<=',max(o.lfp.numTrials)}));
p.addParameter('trind',[]); %, @(x) validateattributes(x,{'logical'}))
p.addParameter('fk',[5, 40],@(x) isnumeric(x)); % frequency, can also be a vector
p.addParameter('fs',1e3,@(x) isnumeric(x)); % sampling rate in ms


p.parse(varargin{:});

args = p.Results;

if numel(args.fk) ~= 2
    error('fk must be a vector of two numbers - the frequency range over which phase is estimated')
end

Lfp = trialLFP(o,'channels',args.channels,'onset',args.onset,'bn', args.bn, 'onsetvector',args.onsetvector,'trind',args.trind);

% parameters for GP
filter_order = 4; Fs = args.fs; lp = 0;  f = args.fk;% data filtered between 5 and 40 Hz
dt = 1 / Fs; T = size(Lfp,3) / Fs; %time = dt:dt:T;

% wideband filter
gpLFP = bandpass_filter( Lfp, f(1), f(2), filter_order, Fs );

% GP representation
gpPhi = generalized_phase( gpLFP, Fs, lp );

% convert to angle in radians
gpPhi = angle(gpPhi);

end

