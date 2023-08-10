# marmolab-analyze
marmolab functions for handling mdbase objects and returning sets of trials with partiuclar alignments + analysis functions that work with the trial structure. 

note: any functions using spike-LFP analysis require mdbase objects containing both spikes and lfps. This can be done on the 'new-args' branch of marmodata. see the makeMdm function for changes in calling mdbase

plotDataDive plots figures from maureen's data dive on 23/5/23 - written for cue saccade task, but can be used as an example of usage

dependencies:

circ_stat toolbox: https://github.com/circstat/circstat-matlab

colorcet: https://colorcet.com/ 

for generalized phase analysis:

this uses the code written by Lyle Mueller, and has a few dependencies, all well documented. start here:

Generalized phase: https://github.com/mullerlab/generalized-phase

and then use the ReadMe file to make sure you have all additional

run the demo gp_demo.m to make sure you have everything working

## instructions for dummies
- Try the datafile from August 8th, 2021 `hugo.cuesaccade.mdm`.
- load the data into the workspace with `load('my\file\here\filename.mdm', '-mat')`
- pass the marmodata object into `plotDataDive` with a function call
- pass another argument with the channel order for the array you're analysing

