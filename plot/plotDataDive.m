function plotDataDive(o,varargin)

% plots a whole bunch of laminar spike-phase figures for an mdbase object
% from maureen's data dive 23/05/15, saves them to savefilepath

% this was written for cuesaccade data - but can be used as an exmaple script of
% how to use a bunch of the functions in this repository. 

p = inputParser();
p.KeepUnmatched = true;
p.addParameter('channelOrder',[],@(x) isnumeric(x) || isempty(x));
p.addParameter('savefilepath',[],@(x) isnumeric(x) || isempty(x));
p.parse(varargin{:});

args = p.Results;

date_str = [o.path{1}(end-9:end-6) '_' o.path{1}(end-4:end-3) '_' o.path{1}(end-1:end)];

if isempty(args.channelOrder)
    channelOrder = o.spikes.chanIds;
else
    channelOrder = args.channelOrder; % shallow < > deep
end

% Future functions use channels as array indices so must always be 1:64
% (using electrodes 65:128 cause code to break)
channelOrder = find(channelOrder == channelOrder);

subject = o.subject;
paradigm = o.paradigm;

%% plot psths

% cuedind = o.cueOn & o.complete; % & d.targetloc == d.theta;
% uncuedind = ~o.cueOn & o.complete; % & d.targetloc == d.theta;
% 
% cuedSp = trialSpike(o,'onset','sTarget','trind', cuedind, 'bn',[-300,500]);
% uncuedSp = trialSpike(o,'onset','sTarget','trind', uncuedind, 'bn',[-300,500]);
% 
% uncued_colour = [0 114 178]./255; %blue
% cueIn_colour = [0 158 115]./255; %green
% 
% figure('Position',[0 0 600 5000]); 
% for icell = 1:numel(channelOrder)
%     
%     cell = channelOrder(icell);
%     rate1 = psth(cuedSp{cell}, [-300,500], 10);
%     rate2 =  psth(uncuedSp{cell}, [-300,500], 10);
%     subplot(4,round(numel(channelOrder)/4),icell)
%     hold on;
%     plot(rate1,'-','Linewidth',1,'Color',cueIn_colour),
%     plot(rate2,'-','Linewidth',1,'Color',uncued_colour),
%     
%     ymax = max([rate1 rate2]) + 2;
%     
%     set(gca,'XTick', 100:200:800);
%     set(gca,'XTickLabel', {'-200','0','200','400'});
%     set(gca,'YTick',  0:10:50);
%     set(gca,'FontName', 'Helvetica', 'FontAngle','normal','FontSize',10);
%     set(gca,'TickDir', 'out');
%     set(gca,'TickLength', [0.03,0.035]);
%     axis([0 800 0 ymax])
%     
% end
% 
% xlabel('Time from target onset')
% ylabel('Firing rate (sp/s)')
% 
% if ~isempty(args.savefilepath)
% print([args.savefilepath date_str '_cuedvsuncuedpsths.png'],'-dpng')
% end

