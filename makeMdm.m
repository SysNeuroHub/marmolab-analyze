function d = makeMdm(varargin)

% function makeMdm

% combine all files of a given task type on a partiuclar day, optional inputs to add spikes,
% lfp, eye data and export objec to mat file for easy access
% give channels to load. check if mdm file already exists,
% if so, dont need to reload channels. save after every channel so dont
% have to start over if it crashes. option to run analysis file

% NOTE: this requries the "new-args" branch of marmodata. Other branches of marmodata dont handle loading spikes and lfps simultaneously.
% the main changes in this branch are 
% 1. the 'source' argument is gone. ie instead of
%   loadArgs = {...,'spikes','true','source','ghetto',...}
% you now will jsut call
%    loadArgs = {...,'spikes','ghetto','lfp','raw',...}
% 2. a cfg file is required for loading neural data. because we're behind the rest
% of the lab, this will have to be supplied in loadArgs:
%   'marmodata.cfgs.mbi.A1x32_100um' for centre array 
%   'marmodata.cfgs.mbi.A1x32_Edge_100um' for edge array
% 3. 'loadEye' is now just 'eye'


% 2023-01-09 - Maureen Hagan <maureen.hagan@monash.edu>

p = inputParser();
p.KeepUnmatched = true;
p.addParameter('path','',@(x) ischar(x) || isempty(x)); % location of your data
p.addParameter('savepath','',@(x) ischar(x) || isempty(x)); % location of your mdm files
p.addParameter('subject','', @(x) ischar(x) || isempty(x));  % subject name
p.addParameter('paradigm','',@(x) ischar(x) || isempty(x)); % paradigm name 
p.addParameter('channels',[]);
p.addParameter('analysis','',@(x) ischar(x) || isempty(x));
p.addParameter('eye',false,@(x) validateattributes(x,{'logical'},{'scalar'}));
p.addParameter('spikes','', @(x)  ischar(x) || isempty(x));
p.addParameter('lfp','',@(x) ischar(x) || isempty(x));
p.addParameter('filtertype','multitaper',@(x) ischar(x) || isempty(x));
p.addParameter('cfg','',@(x) ischar(x) || isempty(x)); % 'marmodata.cfgs.mbi.A1x32_100um' for centre array 'marmodata.cfgs.mbi.A1x32_Edge_100um'
p.addParameter('reload',true,@(x) validateattributes(x,{'logical'},{'scalar'})); % eventually need to sort this out
p.addParameter('overwrite',true,@(x) validateattributes(x,{'logical'},{'scalar'})); % eventually need to sort this out
p.addParameter('force',false,@(x) validateattributes(x,{'logical'},{'scalar'})); % eventually need to sort this out

p.parse(varargin{:});

args = p.Results;

if isempty(args.path), error('must provide a path location for the data!'), end
if isempty(args.subject), error('must provide a subject!'), end
if isempty(args.paradigm), error('must provide a paradigm!'), end

% step 1 - find all of the files for a given task on on a given day.

Files = dir([args.path filesep args.subject '.' args.paradigm '.*' '.mat']); 

filenames = cell(1,numel(Files));
for ifile = 1:numel(Files)
    filenames{ifile} = Files(ifile).name;
end

% file name to save out to:
if isempty(args.savepath)
    args.savepath = args.path;
end

if strcmp(args.spikes,'kilo')
    savefilename = [args.savepath filesep args.subject '.' args.paradigm  '.kilo.mdm']; % save name > for sorted data
else
    savefilename = [args.savepath filesep args.subject '.' args.paradigm  '.mdm']; % save name
end

% old method doesnt work for mulitple files - new branch should allow us to
% do it at once... let see how it goes...

% ns file only
if ~args.eye && isempty(args.spikes) && isempty(args.lfp)
    d = marmodata.mdbase(filenames,'path', args.path);
    fprintf('returning ns file only!')
end

% eye data only
if args.eye && isempty(args.spikes) && isempty(args.lfp)
%     d = marmodata.mdbase(filenames,'path', args.path,'loadArgs',{'loadEye',args.eye});
    d = marmodata.mdbase(filenames,'path', args.path,'loadArgs',{'eye',args.eye});
    fprintf('returning eye and ns data only!')
