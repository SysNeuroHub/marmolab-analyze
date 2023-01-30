function d = makeMdm(varargin)

% function makeMdm

% combine all files of a given task type on a partiuclar day, optional inputs to add spikes,
% lfp, eye data and export objec to mat file for easy access
% give channels to load. check if mdm file already exists,
% if so, dont need to reload channels. save after every channel so dont
% have to start over if it crashes. option to run analysis file

% TODO: 
% handle multiple files of the same paradigm
% check for exisiting MDM file, load it and pick up where left off
% deal with reload 

% 2023-01-09 - Maureen Hagan <maureen.hagan@monash.edu>

p = inputParser();
p.KeepUnmatched = true;
p.addParameter('path','',@(x) ischar(x) || isempty(x)); % location of your data
p.addParameter('subject','', @(x) ischar(x) || isempty(x));  % subject name
p.addParameter('paradigm','',@(x) ischar(x) || isempty(x)); % paradigm name 
p.addParameter('channels',[]);
p.addParameter('analysis','',@(x) ischar(x) || isempty(x));
p.addParameter('loadEye',true,@(x) validateattributes(x,{'logical'},{'scalar'}));
p.addParameter('spikes',true,@(x) validateattributes(x,{'logical'},{'scalar'}));
p.addParameter('source','ghetto',@(x) ischar(x) || isempty(x));
p.addParameter('lfp',true,@(x) validateattributes(x,{'logical'},{'scalar'}));
p.addParameter('reload',true,@(x) validateattributes(x,{'logical'},{'scalar'})); % eventually need to sort this out

p.parse(varargin{:});

args = p.Results;

if isempty(args.path), error('must provide a path location for the data!'), end
if isempty(args.subject), error('must provide a subject!'), end
if isempty(args.paradigm), error('must provide a paradigm!'), end

% step 1 - find all of the files for a given task on on a given day.

Files = dir([args.path filesep args.subject '.' args.paradigm '*' '.mat']); 

filenames = cell(1,numel(Files));
for ifile = 1:numel(Files)
    filenames{ifile} = Files(ifile).name;
    
end

% file name to save out to:
if strcmp(args.source,'kilo')
    savefilename = [args.path filesep args.subject '.' args.paradigm  '.kilo.mdm']; % save name > for sorted data
else
    savefilename = [args.path filesep args.subject '.' args.paradigm  '.mdm']; % save name
end

if exist(savefilename,'file')% if it already exits, load it so you dont have to do everything again
    load(savefilename, '-mat', 'd'); 
else
    d = marmodata.mdbase(filenames,'path', args.path);
end 

% step 2 - load the behaviour

if args.loadEye
    d = d.load('loadEye',args.loadEye);
    
    save(savefilename,'d')
    disp('behaviour saved!')
end

% step 3 - if kilo, load spike data

if args.spikes && strcmp(args.source,'kilo')
    d = d.load('spikes',args.spikes,'source','kilo');
    save(savefilename,'d')
    disp('kilo spike data saved!')
end

% step 4 load lfps (and possibly spikes ghetto) channel by channel

if ~isempty(args.channels)
    channels = args.channels;

    if args.spikes && strcmp(args.source,'ghetto')
        d = d.load('spikes',args.spikes,'source','ghetto','channels',channels,'reload', args.reload);
        save(savefilename,'d')
        disp('ghetto spike data saved!')
    end
    
    if args.lfp
        d = d.load('lfp',args.lfp,'channels',channels,'reload', args.reload);
        save(savefilename,'d')
        disp('lfp data saved!')
    end
    
    % nice idea but this doesnt work
%     for ich = 1:numel(channels)
%         channel = channels(ich);
%         
%         if args.spikes && strcmp(args.source,'ghetto')
%             d = d.load('spikes',args.spikes,'source','ghetto','channels',channel,'reload', args.reload);
%             save(savefilename,'d')
%             disp(['ghetto spike data for ch ' num2str(channel) ' saved!'])
%         end
%         
%         if args.lfp 
%             d = d.load('lfp',args.lfp,'channels',channel,'reload', args.reload);
%             save(savefilename,'d')
%             disp(['lfp data for ch ' num2str(channel) ' saved!'])
%         end
%     end
end


% step 5: run the analysis file for the day

if ~isempty(args.analysis)
    d = feval(args.analysis, d);
    save(savefilename,'d')
    disp('analysis file run and saved!')
end
