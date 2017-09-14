
patternnet(hiddenSizes,trainFcn,performFcn)
% hiddenSizes	Row vector of one or more hidden layer sizes (default = 10)
% trainFcn      Training function (default = 'trainscg')
% performFcn	Performance function (default = 'crossentropy')

net = patternnet(10);
net = train(net,x,t);
view(net)
y = net(x);
perf = perform(net,t,y);
classes = vec2ind(y);