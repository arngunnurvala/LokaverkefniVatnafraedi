clear; clc; close all

% ===== Skráarslóð =====
flowFile = '/Users/arngunnurvala/Downloads/lamah_ice/D_gauges/2_timeseries/daily/ID_67.csv';

% ===== Lesa gögn =====
flow = readtable(flowFile);
flow.date = datetime(flow.YYYY, flow.MM, flow.DD);

% ===== Velja tímabil =====
startDate = datetime(1993,10,1);
endDate   = datetime(2023,9,30);

flow = flow(flow.date >= startDate & flow.date <= endDate, :);
flow = flow(~isnan(flow.qobs) & flow.qobs > 0, :);

% ===== Búa til vatnaár =====
hydroYear = year(flow.date);
hydroYear(month(flow.date) >= 10) = hydroYear(month(flow.date) >= 10) + 1;
flow.hydroYear = hydroYear;

% ===== Skilgreina árstíðir =====
m = month(flow.date);

season = strings(height(flow),1);
season(ismember(m,[12 1 2])) = "Vetur";
season(ismember(m,[3 4 5]))  = "Vor";
season(ismember(m,[6 7 8]))  = "Sumar";
season(ismember(m,[9 10 11])) = "Haust";

flow.season = season;

% ===== Reikna ársmeðalrennsli =====
years = unique(flow.hydroYear);
nY = length(years);

annualMeanQ = nan(nY,1);

for i = 1:nY
    idx = flow.hydroYear == years(i);
    annualMeanQ(i) = mean(flow.qobs(idx), 'omitnan');
end

% ===== Reikna árstíðameðalrennsli =====
seasonNames = ["Vetur","Vor","Sumar","Haust"];
nS = length(seasonNames);

seasonalMeanQ = nan(nY,nS);

for i = 1:nY
    for s = 1:nS
        idx = flow.hydroYear == years(i) & flow.season == seasonNames(s);
        if any(idx)
            seasonalMeanQ(i,s) = mean(flow.qobs(idx), 'omitnan');
        end
    end
end

% ===== Helper function: Theil-Sen slope =====
theilSen = @(x,y) median( ...
    arrayfun(@(i,j) (y(j)-y(i))./(x(j)-x(i)), ...
    repelem((1:length(x)-1)', length(x)-(1:length(x)-1)'), ...
    cell2mat(arrayfun(@(i) (i+1:length(x))', (1:length(x)-1)', 'UniformOutput', false))), ...
    'omitnan');

% ===== Helper function: Mann-Kendall test (basic) =====
mk_test = @(y) mann_kendall_test_local(y);

% ===== Ársgreining =====
x = years(:);
y = annualMeanQ(:);

annualSlope = theilSen(x,y);
[annualTau, annualP, annualTrend] = mk_test(y);

% ===== Árstíðagreining =====
seasonSlope = nan(nS,1);
seasonTau   = nan(nS,1);
seasonP     = nan(nS,1);
seasonTrend = strings(nS,1);

for s = 1:nS
    ys = seasonalMeanQ(:,s);
    valid = ~isnan(ys);

    seasonSlope(s) = theilSen(x(valid), ys(valid));
    [seasonTau(s), seasonP(s), seasonTrend(s)] = mk_test(ys(valid));
end

% ===== Prenta niðurstöður =====
fprintf('\n===== LEITNIGREINING: ÁRSMEÐALRENNSLI =====\n');
fprintf('Theil-Sen slope = %.4f m^3/s á ári\n', annualSlope);
fprintf('Mann-Kendall tau = %.4f\n', annualTau);
fprintf('p-gildi = %.4f\n', annualP);
fprintf('Niðurstaða = %s\n', annualTrend);

fprintf('\n===== LEITNIGREINING: ÁRSTÍÐAMEÐALRENNSLI =====\n');
for s = 1:nS
    fprintf('\n%s:\n', seasonNames(s));
    fprintf('  Theil-Sen slope = %.4f m^3/s á ári\n', seasonSlope(s));
    fprintf('  Mann-Kendall tau = %.4f\n', seasonTau(s));
    fprintf('  p-gildi = %.4f\n', seasonP(s));
    fprintf('  Niðurstaða = %s\n', seasonTrend(s));
end

% ===== Mynd 1: Ársmeðalrennsli =====
figure('Position',[100 100 900 500])
plot(years, annualMeanQ, 'o-', 'LineWidth', 1.5)
hold on

% Theil-Sen lína
annualFit = median(annualMeanQ - annualSlope*years);
plot(years, annualSlope*years + annualFit, '-', 'LineWidth', 2)

xlabel('Vatnaár')
ylabel('Ársmeðalrennsli (m^3/s)')
title('Leitni í ársmeðalrennsli - Norðurá')
legend('Gögn','Theil-Sen lína','Location','best')
grid on

% ===== Mynd 2: Árstíðameðalrennsli =====
figure('Position',[100 100 1000 550])
hold on

markers = {'o-','s-','d-','^-'};  % bara til að aðgreina línurnar
for s = 1:nS
    plot(years, seasonalMeanQ(:,s), markers{s}, 'LineWidth', 1.5)
end

xlabel('Vatnaár')
ylabel('Árstíðameðalrennsli (m^3/s)')
title('Leitni í árstíðameðalrennsli - Norðurá')
legend(seasonNames, 'Location', 'best')
grid on

% ===== Local function =====
function [tau, pValue, trendText] = mann_kendall_test_local(y)

    y = y(:);
    n = length(y);

    S = 0;
    for k = 1:n-1
        for j = k+1:n
            S = S + sign(y(j) - y(k));
        end
    end

    % tie correction
    uniqueVals = unique(y);
    tieSum = 0;
    for i = 1:length(uniqueVals)
        t = sum(y == uniqueVals(i));
        if t > 1
            tieSum = tieSum + t*(t-1)*(2*t+5);
        end
    end

    varS = (n*(n-1)*(2*n+5) - tieSum) / 18;

    if S > 0
        Z = (S - 1) / sqrt(varS);
    elseif S < 0
        Z = (S + 1) / sqrt(varS);
    else
        Z = 0;
    end

    % normal approx without toolbox
    pValue = 2 * (1 - 0.5 * erfc(-abs(Z)/sqrt(2)));

    tau = S / (0.5*n*(n-1));

    if pValue < 0.05
        if tau > 0
            trendText = "Marktæk hækkandi leitni (p < 0.05)";
        elseif tau < 0
            trendText = "Marktæk lækkandi leitni (p < 0.05)";
        else
            trendText = "Engin marktæk leitni";
        end
    else
        trendText = "Engin marktæk leitni (p >= 0.05)";
    end
end