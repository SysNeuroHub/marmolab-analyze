function Data = vonMisesFit(X, Ang, varargin)

% uses maximum likelihood estimation (mle) and a negative log likelihood function
% to estimate the parameters the von mises fit

% for significance, the function compares the fit to a constant poisson (a
% flat line)

% X is a linear variable (firing rate, reaction time, etc)
% Ang is the ciruclar variable in RADIANS (saccade direction, phase of lfp etc)


% optional inputs:
% phatnull_start/phatalt_start - starting point for the fit. if mle is
% having difficulty converging but you think there should be a fit, see
% vonMisesJitter and try to find more suitable start settings.
% baselinecomparison flag - logical, whether to do a baseline comparison
% (in the case of a negative tuning curve)
% gamma flag - logical, indicates whether to use a gamma distrubtion instead of poisson. this is more
% apporiate for data that is better described by a gamma distribution (ie
% reaction times)

p = inputParser();

p.addParameter('phatalt_start',[],@(x) validateattributes(x,{'numeric'}));
p.addParameter('phatnull_start',[],@(x) validateattributes(x,{'numeric'}));
p.addParameter('baselinecomparison',false,@(x) validateattributes(x,{'logical'},{'nonempty'}));
p.addParameter('gamma',false,@(x) validateattributes(x,{'logical'},{'nonempty'}));
p.addParameter('constrainmu',false,@(x) validateattributes(x,{'logical'},{'nonempty'})); % constrain mu to be near circular mean > requires circ stat toolbox!
p.addParameter('jitter',false,@(x) validateattributes(x,{'logical'},{'nonempty'})); % jitter data to try to converge mle
p.addParameter('jittersize',[],@(x) validateattributes(x,{'numeric'}));

p.parse(varargin{:});

args = p.Results;


%% fitting a von mises

% set some parameters for mle
options = statset('mlecustom');
options.GradObj = 'on';
options.MaxIter = 2e3;
options.MaxFunEvals = 4e3;

% Construct a negative log likelihood function for each xi
if args.gamma
    nloglf_alt = @(params,X,cens,freq) nloglfVonMisesGamma(params,X,cens,freq,Ang);
    nloglf_null = @(params,X,cens,freq) nloglfConstantGamma(params,X,cens,freq);
else
    nloglf_alt = @(params,data,cens,freq) nloglfVonMisesPoisson(params,data,cens,freq,Ang);
    nloglf_null = @(params,data,cens,freq) nloglfConstantPoisson(params,data);
end

% Choose parameter starting points
if isempty(args.phatalt_start)
    
    bins{1}(1,:) = [-pi,-pi+pi./4];
    bins{2}(1,:) = [-3*pi./4,-pi./2];
    bins{3}(1,:) = [-pi./2,-pi./4];
    bins{4}(1,:) = [-pi./4,0];
    bins{5}(1,:) = [0,pi./4];
    bins{6}(1,:) = [pi./4,pi./2];
    bins{7}(1,:) = [pi./2,3*pi./4];
    bins{8}(1,:) = [3*pi./4,pi];
    bin_axis=-pi+pi/8:pi/4:pi;
    
    x = calcTuningCurve(Ang,X, bins);
    
    A_start = median(x);
    B_start = max(x)-min(x);
    kappa_start = 1.5;
    [~,ind]=max(x);
    
    if args.constrainmu
        % use circ stat toolbox?
        mu = circ_mean(Ang);
        t = circ_confmean(Ang,0.2);
        mu_start = mu; 
        mu_range = [mu-t,mu+t];
    else
        mu_start = bin_axis(ind);
        mu_range = [-pi,pi];
    end
    
    
    A_range = [0.01 2000];
    B_range = [0.01 2000];
    kappa_range = [0.05,10]; % 10 is maybe too high of a max, was set to 2 for nature paper.

    
    % check to see if the most deviated bin is above or below the
    % median (if you suspect an inverted tuning curve)
    if args.baselinecomparison
        bins = -pi:pi/4:pi;
        nbins = length(bins)-1;
        binX = zeros(1,nbins);
        
        for ibn = 1:nbins
            start = bins(ibn);
            stop = bins(ibn)+1;
            
            binX(ibn) = mean(X(Ang>=start & Ang<stop));
        end
        Xdiff = abs(binX - A_start);
        [~, maxind] = max(Xdiff);
        if Xdiff(maxind) < 0
            B_start = min(x)-max(x); B_range = [ -2000 -0.01 ];
            
        end
    end
    
    start_setting = [A_start,B_start,kappa_start,mu_start];
    
    if args.gamma % gamma distribution has one extra parameter
        k_start = 20;
        k_range = [ 0.01 100];
        start_setting = [k_start,A_start,B_start,kappa_start,mu_start];
    end
