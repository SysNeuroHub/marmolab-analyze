
% image with a transition
imSize = 16; 
transition = 5; 
offset = 3;

phaseplot = [randn(imSize, transition) randn(imSize, imSize-transition)+offset];

subplot(1,2,1)
imagesc(phaseplot); 
subplot(1,2,2)
plot(phaseplot')

% problem: find the value of "transition" when offset is high (easy) and
% low (hard). 