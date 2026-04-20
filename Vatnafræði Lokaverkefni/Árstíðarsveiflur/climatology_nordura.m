clear; clc; close all

% ===== Skráarslóðir =====
flowFile = '/Users/arngunnurvala/Downloads/lamah_ice/D_gauges/2_timeseries/daily/ID_67.csv';
metFile  = '/Users/arngunnurvala/Downloads/lamah_ice/A_basins_total_upstrm/2_timeseries/daily/meteorological_data/ID_67.csv';

% ===== Lesa gögn =====
flow = readtable(flowFile);
met  = readtable(metFile);

% ===== Búa til dagsetningar =====
flow.date = datetime(flow.YYYY, flow.MM, flow.DD);
met.date  = datetime(met.YYYY, met.MM, met.DD);

% ===== Sía tímabilið 1.10.1993 til 30.9.2023 =====
startDate = datetime(1993,10,1);
endDate   = datetime(2023,9,30);

flow = flow(flow.date >= startDate & flow.date <= endDate, :);
met  = met(met.date  >= startDate & met.date  <= endDate, :);

% ===== Finna rétta hitadálkinn =====
metNames = met.Properties.VariableNames;

if ismember('x2m_temp_mean', metNames)
    tempVar = 'x2m_temp_mean';
elseif ismember('m_temp_mean', metNames)
    tempVar = 'm_temp_mean';
elseif ismember('Var6', metNames)
    tempVar = 'Var6';
else
    error('Fann ekki dálk fyrir hitastig. Keyrðu met.Properties.VariableNames og athugaðu dálkanöfnin.');
end

% ===== Reikna mánaðarmeðaltöl =====
monthlyQ = zeros(12,1);
monthlyP = zeros(12,1);
monthlyT = zeros(12,1);

for m = 1:12
    monthlyQ(m) = mean(flow.qobs(flow.MM == m), 'omitnan');
    monthlyP(m) = mean(met.prec(met.MM == m), 'omitnan');
    monthlyT(m) = mean(met.(tempVar)(met.MM == m), 'omitnan');
end

% ===== Mánuðir =====
months = 1:12;
monthLabels = {'Jan','Feb','Mar','Apr','Maí','Jún','Júl','Ágú','Sep','Okt','Nóv','Des'};

% ===== Plotta rennsli =====
figure('Position', [100, 100, 900, 500])
plot(months, monthlyQ, '-o', 'LineWidth', 2)
xticks(months)
xticklabels(monthLabels)
xlabel('Mánuður')
ylabel('Rennsli Q')
title('Meðaltalsár rennslis - Norðurá')
grid on
% ===== Plotta úrkomu =====
figure('Position', [100, 100, 900, 500])
plot(months, monthlyP, '-o', 'LineWidth', 2)
xticks(months)
xticklabels(monthLabels)
xtickangle(45)
xlabel('Mánuður')
ylabel('Úrkoma P')
title('Meðaltalsár úrkomu – Norðurá')
grid on

% ===== Plotta hitastig =====
figure('Position', [100, 100, 900, 500])
plot(months, monthlyT, '-o', 'LineWidth', 2)
xticks(months)
xticklabels(monthLabels)
xtickangle(45)
xlabel('Mánuður')
ylabel('Hitastig T')
title('Meðaltalsár hitastigs – Norðurá')
grid on