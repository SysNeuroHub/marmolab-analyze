%% Relative phase method

% uncuedLFP = trialLFP(d,'channels',1:32,'trind', uncuedind, 'bn',[-500,500]); % run with the same inputs you put into the trialSpikePhase
spikephase = trialLFP(d,'bn',[0,1000]);
sortedLFP = uncuedLFP(channelOrder,:,:); % use your channel order for each shank

%% lets get the spectrum
N = 0.9; % duration of analysis window in s.
W = 2;   % bandwidth of frequency smoothing in Hz.
sampling = 1e3;
dn = N./10;
fk = 150;

uncuedSpec = nan(size(sortedLFP,1), 307);

for ich = 1:size(sortedLFP,1)
    uncuedSpec(ich,:) = squeeze(mean(tfspec(squeeze(sortedLFP(ich,:,:)), [N,W], sampling, dn, fk)))';
end

% now... for each frequency, find the max power across channels and
% nomralize by that.

[mxpwr,mxind] = max(uncuedSpec,[],1);

% figure; imagesc(squeeze(uncuedSpec(:,win,100:150)))

%     normSpec = squeeze(uncuedSpec(:,win,:))./mxpwr;
normSpec = uncuedSpec./mxpwr;

alpha_color = [0 0 1];
gamma_color = [1 0 0];
%%

yind = 8;
ch_str = cell(1,numel(channelOrder)/yind);
for ich = 1:numel(channelOrder)/yind
    ch_str{ich} = num2str(ich*yind);
end

uncued_colour = [0 114 178]./255; %blue

% plot just the indices - should look like a radical sign
figure;
plot(mxind,'LineWidth',2,'Color',uncued_colour)
set(gca, 'YDir','reverse')
set(gca,'YTick',  yind:yind:numel(channelOrder));
set(gca,'YTickLabel',  ch_str);
set(gca,'XTick',  30*2:30*2:fk*2);
set(gca,'XTickLabel',  {'30' '60' '90' '120' '150'});
set(gca,'FontName', 'Helvetica', 'FontAngle','normal','FontSize',12);
set(gca,'TickDir', 'out');
set(gca,'TickLength', [0.02,0.035]);
% title(day)
xlabel('Frequency (Hz)')
ylabel('Electrodes')
title('max power index')
axis([1 fk*2 1 numel(channelOrder)])
box off

figure('Position',[0 0 800 300]);

subplot(1,2,1)
imagesc(normSpec), c = colorbar('Ticks',0:0.2:1);
c.Label.String = 'Relative power';
c.FontSize = 12;

hold on;
line([10 30], [1 1],'LineWidth',3,'Color',alpha_color)
text(mean([10 30]), 0, 'alpha-beta','FontName','Helvetica', 'FontAngle','normal','FontSize',12,'HorizontalAlignment','center');

line([50 150], [1 1],'LineWidth',3,'Color',gamma_color)
text(mean([50 150]), 0, 'gamma','FontName','Helvetica', 'FontAngle','normal','FontSize',12,'HorizontalAlignment','center');

set(gca,'YTick',  yind:yind:numel(channelOrder));
set(gca,'YTickLabel',  ch_str);
set(gca,'FontName', 'Helvetica', 'FontAngle','normal','FontSize',12);
set(gca,'TickDir', 'out');
set(gca,'TickLength', [0.02,0.035]);
xlabel('Frequency (Hz)')
ylabel('Electrodes')
axis([1 150 1 numel(channelOrder)])
box off

% get the mean power over depth
alphapwr = mean(normSpec(:,10:30),2);
gammapwr = mean(normSpec(:,50:150),2);

%figure;
subplot(1,2,2)
hold on;
plot(alphapwr,1:1:numel(channelOrder),'-','Color',alpha_color,'Linewidth',1)
plot(gammapwr,1:1:numel(channelOrder),'-','Color',gamma_color,'Linewidth',1)

set(gca, 'YDir','reverse')
set(gca,'YTick',  1:yind:numel(channelOrder)-1);
set(gca,'YTickLabel',  ch_str(end:-1:1));
set(gca,'FontName', 'Helvetica', 'FontAngle','normal','FontSize',12);
set(gca,'TickDir', 'out');
set(gca,'TickLength', [0.02,0.035]);
xlabel('Relative Power')
ylabel('Electrodes')
axis([0 1 1 numel(channelOrder)])