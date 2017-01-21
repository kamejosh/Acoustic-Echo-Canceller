% clear command window
clc;
% clear workspace
clear all;
% close open windows
close all;
%% general settings

% frequency
fs = 8000;
M = fs/2 + 1;

% number of samples that schould be analysed for double talk: 20ms
lookupTime = fs/50;
% hold time for dtd: 100ms
holdTime = fs/10;

% creating impulse response
[B,A] = cheby2(4,20,[0.1 0.7]);
impulseResponseGenerator = dsp.IIRFilter('Numerator', [zeros(1,6) B], ...
    'Denominator', A);

% creating room
roomImpulseResponse = impulseResponseGenerator( ...
        (log(0.99*rand(1,M)+0.01).*sign(randn(1,M)).*exp(-0.002*(1:M)))');
roomImpulseResponse = roomImpulseResponse/norm(roomImpulseResponse)*4;
room = dsp.FIRFilter('Numerator', roomImpulseResponse');

%% nearspeech

% load audiofile for nearend
% Fname1 = filename
% Pname1 = pathname
[Fname1,Pname1] = uigetfile('*.wav','Select nearspeech FIle'); 

% complete filename inkl. path
filenameNE = strcat(Pname1, Fname1);

% read audio data from file
% v = sampled data (audio information)
% Fs1 = Samplerate
[v,Fs1] = audioread(filenameNE);

% assign audio to variable 'near'
near = v;

%% farspeech

% load audiofile for farend
% Fname1 = filename
% Pname1 = pathname
[Fname2,Pname2] = uigetfile('*.wav','Select farspeech FIle'); 

% complete filenmae inkl. path
filenameFE = strcat(Pname2, Fname2);

% read audio data from file
% v = sampled data (audio information)
% Fs1 = Samplerate
[x,Fs2] = audioread(filenameFE);

% assign audio to variable 'far'
far = x;

%% far and echoed speech

% create echo signal
farEcho = room(far);
farEcho = farEcho * 0.2 + far;

% playback of echoed far-end signal
% sound(farEcho,8000);
% if audio is played back the pause guarantes no mixed playback
% pause(30);
%% 

% combining far-end echo and near-end for micSignal
micSignal = farEcho + near;

% here original signal
% sound(micSignal);
% pause(30);

% calculating length of array
miclength = length(micSignal);

%% Geigel Algorithmus for detecting Double Talk

% length of array transfered to typical for loop variable
N = miclength;

% threshold
T = 2.5;

% allocating memory for variables , so matlab doesn't spent time on
% reallocating during calculation
% variable that defines if dtd is happening
geigel = zeros(1,N);
% measuring calculation time
timeForEachIteration = zeros(1,N);
% subset used in calculating max Value
subFar = zeros(1, lookupTime);

% Geigel Loop over Signal
for i = 1:N
    % start time meassuring
    tic   
    % calculating ratio
    if i <= lookupTime
        subFar = far(1:i);
    else
        subFar = far((i-lookupTime):i);
    end
       
    % calculate ratio
    x = abs(micSignal(i));
    y = max(abs(subFar));
    p = x/y;
    
    if p > T && abs(far(i)) > 0.02
        if i + 10 < N
            geigel(i:i+holdTime) = 1; 
        else
            geigel(i:N) = 1; 
        end
    end
    %stop time meassuring for this iteration
    timeForEachIteration(i) = toc;
end

%% ploting graphs

figure
% plot near-end signal
subplot(5,1,1);
plot(near);
title('nearspeech');
% plot far-end signal
subplot(5,1,2);
plot(far);
title('farspeech');
% plot dtd
subplot(5,1,3);
plot(geigel);
title('geigel dtd');
% plot mic signal
subplot (5,1,4);
plot (micSignal);
title('micSignal'); 