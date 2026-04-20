clear; clc; close all

% ===== Skráarslóð =====
flowFile = '/Users/arngunnurvala/Downloads/lamah_ice/D_gauges/2_timeseries/daily/ID_67.csv';

% ===== Lesa gögn =====
flow = readtable(flowFile);

% ===== Búa til dagsetningar =====
flow.date = datetime(flow.YYYY, flow.MM, flow.DD);

% ===== Velja rétt tímabil: 1.10.1993 til 30.9.2023 =====
startDate = datetime(1993,10,1);
endDate   = datetime(2023,9,30);

flow = flow(flow.date >= startDate & flow.date <= endDate, :);

% ===== Fjarlægja ógild gildi =====
valid = ~isnan(flow.qobs) & flow.qobs > 0;
flow = flow(valid,:);

% ===== Búa til vatnaár =====
hydroYear = year(flow.date);
hydroYear(month(flow.date) >= 10) = hydroYear(month(flow.date) >= 10) + 1;
flow.hydroYear = hydroYear;

% ===== Finna annual peak flow fyrir hvert vatnaár =====
years = unique(flow.hydroYear);
nYears = length(years);

annualPeak = zeros(nYears,1);
peakDate   = NaT(nYears,1);

for i = 1:nYears
    idx = flow.hydroYear == years(i);
    Qyear = flow.qobs(idx);
    dateYear = flow.date(idx);

    [annualPeak(i), indMax] = max(Qyear);
    peakDate(i) = dateYear(indMax);
end

% ===== Raða annual peaks frá hæsta til lægsta =====
Q_sorted = sort(annualPeak, 'descend');

% ===== Gringorten plotting positions =====
m = (1:nYears)';
P_exceed = (m - 0.44) ./ (nYears + 0.12);   % exceedance probability
T_return = 1 ./ P_exceed;                   % return period

% =========================================================
% ===== GUMBEL FIT =====
% =========================================================
mu_Q  = mean(annualPeak);
std_Q = std(annualPeak);

beta_g = std_Q * sqrt(6) / pi;
u_g    = mu_Q - 0.5772 * beta_g;

% Gumbel quantiles fyrir Q10, Q50, Q100
Tvals = [10 50 100];
Pvals = 1 - 1 ./ Tvals;   % non-exceedance probability

Q_gumbel = u_g - beta_g .* log(-log(Pvals));

Q10_gumbel  = Q_gumbel(1);
Q50_gumbel  = Q_gumbel(2);
Q100_gumbel = Q_gumbel(3);

% =========================================================
% ===== LOG NORMAL FIT =====
% =========================================================
Y = log(annualPeak);   % natural log
mu_Y  = mean(Y);
std_Y = std(Y);

Q_lognormal = exp(mu_Y + std_Y .* (-sqrt(2) .* erfcinv(2*Pvals)));

Q10_lognormal  = Q_lognormal(1);
Q50_lognormal  = Q_lognormal(2);
Q100_lognormal = Q_lognormal(3);

% =========================================================
% ===== LOG PEARSON III FIT =====
% =========================================================
% Log-Pearson III = Pearson III dreifing á log10(Q)
Z = log10(annualPeak);
mu_Z  = mean(Z);
std_Z = std(Z);

% Handreiknuð skewness (þarf ekki toolbox)
n = length(Z);
Z_mean = mean(Z);
Z_std = std(Z);

Cs = (n/((n-1)*(n-2))) * sum(((Z - Z_mean)/Z_std).^3);

if abs(Cs) < 1e-8
    % Ef skekkja er nánast 0 -> normal dreifing í log-rými
    z_lp3 = mu_Z + std_Z .* sqrt(2) .* erfinv(2*Pvals - 1);
