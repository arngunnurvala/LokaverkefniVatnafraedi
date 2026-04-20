%% Liður 8 - Greining á rennslisatburði fyrir Norðurá (ID 67)

clear; clc; close all;

%% ---- SLÓÐ ----
basePath = '/Users/salkarutbodvarsdottir/Desktop/heimad2/lamah_ice';

qFile = fullfile(basePath, 'D_gauges', '2_timeseries', 'daily', 'ID_67.csv');
metFile = fullfile(basePath, 'A_basins_total_upstrm', '2_timeseries', 'daily', 'meteorological_data', 'ID_67.csv');

%% ---- CHECK PATH ----
disp(qFile)
disp(metFile)

if exist(qFile,'file') ~= 2
    error('Finn ekki rennslisskrá!');
end
if exist(metFile,'file') ~= 2
    error('Finn ekki veðurskrá!');
end

%% ---- LESA INN GÖGN ----
Qtab = readtable(qFile);
Mtab = readtable(metFile);

%% ---- SÝNA DÁLKA ----
disp('--- Qtab columns ---')
disp(Qtab.Properties.VariableNames')

disp('--- Mtab columns ---')
disp(Mtab.Properties.VariableNames')

%% ---- BÚA TIL DATETIME ----
Qtab.date = datetime(Qtab.YYYY, Qtab.MM, Qtab.DD);
Mtab.date = datetime(Mtab.YYYY, Mtab.MM, Mtab.DD);

%% ---- SAMEINA TÖFLUR EFTIR DAGSETNINGU ----
T = innerjoin(Qtab, Mtab, 'Keys', 'date');

%% ---- AFMARKA TÍMABIL VERKEFNISINS ----
startDate = datetime(1993,10,1);
endDate   = datetime(2023,9,30);

T = T(T.date >= startDate & T.date <= endDate, :);

%% ---- FINNA BREYTUR ----
% Rennsli
Q = T.qobs;

% Úrkoma
precVar = '';
possiblePrecVars = {'prec','prec_carra','tp','rr','xprec','xprec_carra'};

for i = 1:length(possiblePrecVars)
    if ismember(possiblePrecVars{i}, T.Properties.VariableNames)
        precVar = possiblePrecVars{i};
        break
    end
end

if isempty(precVar)
    error('Finn ekki úrkomubreyta. Skoðaðu VariableNames.');
else
    P = T.(precVar);
    fprintf('Notar úrkomubreyta: %s\n', precVar);
end

% Hitastig
tempVar = '';
possibleTempVars = {'x2m_temp_mean','x2m_temp_carra','2m_temp_mean','2m_temp_carra','temp','tas'};

for i = 1:length(possibleTempVars)
    if ismember(possibleTempVars{i}, T.Properties.VariableNames)
        tempVar = possibleTempVars{i};
        break
    end
end

if isempty(tempVar)
    error('Finn ekki hitabreyta. Skoðaðu VariableNames.');
else
    Temp = T.(tempVar);
    fprintf('Notar hitabreytu: %s\n', tempVar);
end

date = T.date;

%% ---- HREINSA NaN ----
ok = ~isnan(Q) & ~isnan(P) & ~isnan(Temp);

Q = Q(ok);
P = P(ok);
Temp = Temp(ok);
date = date(ok);

%% ---- FINNA HÆSTA RENNSLISTOPP ----
Q_work = Q;
Q_work(isnan(Q_work)) = -Inf;

[Qmax, peakLoc] = max(Q_work);
peakDate = date(peakLoc);

%% ---- SKILGREINA FYRIR ATBURÐ ----
nBefore = 10;
nAfter  = 20;

i1 = max(1, peakLoc - nBefore);
i2 = min(length(Q), peakLoc + nAfter);

date_ev = date(i1:i2);
Q_ev = Q(i1:i2);
P_ev = P(i1:i2);
T_ev = Temp(i1:i2);

%% ---- UPPHAF ATBURÐAR ----
% Tek lægsta rennsli í glugganum fyrir topp sem einfalt mat á grunnástandi
[~, relStart] = min(Q(i1:peakLoc));
startLoc = i1 + relStart - 1;

startDateEvent = date(startLoc);
Q_before = Q(startLoc);

%% ---- TIME-TO-PEAK ----
time_to_peak = days(peakDate - startDateEvent);

%% ---- LOK ÚRKOMU FYRIR TOPPINN ----
rainThresh = 0.1;   % mm/dag
rainDays = find(P(i1:peakLoc) > rainThresh);

if ~isempty(rainDays)
    lastRainLoc = i1 + rainDays(end) - 1;
    lastRainDate = date(lastRainLoc);
else
    lastRainLoc = NaN;
    lastRainDate = NaT;
end

%% ---- RECESSION TIME ----
% Mýkri skilgreining:
% endi atburðar þegar rennsli hefur lækkað niður í 110% af upphafsgildi
Q_target = 1.10 * Q_before;

searchEnd = min(length(Q), peakLoc + 30);   % leita max 30 daga eftir topp
postPeak = peakLoc:searchEnd;

backToBase = find(Q(postPeak) <= Q_target, 1, 'first');

if ~isempty(backToBase)
    endLoc = postPeak(backToBase);
    endDateEvent = date(endLoc);
    recession_time = days(endDateEvent - peakDate);
else
    endLoc = NaN;
    endDateEvent = NaT;
    recession_time = NaN;
end

%% ---- EXCESS RAIN RELEASE TIME ----
if ~isnat(lastRainDate) && ~isnat(endDateEvent)
    excess_time = days(endDateEvent - lastRainDate);
else
    excess_time = NaN;
end

%% ---- PRINTA NIÐURSTÖÐUR ----
fprintf('\n--- NIÐURSTÖÐUR ---\n');
fprintf('Peak date: %s\n', datestr(peakDate));
fprintf('Q_before: %.2f m3/s\n', Q_before);
fprintf('Qmax: %.2f m3/s\n', Qmax);
fprintf('Time-to-peak: %.1f dagar\n', time_to_peak);

if isnan(recession_time)
    fprintf('Recession time: fannst ekki innan leitarglugga\n');
else
    fprintf('Recession time: %.1f dagar\n', recession_time);
end

if isnan(excess_time)
    fprintf('Excess rain release time: fannst ekki\n');
else
    fprintf('Excess rain release time: %.1f dagar\n', excess_time);
end

%% ---- PLOTTA SKÝRT Í 3 MYNDUM ----
figure('Position',[100 100 950 750])
sgtitle('Rennslisatburður í Norðurá (desember 2006)', ...
    'FontWeight','bold','FontSize',12)

% 1) Rennsli
subplot(3,1,1)
plot(date_ev, Q_ev, '-o', 'LineWidth', 1.5, 'MarkerSize', 4)
hold on
xline(startDateEvent, '--')
xline(peakDate, '--')

if ~isnat(lastRainDate)
    xline(lastRainDate, '--')
end

if ~isnat(endDateEvent) && endDateEvent >= date_ev(1) && endDateEvent <= date_ev(end)
    xline(endDateEvent, '--')
end

ylabel('Q (m^3/s)')
grid on

% 2) Úrkoma
subplot(3,1,2)
bar(date_ev, P_ev)
hold on

if ~isnat(lastRainDate)
    xline(lastRainDate, '--')
end

if ~isnat(endDateEvent) && endDateEvent >= date_ev(1) && endDateEvent <= date_ev(end)
    xline(endDateEvent, '--')
end

ylabel('P (mm/dag)')
grid on

% 3) Hitastig
subplot(3,1,3)
plot(date_ev, T_ev, '-s', 'LineWidth', 1.2, 'MarkerSize', 4)
hold on
yline(0, '--')

if ~isnat(lastRainDate)
    xline(lastRainDate, '--')
end

if ~isnat(endDateEvent) && endDateEvent >= date_ev(1) && endDateEvent <= date_ev(end)
    xline(endDateEvent, '--')
end

xlabel('Dagsetning')
ylabel('T (°C)')
grid on

%%
saveas(gcf, 'rennslisatburdur_nordura_ID67.png')