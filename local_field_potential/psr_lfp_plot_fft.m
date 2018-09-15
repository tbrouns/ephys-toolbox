function h = psr_lfp_plot_fft(fftfreq,parameters)

% PSR_LFP_PLOT_FFT - Plot power spectrum
%
% Syntax:  h = psr_lfp_plot_fft(fftfreq,parameters)
%
% Inputs:
%    fftfreq    - Output from PSR_LFP_FFT function
%    parameters - See PSR_PARAMETERS_ANALYSIS
%
% Outputs:
%    h - Handle for power spectrum plot
%
% See also: PSR_LFP_FFT

% PASER: Processing and Analysis Schemes for Extracellular Recordings 
% https://github.com/tbrouns/paser

% Author: Terence Brouns
% Radboud University, Neurophysiology Dept. 
% E-mail address: t.s.n.brouns@gmail.com
% Date: 2018

%------------- BEGIN CODE --------------

if (strcmp(parameters.analysis.fft.plot.error,'no')); PLOT_ERROR = false;
else,                                                 PLOT_ERROR = true;
end

h = [];
smfreq  = parameters.analysis.fft.plot.smfreq;
powtype = parameters.analysis.fft.plot.powtype;

% Convert data if specified

powtype = lower(powtype);
switch powtype
    case 'decibel'; fftfreq.powspctrm = 10 * log10(fftfreq.powspctrm);
end
yLabelStr = [upper(powtype(1)) powtype(2:end) ' \ power'];

% Power spectrum (Power vs. Frequency)

powSpctrm = fftfreq.powspctrm;
freqArray = fftfreq.freq;

nDims   = ndims(powSpctrm);
nTrials =  size(powSpctrm,1);

if (nDims == 3) % Average over trials
    keep = ~isinf(sum(powSpctrm,3));
    powSpctrm = powSpctrm(keep(:),:,:);
    powSpctrmMean = nanmean(powSpctrm,1);
    powSpctrmMean = permute(powSpctrmMean,[2 3 1]);
    if (nTrials > 1 && PLOT_ERROR)
        switch parameters.analysis.fft.plot.error
            case 'std'; n = 1;
            case 'sem'; n = sqrt(nTrials);
        end
        sd = std(powSpctrm,[],1);
        sd = permute(sd,[2 3 1]);
        l = powSpctrmMean - (sd / n);
        u = powSpctrmMean + (sd / n);
    else
        PLOT_ERROR = false;
    end
    powSpctrm = powSpctrmMean;
end

if (smfreq > 0)
    df = mean(diff(freqArray));
    powSpctrm = psr_gauss_smoothing(powSpctrm,df,smfreq);
    if (PLOT_ERROR)
        l = psr_gauss_smoothing(l,df,smfreq);
        u = psr_gauss_smoothing(u,df,smfreq);
    end
end

% Remove NaNs and Infs

del = (isnan(powSpctrm) | isinf(powSpctrm));
if (all(del)); return; end
freqArray(del) = [];
powSpctrm(del) = [];

if (PLOT_ERROR) % Plot error range
    l(del) = [];
    u(del) = [];
    plot_ci(freqArray,[l' u'],   ...
        'PatchAlpha', parameters.analysis.fft.plot.alpha, ...
        'PatchColor', parameters.analysis.fft.plot.color, ...
        'LineStyle',  'none');
end

% Plot power specturm
h = plot(freqArray,powSpctrm,'LineWidth',1.5,'Color',parameters.analysis.fft.plot.color);
xlabel( '$\bf{Frequency \ [Hz]}$','Interpreter','Latex');
ylabel(['$\bf{' yLabelStr '}$'],  'Interpreter','Latex');
set(gca,'TickLabelInterpreter','Latex');
set(gca, 'XScale', 'log');

if (~isempty_field(parameters,'parameters.analysis.fft.plot.flim')); xlim(parameters.analysis.fft.plot.flim); end
if (~isempty_field(parameters,'parameters.analysis.fft.plot.plim')); ylim(parameters.analysis.fft.plot.plim); end

end