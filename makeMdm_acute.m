function d = makeMdm_acute(varargin)

% function makeMdm_acute

% combine all files of a given task type on a partiuclar day, optional inputs to add spikes,
% lfp, eye data and export objec to mat file for easy access
% give channels to load. check if mdm file already exists,
% if so, dont need to reload channels. save after every channel so dont
% have to start over if it crashes. option to run analysis file

% NOTE: this requries the "new-args" branch of marmodata. Other branches of marmodata dont handle loading spikes and lfps simultaneously.
% the main changes in this branch are 
% 1. the 'lfp' argument is gone. ie instead of
%   loadArgs = {...,'spikes','true','source','ghetto',...}
% you now will jsut call
%    loadArgs = {...,'spikes','ghetto','lfp','raw',...}
% 2. a cfg file is required for loading neural data. because we're behind the rest
% of the lab, this will have to be supplied in loadArgs:
%   'marmodata.cfgs.mbi.A1x32_100um' for centre array 
%   'marmodata.cfgs.mbi.A1x32_Edge_100um' for edge array
% 3. 'loadEye' is now just 'eye'


% 2023-01-09 - original author for awake data Maureen Hagan <maureen.hagan@monash.edu>
% 2023-08-11 - adjustments for acute data made by Gretel Gibson-Bourke

p = inputParser();
p.KeepUnmatched = true;
p.addParameter('path','',@(x) ischar(x) || isempty(x)); % location of your data
p.addParameter('savesuffix','',@(x) ischar(x) || isempty(x)); % location of your data
p.addParameter('savepath','',@(x) ischar(x) || isempty(x)); % location of your mdm files
p.addParameter('channels',[]);
p.addParameter('spikes','', @(x)  ischar(x) || isempty(x));
p.addParameter('lfp','',@(x) ischar(x) || isempty(x));
p.addParameter('filtertype','multitaper',@(x) ischar(x) || isempty(x));
p.addParameter('cfg','',@(x) ischar(x) || isempty(x)); % 'marmodata.cfgs.mbi.A1x32_100um' for centre array 'marmodata.cfgs.mbi.A1x32_Edge_100um'
p.addParameter('reload',true,@(x) validateattributes(x,{'logical'},{'scalar'})); % eventually need to sort this out
p.addParameter('overwrite',true,@(x) validateattributes(x,{'logical'},{'scalar'})); % eventually need to sort this out

p.parse(varargin{:});

args = p.Results;

if isempty(args.path), error('must provide the data file and path!'), end

% step 1 - find the file

[path, name, ext] = fileparts(args.path);
filename = [name ext];

% file name to save out to:
if isempty(args.savepath)
    args.savepath = path;
end

assert(exist(args.cfg,'class') == 8,'''cfg'' must be the name of a valid ephys configuration, e.g., from marmodata.cfgs.');
d = marmodata.mdbase(filename,'path', path,'loadArgs',{'spikes',args.spikes,'lfp',args.lfp,'filtertype',args.filtertype,'channels',args.channels,'cfg',args.cfg,'reload', args.reload});
    fprintf(['returning ' args.spikes ' spikes and lfp data']);

save([path filesep name args.savesuffix '.mdm'],'d','-v7.3')
fprintf('everything saved!')