else
    start_setting = args.phatalt_start;
end

if args.gamma
    lower_setting = [k_range(1) A_range(1) B_range(1) kappa_range(1) mu_range(1)];
    upper_setting = [k_range(2) A_range(2) B_range(2) kappa_range(2) mu_range(2)];
else
    lower_setting = [A_range(1) B_range(1) kappa_range(1) mu_range(1)];
    upper_setting = [A_range(2) B_range(2) kappa_range(2) mu_range(2)];
end

% fit parameters for the von mises
[phat_alt,pci_alt] = mle(X,'nloglf',nloglf_alt,'options',options,...
    'lowerbound',lower_setting,'upperbound',upper_setting,...
    'start',start_setting);

if args.jitter % check that the fit converged, if not, try jittering the data to get there
    if isnan(pci_alt)
        Datatmp = vonMisesJitter(X, Ang, 'gamma',args.gamma,'jittersize',args.jittersize,'baselinecomparison',args.baselinecomparison);
        start_setting = Datatmp.phat_alt; % find a better start setting for the mle
        [phat_alt,pci_alt] = mle(X,'nloglf',nloglf_alt,'options',options,...
            'lowerbound',lower_setting,'upperbound',upper_setting,...
            'start',start_setting);
    end
end

% fit for the null hypotheis (distrubiton is flat)
if isempty(args.phatnull_start)
    if args.gamma
        theta_start = var(X)./mean(X);
        k_start = mean(X)./theta_start;
        start_setting = [k_start theta_start];
        lower_setting = [0.01 0.01];
        upper_setting = [200 1000];
    else
        theta_start = mean(X);
        start_setting = theta_start;
        lower_setting = 0.01;
        upper_setting = 1000;
    end
else
    start_setting = args.phatnull_start;
end

[phat_null,pci_null] = mle(X,'nloglf',nloglf_null,'options',options,...
    'lowerbound',lower_setting,'upperbound',upper_setting,...
    'start',start_setting);

% test out the two fits on the data
if args.gamma
    val_alt = nloglfVonMisesGamma(phat_alt,X,[],[],Ang);
    val_null = nloglfConstantGamma(phat_null,X,[],[]);
else
    val_alt = nloglfVonMisesPoisson(phat_alt,X,[],[],Ang);
    val_null = nloglfConstantPoisson(phat_null,X);
end

if ~isnan(pci_alt)
    D = 2*(val_null-val_alt);
    pval = 1 - chi2cdf(real(D),3);
else
    pval = nan(1);
end

% save it all out
Data.phat_alt = phat_alt;
Data.pci_alt = pci_alt;
Data.phat_null = phat_null;
Data.pci_null = pci_null;
Data.pval = pval;
Data.X = X;
Data.Ang = Ang;
xi = linspace(-pi,pi,100);
Data.Vm.X = fnVonMises(xi, phat_alt);
Data.Gs.X = repmat(phat_null,1,length(xi));

if args.gamma
    Data.type = 'gamma';
else
    Data.type = 'poisson';
end

% call the "Fit" which ever curve best describes the data.
Data.Fit.Angle = xi;
if pval < 0.05
    Data.Fit.X = Data.Vm.X;
else
    Data.Fit.X = Data.Gs.X;
end


% Calculating the bandwidth of the curve fit - in radians
halfmaxline = ((max(Data.Vm.X) - min(Data.Vm.X)) /2) + min(Data.Vm.X); 
inds = find(Data.Vm.X >= halfmaxline);
Data.bandwidth = abs(angle(exp(1i*Data.Fit.Angle(inds(1)))./exp(1i*Data.Fit.Angle(inds(end))))); % this is just circ_dist

% x = Data.Fit.Angle;
% y = Data.Fit.X;
% l = halfmaxline;
% 

% 
% if length(unique(y)) <= 1
%     Data.bandwidth = NaN;
% else 
%     [~,idx] = max(y);
%     xq(1) = interp1(y(1:idx),x(1:idx), l);
%     xq(2) = interp1(y(idx+1:end), x(idx+1:end), l);
%     
%     Data.bandwidth = abs(xq(1) - xq(2));
% end 


end
