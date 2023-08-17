clc

addpath(genpath('~/Documents/code/marmolab/'))
addpath(genpath('~/Documents/git/neurostim/'))
addpath(genpath('~/Documents/git/marmolab-analyze/'))

dataloc = '~/home/marmolab/data2/2022/09/13/CJ223.motionStim.055339.mat'; % file contains stimulus info & points to data folder
saveloc = '~/home/marmolab/data2/2022/09/13/'; % destination filepath

suffix = '_MT'; % _V1 or _MT

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