# marmolab-analyze
marmolab functions for handling mdbase objects and returning sets of trials with partiuclar alignments + analysis functions that work with the trial structure. 

note: any functions using spike-LFP analysis require mdbase objects containing both spikes and lfps. This can be done on the 'new-args' branch of marmodata. see the makeMdm function for changes in calling mdbase

dependencies:
circ_stat toolbox: https://github.com/circstat/circstat-matlab
colorcet: https://colorcet.com/ 

for generalized phase analysis:
this uses the code written by Lyle Mueller, and has a few dependencies, all well documented. start here:

Generalized phase: https://github.com/mullerlab/generalized-phase
and then use the ReadMe file to make sure you have all additional
run the demo gp_demo.m to make sure you have everything working

