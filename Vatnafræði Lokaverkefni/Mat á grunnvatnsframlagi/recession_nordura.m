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

% ===== Taka rennslisgögn =====
Q = flow.qobs;
dates = flow.date;

% Fjarlægja neikvæð eða ógild gildi
Q(Q <= 0) = NaN;

% ===== Finna samfellda lækkandi daga =====
% Notum aðeins daga þar sem Q(t+1) < Q(t)
Q1 = Q(1:end-1);
Q2 = Q(2:end);

valid = ~isnan(Q1) & ~isnan(Q2) & (Q2 < Q1) & (Q1 > 0) & (Q2 > 0);

Q1_rec = Q1(valid);
Q2_rec = Q2(valid);

% ===== Reikna recession constant k =====
% Q(t+1) = Q(t) * exp(-k)
% => ln(Q(t+1)/Q(t)) = -k
k_values = -log(Q2_rec ./ Q1_rec);

% Taka meðaltal
k_mean = mean(k_values, 'omitnan');
k_median = median(k_values, 'omitnan');

fprintf('Recession constant k (meðaltal) = %.4f per dag\n', k_mean);
fprintf('Recession constant k (miðgildi) = %.4f per dag\n', k_median);

% ===== Reikna recession factor a = exp(-k) =====
a_mean = exp(-k_mean);
a_median = exp(-k_median);

fprintf('Recession factor a (úr meðaltali k) = %.4f\n', a_mean);
fprintf('Recession factor a (úr miðgildi k) = %.4f\n', a_median);

% ===== Mynd 1: Histogram af k =====
figure('Position',[100 100 900 500])
histogram(k_values, 40)
xlabel('k (per dag)')
ylabel('Fjöldi')
title('Dreifing recession constant k - Norðurá')
grid on

% ===== Mynd 2: Scatter af Q(t) og Q(t+1) í log-rými =====
figure('Position',[100 100 900 500])
plot(log(Q1_rec), log(Q2_rec), '.', 'MarkerSize', 6)
xlabel('ln(Q_t)')
ylabel('ln(Q_{t+1})')
title('Recession samband í log-rými - Norðurá')
grid on

% ===== Passa beina línu í log-rými =====
p = polyfit(log(Q1_rec), log(Q2_rec), 1);
hold on
xfit = linspace(min(log(Q1_rec)), max(log(Q1_rec)), 100);
yfit = polyval(p, xfit);
plot(xfit, yfit, 'r-', 'LineWidth', 2)
legend('Gögn', 'Línuleg aðhvarfslína', 'Location', 'best')

% ===== Sýna hallatölu og skurðpunkt =====
fprintf('Hallatala í log-rými = %.4f\n', p(1));
fprintf('Skurðpunktur í log-rými = %.4f\n', p(2));