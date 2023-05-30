function [tuning_phi,sel,pval,z, tuning, binc] = calcContinuousTuning(Data,Phi,nBins)
%
%  [tuning_phi,sel,p,z] = calcContinuousTuning(Data,Phi,nBins)
%
%   Inputs: Data  =  Array, trial vs time
%   Phi Vector 1 x trial angles
%   nBins
%
%   Outputs:
%               tuning_phi - angle of preferred direction (radians)
%               sel - length of the resultant vector
%               pval - pvalue from random permuatation test
%               z - z score from random permutation test
%

if size(Data,1)==1, Data = Data'; end

T = size(Data,2);
N = length(Phi);
nPerm = 1e4;
complexvalued_r = zeros(1,T);
shuffleR = zeros(1,nPerm);
pval = nan(1,T);

PhiBinWidth = 2*pi./nBins;
PhiBinCenters = -pi+PhiBinWidth./2+PhiBinWidth*(0:nBins-1);


Tuning = zeros(length(T),nBins);

for iT = 1:T
    for iBin = 1:nBins
        inBin = Phi>PhiBinCenters(iBin)-PhiBinWidth & Phi<PhiBinCenters(iBin)+PhiBinWidth;
        Tuning(iT,iBin) = mean(Data(inBin,iT));
    end
    
    complexvalued_r(iT) = (1./N.*sum(Tuning(1,:).*exp(complex(0,1).*PhiBinCenters)));
    
    for iPerm = 1:nPerm
        shufflePhi = Phi(randperm(N));
        shuffleTuning=zeros(1,nBins);
            for iBin = 1:nBins
                inBin = shufflePhi>PhiBinCenters(iBin)-PhiBinWidth & shufflePhi<PhiBinCenters(iBin)+PhiBinWidth;
                shuffleTuning(iBin) = mean(Data(inBin,iT));
            end
        shuffleR(iPerm) = abs(1./N.*sum(shuffleTuning.*exp(complex(0,1).*PhiBinCenters)));
    end
    myR = abs(complexvalued_r(iT));
    pval(iT) = sum(shuffleR>myR)./nPerm;
end

z = norminv(1-pval);
tuning_phi = atan2(imag(complexvalued_r),real(complexvalued_r));
sel = abs(complexvalued_r);
tuning = Tuning;
binc = PhiBinCenters;



