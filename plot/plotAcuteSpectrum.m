

addpath(genpath('~/Documents/code/marmolab/'))
addpath(genpath('~/Documents/code/ephys/neurostim/'))
addpath(genpath('~/Documents/code/ephys/marmolab-analyze/'))

load('/Users/earsenau/Documents/code/ephys/corrStructure_V1MT/data/CJ223/001/CJ223.motionStim.055339_MT.mdm', '-mat');

lfp = trialLFP(d);
%%
clc;
X = squeeze(lfp(1,:,:));
tapers = [0.2 15];


[spec, f] = tfspec(X, tapers, d.lfp.fs, 0.03, [5 120]); %, pad, pval, flag);
%TFSPEC  Moving window time-frequency spectrum using multitaper techniques.
%
% [SPEC, F, ERR] = TFSPEC(X, TAPERS, SAMPLING, DN, FK, PAD, PVAL, FLAG, CONTFLAG, ERRORBAR) 
%
%  Inputs:  X		=  Time series array in [Space/Trials,Time] form.
%	    TAPERS 	=  Data tapers in [K,TIME], [N,P,K] or [N,W] form.
%			   	    [N,W] Form:  N = duration of analysis window in s.
%                                W = bandwidth of frequency smoothing in Hz.
%               Defaults to [N,3,5] where N is NT/10
%				and NT is duration of X. 
%               
%	    SAMPLING 	=  Sampling rate of time series X in Hz. 
%				Defaults to 1.
%	    DN		=  Overlap in time between neighbouring windows.
%			       	Defaults to N./10;
%	    FK 	 	=  Frequency range to return in Hz in
%                               either [F1,F2] or [F2] form.  
%                               In [F2] form, F1 is set to 0.
%			   	Defaults to [0,SAMPLING/2]
%	    PAD		=  Padding factor for the FFT.  
%			      	i.e. For N = 500, if PAD = 2, we pad the FFT 
%			      	to 1024 points; if PAD = 4, we pad the FFT
%			      	to 2048 points.
%				Defaults to 2.
%	   PVAL		=  P-value to calculate error bars for.
%				Defaults to 0.05 i.e. 95% confidence.
%
%	   FLAG = 0:	calculate SPEC seperately for each channel/trial.
%	   FLAG = 1:	calculate SPEC by pooling across channels/trials. 
%      CONTFLAG = 1; There is only a single continuous signal coming in.
%
%  Outputs: SPEC	=  Spectrum of X in [Space/Trials, Time, Freq] form. 
%	    F		=  Units of Frequency axis for SPEC.
%	    ERR 	=  Error bars in[Hi/Lo, Space, Time, Freq]  
%			   form given by the Jacknife-t or Chi2 interval for PVAL.
% 
%   See also DPSS, PSD, SPECGRAM.

%   Author: Bijan Pesaran, version date 15/10/98.
%               Optimized when not computing error bars.

%%
for condID = 1:36; 
iTrial = find(d.condIds == condID);
[nTrials, nT, nF] = size(spec);
if length(iTrial) > 1
    thisSpec= squeeze(mean(spec(iTrial, :, :)));
else 
    thisSpec= squeeze(spec(iTrial, :,:));
end
baseline = thisSpec(end, :);
baseline = repmat(baseline, [nT 1]);
subplot(6,6,condID)
tvimage(thisSpec./baseline);
xlabel('Time (ms)'); ylabel('Frequency (Hz)');
set(gca, 'XTick', linspace(0, nT, 5), ...
    'XTickLabel', linspace(0, 1000, 5), ...
    'YTick', 0:10:nF, ...
    'YTickLabel',round(f(1:10:nF)));
end
% tvimage(spec(1,:,:));

%%
iTrial = 79;
chs = [1 8 9 16 40 46 42 57];
for iCh = 1:length(chs)

    X = squeeze(lfp(chs(iCh),:,:));
tapers = [0.2 15];


[spec, f] = tfspec(X, tapers, d.lfp.fs, 0.03, [5 120]); %, pad, pval, flag);


[nTrials, nT, nF] = size(spec);
if length(iTrial) > 1
    thisSpec= squeeze(mean(spec(iTrial, :, :)));
else 
    thisSpec= squeeze(spec(iTrial, :,:));
end
baseline = thisSpec(end, :);
baseline = repmat(baseline, [nT 1]);
subplot(2,4,iCh);
tvimage(thisSpec./baseline);
title(chs(iCh));
xlabel('Time (ms)'); ylabel('Frequency (Hz)');
set(gca, 'XTick', linspace(0, nT, 5), ...
    'XTickLabel', linspace(0, 1000, 5), ...
    'YTick', 0:10:nF, ...
    'YTickLabel',round(f(1:10:nF)));
end