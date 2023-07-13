function [p, F] = ftest(y, mod1,mod2, df1, df2)
%
% [p, F] = ftest(y, mod1,mod2, df1, df2);
%
% F-test to compare output of two models
%
% model1 is simpler (has less parameters) and higher sum-of-squares error
% model2 is more complex
% so we expect SS1>SS2 and df1>df2
%
% H0 (null hypothesis): simpler model is correct / adequate. We expect that
% more complicated model should be better. P-value addresses the issue of
% what fraction of experiments will the difference in SS be as large, or
% larger, than that observed.
% p<0.05 => significant change in SS, so reject null hypothesis, and
% complex model justifies additional parameters.
% low p => model 2 is significantly better than model 1, despite increase
% in complexity
% for references, see:
%http://www.graphpad.com/help/Prism5/prism5help.html?howtheftestworks.htm
%
% NicP some time in 2007

if df1<df2 %if incorrectly specified, swap order
    dfTEMP = df1; df1 = df2; df2 = dfTEMP; 
    modTEMP = mod1; mod1 = mod2; mod2 = modTEMP;
end

SS1 = sum((mod1-y).^2);
SS2 = sum((mod2-y).^2);

SSrat = (SS1-SS2)/SS2;
DFrat = (df1-df2)/df2;

F = SSrat / DFrat;
p = 1-fcdf(F, df1-df2, df2);