% %% step 4 - get spike times and calc spike-phase relationships - generalized phase method
% 
% % spikephase = trialSpikeLFPPhase(o,'onset','sTarget','trind', o.complete, 'bn',[-500,500],'method','GP','fk',[5, 40]);
% spikephase = trialSpikeLFPPhase(o,'bn',[0,1000],'method','GP','fk',[5,40]);
% spikephase = squeeze(spikephase);
% % plot it...
% 
% SPI = nan(numel(channelOrder),numel(channelOrder)); % spike phase index (circ_r)
% PMP = nan(numel(channelOrder),numel(channelOrder)); % preferred mean phase (circ_m)
% 
% % now we want to do this ordered by depth
% for icell = 1:numel(channelOrder)
%     cellind = channelOrder(icell);
%     for ilfp = 1:numel(channelOrder)
%         lfpind = channelOrder(ilfp); 
%         if ~isempty([spikephase{cellind,lfpind}{:}])
%         SPI(icell,ilfp) = circ_r([spikephase{cellind,lfpind}{:}]');
%         PMP(icell,ilfp) = circ_mean([spikephase{cellind,lfpind}{:}]');
%         disp(['icell = ' num2str(icell) ' lfp = ' num2str(ilfp) ' cicmean = ' num2str(PMP(icell,ilfp))])
%         end
%     end
% end
% 
% figure; 
% subplot(1,2,1)
% imagesc(SPI,[0, 0.1]), colorbar
% map = colorcet( 'L03' ); colormap(gca,map)
% axis square
% title('Spike Phase Index')
% ylabel('Multiunits by depth')
% xlabel('LFPs by depth')
% 
% subplot(1,2,2) 
% imagesc(PMP), colorbar
% map = colorcet( 'C2' ); colormap(gca, circshift( map, [ 28, 0 ] ) )
% axis square
% title('Phase Mean Angle')
% ylabel('Multiunits by depth')
% xlabel('LFPs by depth')
% 
% if ~isempty(args.savefilepath)
% print([args.savefilepath date_str '_' subject '_' paradigm '_ZacSpikePhasebyDepth.png'],'-dpng')
% end


%% use multitaper - test different frequency bands

% spikephase = trialSpikeLFPPhase(o,'onset','sTarget', 'bn',[-500,500],'method','MT','tapers',[0.5,10],'fk',[4 12 20 40]);
% spikephase = trialSpikeLFPPhase(o,'bn',[0,1000],'method','MT','tapers',[0.5,10],'fk',[4 12 20 40]);
spikephase = trialSpikeLFPPhase(o,'bn',[0,1000],'method','MT','tapers',[0.5,10],'fk',4);
spikephase = squeeze(spikephase);

array = marmodata.cfgs.acute.H64FlexiH64FlexiIntan();
channelOrder = array.electrode{1,1}.chanMap;

nfreq = 4;
SPI = nan(nfreq, numel(channelOrder),numel(channelOrder)); % spike phase index (circ_r)
PMP = nan(nfreq, numel(channelOrder),numel(channelOrder)); % preferred mean phase (circ_m)

% now we want to do this ordered by depth

for ifreq = 1:4
    for icell = 1:numel(channelOrder)
        cellind = channelOrder(icell);
        for ilfp = 1:numel(channelOrder)
            lfpind = channelOrder(ilfp);
            if ~isempty([spikephase{ifreq,cellind,lfpind}{:}])
                SPI(ifreq,icell,ilfp) = circ_r([spikephase{ifreq,cellind,lfpind}{:}]');
                PMP(ifreq,icell,ilfp) = circ_mean([spikephase{ifreq,cellind,lfpind}{:}]');
            end
        end
    end
end
% plot it
titles = {'Theta 4Hz', 'Alpha 12Hz', 'Beta 20Hz', 'Gamma 40Hz'};
% scale = [0.2 0.2 0.2 0.2];

figure; 
for ifreq = 1:4
subplot(2,2,ifreq)
imagesc(squeeze(SPI(ifreq,:,:))), colorbar
map = colorcet( 'L03' ); colormap(gca,map)
axis square
ylabel('Multiunits by depth')
xlabel('LFPs by depth')
title(titles{ifreq});
end

if ~isempty(args.savefilepath)
print([args.savefilepath date_str '_' subject '_' paradigm '_Multitaper_all_freqs_SPI.png'],'-dpng')
end


figure; 
for ifreq = 1:4
subplot(2,2,ifreq)
imagesc(squeeze(PMP(ifreq,:,:))), colorbar
map = colorcet( 'C2' ); colormap(gca, circshift( map, [ 28, 0 ] ) )
axis square
ylabel('Multiunits by depth')
xlabel('LFPs by depth')
title(titles{ifreq});
end

if ~isempty(args.savefilepath)
print([args.savefilepath date_str '_' subject '_' paradigm '_Multitaper_all_freqs_PMP.png'],'-dpng')
end
