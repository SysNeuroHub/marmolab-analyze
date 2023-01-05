% function makeMdm
% This will take 5-10 minutes for 96 channels * 30 minutes of data

p = '/home/marmolab/data/2022/10/25/';
s = 'CJ228.oriXYZ.204629_221025_204713'; % add in Intan data directory
f = 'CJ228.oriXYZ.204629.mat'; %noisegrid.021523.mat';

ch = 1:128; %[1:128]; % 1:3; %1:96; %[1:64 97:128]; %65:67;
% cfg = 'marmodata.cfgs.acute.neuropix';
cfg = 'marmodata.cfgs.acute.H64FlexiH64FlexiIntan';

tic
d = marmodata.mdbase([p f],'loadArgs', ...
    {'loadEye',false,'spikes',true,'source','intan', ... % source - ghetto / intan
    'reload',true,'cfg',cfg,'channels',ch,'useCAR',false}); %,'saveDir',s});
toc

out = [p f(1:end-4) '.mdm']; % save name
save(out,'d')
disp('saved!')