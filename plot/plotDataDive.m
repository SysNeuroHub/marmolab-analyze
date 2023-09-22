function plotDataDive(o,varargin)

% plots a whole bunch of laminar spike-phase figures for an mdbase object
% from maureen's data dive 23/05/15

% adjusted to be used for acute experiments 15/9/23

% Load data as follows:
% load("/home/marmolab/data2/2022/09/13/CJ223.motionStim.055339_MT.mdm",'-mat');
% then run plotDataDive(d)

p = inputParser();
p.KeepUnmatched = true;
p.parse(varargin{:});

%% Multitaper - test different frequency bands

spikephase = trialSpikeLFPPhase(o,'bn',[0,1000],'method','MT','tapers',[0.5,10],'fk',[4 12 20 40]);
spikephase = squeeze(spikephase);

% Import Intan array
array = input("Filepath for channel order:"); % marmodata.cfgs.acute.H64FlexiH64FlexiIntan();
channelOrder = array.electrode{1,1}.chanMap;

% Autofill SPI and PMP matrices to suit size of array
nfreq = 4;
SPI = nan(nfreq, numel(channelOrder),numel(channelOrder)); % spike phase index (circ_r)
PMP = nan(nfreq, numel(channelOrder),numel(channelOrder)); % preferred mean phase (circ_m)

% SPi + PMP ordered by depth
for ifreq = 1:4
    for icell = 1:numel(channelOrder)
        cellind = channelOrder(icell);
        for ilfp = 1:numel(channelOrder)
            lfpind = channelOrder(ilfp);
            if ~isempty([spikephase{ifreq,cellind,lfpind}{:}])
                SPI(ifreq, icell,ilfp) = circ_r([spikephase{ifreq,cellind,lfpind}{:}]');
                PMP(ifreq, icell,ilfp) = circ_mean([spikephase{ifreq,cellind,lfpind}{:}]');
            end
        end
    end
end

%% Plotting results

% Title lists
freqsList = {'Theta 4Hz', 'Alpha 12Hz', 'Beta 20Hz', 'Gamma 40Hz'};
shanksList = {'Shank 1','Shank 4','Shank 2','Shank 3',};

% Counter initialise
plotCount =1; % counts subplot #

% Plotting SPI results

figure();

for ifreq = 1:nfreq
    chanIndex = 1; % counts 1-64 in 16-electrode-increments for each shank
    shankCount = 1; % counts 1-4 for shank titles 
    
    while chanIndex < 65
        % Plot SPI
        sp(plotCount) = subplot(nfreq,length(shanksList),plotCount);
        imagesc(squeeze(SPI(ifreq,chanIndex:chanIndex+15,chanIndex:chanIndex+15))), colorbar
        
        % Plot features
        map = colorcet( 'L3' ); colormap(gca,map)
        axis square
        caxis([0,0.22])
        ylabel('Multiunits by depth');
        xlabel('LFPs by depth');
        title(shanksList{shankCount});
        
        % Increment counters
        chanIndex = chanIndex + 16;
        shankCount=shankCount+1;
        plotCount = plotCount + 1;
    end
end

% % Overarching frequency titles 
row_height = 0.1;
y_coords = [0.775,0.55,0.325,0.125];

for i = 1:length(freqsList)
    annotation('textbox',[0.03,y_coords(i),0.08,row_height],'String',freqsList{i},'EdgeColor','none','FontSize',14);
end


% Plotting PMP results

figure(); 

% Counter reset
plotCount =1; % counts subplot #

for ifreq = 1:nfreq
    chanIndex = 1; % counts 1-64 in 16-electrode-increments for each shank
    shankCount = 1; % counts 1-4 for shank titles 
    
    while chanIndex < 65
        % Plot SPI
        fprintf("Breaks at chanindex %d, shankCount %d, plotcount %d\n",chanIndex,shankCount,plotCount)
        subplot(nfreq,length(shanksList),plotCount)
        imagesc(squeeze(PMP(ifreq,chanIndex:chanIndex+15,chanIndex:chanIndex+15))), colorbar
        
        % Plot features
        map = colorcet( 'C2' ); colormap(gca, circshift( map, [ 28, 0 ] ) )
        axis square
        caxis([-pi,pi])
        ylabel('Multiunits by depth')
        xlabel('LFPs by depth')
        title(shanksList{shankCount});
        
        % Increment counters
        chanIndex = chanIndex + 16;
        shankCount=shankCount+1;
        plotCount = plotCount + 1;
    end
end


% % Overarching frequency titles 
row_height = 0.1;
y_coords = [0.775,0.55,0.325,0.125];

for i = 1:length(freqsList)
    annotation('textbox',[0.03,y_coords(i),0.08,row_height],'String',freqsList{i},'EdgeColor','none','FontSize',14);
end
