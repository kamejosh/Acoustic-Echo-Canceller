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

% creating impulse response
[B,A] = cheby2(4,20,[0.1 0.7]);
impulseResponseGenerator = dsp.IIRFilter('Numerator', [zeros(1,6) B], ...
    'Denominator', A);

% creating room
roomImpulseResponse = impulseResponseGenerator( ...
        (log(0.99*rand(1,M)+0.01).*sign(randn(1,M)).*exp(-0.002*(1:M)))');
roomImpulseResponse = roomImpulseResponse/norm(roomImpulseResponse)*4;
room = dsp.FIRFilter('Numerator', roomImpulseResponse');

% creating the FDAF object
echoCanceller    = dsp.FrequencyDomainAdaptiveFilter('Length', 1000, ...
    'StepSize', 0.025, ...
    'InitialPower', 0.01, ...
    'AveragingFactor', 0.98, ...
    'Method', 'Unconstrained FDAF');

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

%% FDAF Algo for removing echo

[y, e] = echoCanceller(far,micSignal);

% playback of error signal (output)
sound(e,8000);

%% PLOT

figure
% plot near-end signal
subplot(5,1,1);
plot(near);
title('nearspeech');
% plot far-end signal
subplot(5,1,2);
plot(far);
title('farspeech');
% plot echoed signal
subplot (5,1,3);
plot (farEcho);
title('far-end echoed');
% plotting mic Signal
subplot (5,1,4);
plot (micSignal);
title('micSignal'); 
% plotting error signal
subplot(5,1,5);
plot(e);
title('NLMS Out');

%% Plotting erle
diffAverager = dsp.FIRFilter('Numerator', ones(1,1024));
farEchoAverager = clone(diffAverager);

erle = diffAverager((e-near).^2)./ farEchoAverager(farEcho.^2);
erledB = -10*log10(erle);

% erledB = abs(erledB);
figure(3);
plot(erledB);
xlabel('Samlpes]');
ylabel('ERLE [dB]');
title('Echo Return Loss Enhancement');
set(gcf, 'Color', [1 1 1])
avgErle = mean(erledB);
disp(avgErle);
                