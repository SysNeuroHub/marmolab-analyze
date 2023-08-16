clc

addpath(genpath('~/Documents/code/marmolab/'))
addpath(genpath('~/Documents/code/ephys/neurostim/'))
addpath(genpath('~/Documents/code/ephys/marmolab-analyze/'))

dataloc = '~/Documents/code/ephys/corrStructure_V1MT/data/CJ223/001/CJ223.motionStim.055339.mat';
saveloc = '~/Documents/code/ephys/corrStructure_V1MT/data/CJ223/001/';

d= makeMdm_acute('path', dataloc, 'savepath', saveloc, ...
               'channels', 65:128, 'spikes', 'ghetto', 'lfp', ...
               'raw', 'cfg', 'marmodata.cfgs.acute.H64FlexiH64FlexiIntan',...
               'savesuffix', '_MT');