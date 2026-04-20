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

% Fjarlægja ógild gildi
valid = ~isnan(Q) & Q > 0;
flow = flow(valid,:);

% ===== Búa til vatnaár =====
% Vatnaár: okt-des teljast til næsta árs
hydroYear = year(flow.date);
hydroYear(month(flow.date) >= 10) = hydroYear(month(flow.date) >= 10) + 1;

flow.hydroYear = hydroYear;

% ===== Finna annual peak fyrir hvert vatnaár =====
years = unique(flow.hydroYear);
nYears = length(years);

annualPeak = zeros(nYears,1);
peakMonth  = zeros(nYears,1);
peakDate   = NaT(nYears,1);

for i = 1:nYears
    idx = flow.hydroYear == years(i);
    Qyear = flow.qobs(idx);
    dateYear = flow.date(idx);

    [annualPeak(i), indMax] = max(Qyear);
    peakDate(i)  = dateYear(indMax);
    peakMonth(i) = month(dateYear(indMax));
end

% ===== Tölur í Command Window =====
disp(table(years, annualPeak, peakDate, peakMonth, ...
    'VariableNames', {'HydroYear','AnnualPeak','PeakDate','PeakMonth'}))

% ===== Telja fjölda toppa í hverjum mánuði =====
monthCounts = zeros(12,1);
for m = 1:12
    monthCounts(m) = sum(peakMonth == m);
end

% ===== Mánuðaheiti =====
monthLabels = {'Jan','Feb','Mar','Apr','Maí','Jún','Júl','Ágú','Sep','Okt','Nóv','Des'};

% ===== Súlurit =====
figure('Position',[100 100 950 500])
bar(1:12, monthCounts)
xticks(1:12)
xticklabels(monthLabels)
xlabel('Mánuður')
ylabel('Fjöldi annual peaks')
title('Árstíðabundin dreifing annual peak flows - Norðurá')
ylim([0 max(monthCounts)+1])
grid on


