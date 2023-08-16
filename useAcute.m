clc

addpath(genpath('~/Documents/code/marmolab/'))
addpath(genpath('~/Documents/code/ephys/neurostim/'))
addpath(genpath('~/Documents/code/ephys/marmolab-analyze/'))

dataloc = '~/Documents/code/ephys/corrStructure_V1MT/data/CJ223/001/CJ223.motionStim.055339.mat';
saveloc = '~/Documents/code/ephys/corrStructure_V1MT/data/CJ223/001/';

suffix = '_MT';

switch suffix
    case '_MT'
        ch = 65:128;
    case '_V1'
        ch = 1:64;
    otherwise 
        ch = 1;
end        
        
d= makeMdm_acute('path', dataloc, 'savepath', saveloc, ...
               'channels', ch, 'spikes', 'ghetto', 'lfp', ...
               'raw', 'cfg', 'marmodata.cfgs.acute.H64FlexiH64FlexiIntan',...
               'savesuffix', suffix);