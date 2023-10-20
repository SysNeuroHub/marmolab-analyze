
success_count = 0;
small_fail_count = 0;
big_fail_count = 0;
num_loops = 500;

for m = 1:num_loops
% image with a transition
imSize = 16; 
transition = randi([1,imSize]); 
offset = 0.8;

phaseplot = [randn(imSize, transition) randn(imSize, imSize-transition)+offset];



subplot(1,3,1)
imagesc(phaseplot); 
axis square
title("Raw")
subplot(1,3,2)
plot(mean(phaseplot));
axis square
title("Mean")

% pre-define parameters a, b and c to hopefully improve fit.
guess_a = 1.5; % a = max value of sigmoid
guess_b = 0.2; % b = steepness at transition
guess_c = transition; % c = midpoint of transition

% When we're using real data, we won't know when to expect the transition
% but what we could do instead is use historical data to roughly predict
% where the array "normally" sits and use that as a guess for 'c'.

opts = fitoptions('Method','NonLinearLeastSquares');
opts.StartPoint = [guess_a, guess_b, guess_c];

% problem: find the value of "transition" when offset is high (easy) and
% low (hard). 
subplot(1,3,3)
sigmoidModel = fittype(@(a,b,c,x) a./(1+exp(-b*(x-c))), 'independent','x','dependent','y');
fitted_model = fit((1:16)',mean(phaseplot)',sigmoidModel,opts);


% disp(fitted_model)

fittedY = fitted_model(1:16);
x = 1:16;
plot(x,fittedY);
axis square
title("Fitted")

% create for loop that loops through each x and calculates the difference
% between one y value and the next 
% whenever that difference is a maximum, record the x index and keep
% updating

ydiff_old = 0;
ydiff_new = 0;

for i = 1:length(x)-1
    ydiff_new = fittedY(i+1)-fittedY(i);
    if ydiff_new > ydiff_old
        transition_exp = x(i);
    end
    ydiff_old = ydiff_new;
end


if (transition == transition_exp) 
%     fprintf("Success");
    success_count = success_count +1;
else
    transition_diff = abs(transition_exp - transition);
    if transition_diff <=1
        small_fail_count = small_fail_count + 1;
    else
        big_fail_count = big_fail_count + 1;
    end
%     fprintf("Fail: \n Real transition: %d \n Predicted transition: %d \n",transition,transition_exp);

end

end

fprintf("Success: %.2f %%\n",100*success_count/num_loops);
fprintf("Small fails: %.2f %%\n",100*small_fail_count/num_loops);
fprintf("Significant fails: %.2f %%\n",100*big_fail_count/num_loops);

% note for Gretel for next week
% It might be worth checking points in groups of three rather groups of two
% to find the maximum transition because sometimes the transition occurs over 3
% electrodes which means the recorded transition is in the middle which
% we're missing out on. This should reduce the number of small fails
% although possibly not significantly as it seems that a fail by 1
% electrode happens about 5% of the time but hopefully that will take
% accuracy to > 70%. 