end

% spiking only
if args.eye && ~isempty(args.spikes) && isempty(args.lfp)
    assert(exist(args.cfg,'class') == 8,'''cfg'' must be the name of a valid ephys configuration, e.g., from marmodata.cfgs.');
     
    d = marmodata.mdbase(filenames,'path', args.path,'loadArgs',{'eye',args.eye,'spikes',args.spikes,'channels',args.channels,'cfg',args.cfg,'reload', args.reload});
    fprintf(['returning ' args.spikes ' spikes'])
end

% lfp only
if args.eye && isempty(args.spikes) && ~isempty(args.lfp)
    assert(exist(args.cfg,'class') == 8,'''cfg'' must be the name of a valid ephys configuration, e.g., from marmodata.cfgs.');
     
    d = marmodata.mdbase(filenames,'path', args.path,'loadArgs',{'eye',args.eye,'lfp',args.lfp,'filtertype',args.filtertype,'channels',args.channels,'cfg',args.cfg,'reload', args.reload});
    fprintf('returning lfp data')
end

% everything (preferable!)
if args.eye && ~isempty(args.spikes) && ~isempty(args.lfp)
      assert(exist(args.cfg,'class') == 8,'''cfg'' must be the name of a valid ephys configuration, e.g., from marmodata.cfgs.');
      d = marmodata.mdbase(filenames,'path', args.path,'loadArgs',{'eye',args.eye,'spikes',args.spikes,'lfp',args.lfp,'filtertype',args.filtertype,'channels',args.channels,'cfg',args.cfg,'reload', args.reload,'force',args.force});
    fprintf(['returning ' args.spikes ' spikes and lfp data'])
end

% if exist(savefilename,'file')% if it already exits, load it so you dont have to do everything again
%     load(savefilename, '-mat', 'd'); 
% else
%     d = marmodata.mdbase(filenames,'path', args.path);
% end 
% 
% % step 2 - load the behaviour
% 
% if args.loadEye
%     d = d.load('loadEye',args.loadEye);
%     
%     save(savefilename,'d')
%     disp('behaviour saved!')
% end
% 
% % step 3 - if kilo, load spike data
% 
% if args.spikes && strcmp(args.source,'kilo')
%     d = d.load('spikes',args.spikes,'source','kilo');
%     save(savefilename,'d')
%     disp('kilo spike data saved!')
% end
% 
% % step 4 load lfps (and possibly spikes ghetto) channel by channel
% 
% if ~isempty(args.channels)
%     channels = args.channels;
% 
%     if args.spikes && strcmp(args.source,'ghetto')
%         d = d.load('spikes',args.spikes,'source','ghetto','channels',channels,'reload', args.reload);
%         save(savefilename,'d')
%         disp('ghetto spike data saved!')
%     end
%     
%     if args.lfp
%         d = d.load('lfp',args.lfp,'channels',channels,'reload', args.reload);
%         save(savefilename,'d')
%         disp('lfp data saved!')
%     end
%     
%     % nice idea but this doesnt work
% %     for ich = 1:numel(channels)
% %         channel = channels(ich);
% %         
% %         if args.spikes && strcmp(args.source,'ghetto')
% %             d = d.load('spikes',args.spikes,'source','ghetto','channels',channel,'reload', args.reload);
% %             save(savefilename,'d')
% %             disp(['ghetto spike data for ch ' num2str(channel) ' saved!'])
% %         end
% %         
% %         if args.lfp 
% %             d = d.load('lfp',args.lfp,'channels',channel,'reload', args.reload);
% %             save(savefilename,'d')
% %             disp(['lfp data for ch ' num2str(channel) ' saved!'])
% %         end
% %     end
% end


% step 5: run the analysis file for the day

if ~isempty(args.analysis)
    d = feval(args.analysis, d);
    fprintf('analysis file run!')
end

save(savefilename,'d','-v7.3')
fprintf('everything saved!')