else
    alpha_lp3 = 4 / (Cs^2);          % shape
    beta_lp3  = std_Z * abs(Cs) / 2; % scale
    xi_lp3    = mu_Z - 2*std_Z / Cs; % location

    if Cs > 0
        Gq = beta_lp3 .* gammaincinv(Pvals, alpha_lp3, 'lower');
        z_lp3 = xi_lp3 + Gq;
    else
        Gq = beta_lp3 .* gammaincinv(1 - Pvals, alpha_lp3, 'lower');
        z_lp3 = xi_lp3 - Gq;
    end
end

Q_logpearson = 10.^z_lp3;

Q10_logpearson  = Q_logpearson(1);
Q50_logpearson  = Q_logpearson(2);
Q100_logpearson = Q_logpearson(3);

% =========================================================
% ===== Sýna niðurstöður í Command Window =====
% =========================================================
fprintf('=============================\n');
fprintf('Flood frequency analysis\n');
fprintf('Norðurá - ID 67\n');
fprintf('=============================\n\n');

fprintf('--- GUMBEL ---\n');
fprintf('Q10  = %.3f m^3/s\n', Q10_gumbel);
fprintf('Q50  = %.3f m^3/s\n', Q50_gumbel);
fprintf('Q100 = %.3f m^3/s\n\n', Q100_gumbel);

fprintf('--- LOG NORMAL ---\n');
fprintf('Q10  = %.3f m^3/s\n', Q10_lognormal);
fprintf('Q50  = %.3f m^3/s\n', Q50_lognormal);
fprintf('Q100 = %.3f m^3/s\n\n', Q100_lognormal);

fprintf('--- LOG PEARSON III ---\n');
fprintf('Q10  = %.3f m^3/s\n', Q10_logpearson);
fprintf('Q50  = %.3f m^3/s\n', Q50_logpearson);
fprintf('Q100 = %.3f m^3/s\n\n', Q100_logpearson);

% =========================================================
% ===== Mynd 1: Annual peaks með plotting positions =====
% =========================================================
figure('Position',[100 100 950 550])
plot(T_return, Q_sorted, 'o', 'MarkerSize', 7, 'LineWidth', 1.5)
set(gca, 'XScale', 'log')
xlabel('Endurkomutími T (ár)')
ylabel('Annual peak flow (m^3/s)')
title('Annual peak flows - Norðurá')
grid on

% =========================================================
% ===== Mynd 2: Samanburður á Gumbel, Log Normal og LP3 =====
% =========================================================
Tplot = linspace(1.01, 150, 500);
Pplot = 1 - 1 ./ Tplot;

% Gumbel lína
Qplot_gumbel = u_g - beta_g .* log(-log(Pplot));

% Log Normal lína
Qplot_lognormal = exp(mu_Y + std_Y .* (-sqrt(2) .* erfcinv(2*Pplot)));

% Log Pearson III lína
if abs(Cs) < 1e-8
    zplot_lp3 = mu_Z + std_Z .* sqrt(2) .* erfinv(2*Pplot - 1);
else
    if Cs > 0
        Gplot = beta_lp3 .* gammaincinv(Pplot, alpha_lp3, 'lower');
        zplot_lp3 = xi_lp3 + Gplot;
    else
        Gplot = beta_lp3 .* gammaincinv(1 - Pplot, alpha_lp3, 'lower');
        zplot_lp3 = xi_lp3 - Gplot;
    end
end

Qplot_logpearson = 10.^zplot_lp3;

figure('Position',[100 100 950 550])
plot(T_return, Q_sorted, 'o', 'MarkerSize', 7, 'LineWidth', 1.5)
hold on
plot(Tplot, Qplot_gumbel, 'LineWidth', 2)
plot(Tplot, Qplot_lognormal, 'LineWidth', 2)
plot(Tplot, Qplot_logpearson, 'LineWidth', 2)
set(gca, 'XScale', 'log')
xlabel('Endurkomutími T (ár)')
ylabel('Rennsli (m^3/s)')
title('Flóðadreifingar fyrir annual peak flows - Norðurá')
legend('Annual peaks', 'Gumbel', 'Log Normal', 'Log Pearson III', 'Location', 'best')
grid on