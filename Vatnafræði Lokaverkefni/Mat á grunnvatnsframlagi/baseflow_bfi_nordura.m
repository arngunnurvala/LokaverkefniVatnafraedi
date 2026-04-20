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

% Fjarlægja neikvæð eða ógild gildi ef þau finnast
Q(Q < 0) = NaN;

% Fylla eyður tímabundið með línulegri interpolation svo filter virki
Q_filled = fillmissing(Q, 'linear');

% ===== Lyne-Hollick filter =====
% alpha yfirleitt valið hátt, t.d. 0.925 fyrir dagleg gögn
alpha = 0.925;

n = length(Q_filled);
quickflow = zeros(n,1);

% Fyrsta forward pass
for i = 2:n
    quickflow(i) = alpha * quickflow(i-1) + ((1 + alpha)/2) * (Q_filled(i) - Q_filled(i-1));
    if quickflow(i) < 0
        quickflow(i) = 0;
    end
    if quickflow(i) > Q_filled(i)
        quickflow(i) = Q_filled(i);
    end
end

% Reikna baseflow
baseflow = Q_filled - quickflow;
baseflow(baseflow < 0) = 0;

% ===== BFI =====
BFI = sum(baseflow, 'omitnan') / sum(Q_filled, 'omitnan');

fprintf('BFI fyrir Norðurá (1993-10-01 til 2023-09-30) = %.3f\n', BFI);

% ===== Teikna mynd =====
figure('Position',[100 100 1100 500])
plot(dates, Q_filled, 'LineWidth', 1)
hold on
plot(dates, baseflow, 'LineWidth', 1.5)
xlabel('Dagsetning')
ylabel('Rennsli (m^3/s)')
title('Heildarrennsli og baseflow - Norðurá (1993–2023)')
legend('Heildarrennsli', 'Baseflow', 'Location', 'best')
grid on

