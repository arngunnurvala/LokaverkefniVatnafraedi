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

% Fjarlægja ógild gildi
Q = Q(~isnan(Q) & Q > 0);

% ===== Raða frá hæsta til lægsta =====
Q_sorted = sort(Q, 'descend');

% ===== Reikna exceedance probability (%) =====
n = length(Q_sorted);
P = (1:n)' ./ (n + 1) * 100;

% ===== Finna Q5, Q50, Q95 =====
Q5  = interp1(P, Q_sorted, 5,  'linear');
Q50 = interp1(P, Q_sorted, 50, 'linear');
Q95 = interp1(P, Q_sorted, 95, 'linear');

fprintf('Q5  = %.3f m^3/s\n', Q5);
fprintf('Q50 = %.3f m^3/s\n', Q50);
fprintf('Q95 = %.3f m^3/s\n', Q95);

% ===== Plotta FDC =====
figure('Position',[100 100 900 550])
plot(P, Q_sorted, 'LineWidth', 2)
hold on
plot(5,  Q5,  'o', 'MarkerSize', 8, 'LineWidth', 2)
plot(50, Q50, 'o', 'MarkerSize', 8, 'LineWidth', 2)
plot(95, Q95, 'o', 'MarkerSize', 8, 'LineWidth', 2)

xlabel('Exceedance probability (%)')
ylabel('Rennsli (m^3/s)')
title('Langaeislína rennslis (Flow Duration Curve) - Norðurá')
grid on
legend('FDC', 'Q5', 'Q50', 'Q95', 'Location', 'best')

% ===== Aukamynd með log-kvarða á y-ás =====
figure('Position',[100 100 900 550])
semilogy(P, Q_sorted, 'LineWidth', 2)
hold on
semilogy(5,  Q5,  'o', 'MarkerSize', 8, 'LineWidth', 2)
semilogy(50, Q50, 'o', 'MarkerSize', 8, 'LineWidth', 2)
semilogy(95, Q95, 'o', 'MarkerSize', 8, 'LineWidth', 2)

xlabel('Exceedance probability (%)')
ylabel('Rennsli (m^3/s) [log kvarði]')
title('Langaeislína rennslis (Flow Duration Curve, log-kvarði) - Norðurá')
grid on
legend('FDC', 'Q5', 'Q50', 'Q95', 'Location', 'best')