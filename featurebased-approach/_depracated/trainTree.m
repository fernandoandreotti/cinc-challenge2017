rng(1); % For reproducibility
ens = fitensemble(In,Out,'Bag',50,...
    'Tree','type','classification');
[label,score] = oobPredict(ens);