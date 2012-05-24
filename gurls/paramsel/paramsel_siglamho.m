function vout = paramsel_siglamho(X,y,opt)
% paramsel_siglam(X,Y,OPT)
% Performs parameter selection when the dual formulation of RLS is used.
% The hold-out approach is used.
% It selects both the regularization parameter lambda and the kernel parameter sigma.
%
% INPUTS:
% -X: input data matrix
% -Y: labels matrix
% -OPT: struct of options with the following fields:
%   fields that need to be set through previous gurls tasks:
%		- kernel.K (set by the kernel_* routines)
%   fields with default values set through the defopt function:
%       - nsigma
%		- kernel.type
%		- nlambda
%       - hoperf
%
%   For more information on standard OPT fields
%   see also defopt
% 
% OUTPUT: structure with the following fields:
% -lambdas: value of the regularization parameter lambda
%           minimizing the validation error, replicated in a TX1 array 
%           where T is the number of classes
% -sigma: value of the kernel parameter minimizing the validation error


%savevars = {'forho','M'};


if isfield (opt,'paramsel')
	vout = opt.paramsel; % lets not overwrite existing parameters.
			      		 % unless they have the same name
end
savevars = [];

[n,T]  = size(y);
if ~isfield(opt,'kernel')
	opt.kernel.type = 'rbf';
end
if ~isfield(opt.kernel,'distance')
	opt.kernel.distance = squareform(pdist(X));
end	
if ~isfield(opt,'sigmamin')
	D = sort(squareform(opt.kernel.distance));
	firstPercentile = round(0.01*numel(D)+0.5);
	opt.sigmamin = D(firstPercentile);
	clear D;
end
if ~isfield(opt,'sigmamax')
	opt.sigmamax = max(max(opt.kernel.distance));
end
if opt.sigmamin <= 0
	opt.sigmamin = eps;
end
if opt.sigmamin <= 0
	opt.sigmamax = eps;
end	
q = (opt.sigmamax/opt.sigmamin)^(1/opt.nsigma);
LOOSQE = zeros(opt.nsigma,opt.nlambda,T);
sigmas = zeros(1,opt.nsigma);

for i = 1:opt.nsigma
	sigmas(i) = (opt.sigmamin*(q^i));
	opt.paramsel.sigma = sigmas(i);
	opt.kernel = kernel_rbf(X,y,opt);
	paramsel = paramsel_hodual(X,y,opt);
	forho(i,:,:) = paramsel.forho{1};
	guesses(i,:) = paramsel.guesses{1};
end
% The lambda axis is redefined each time but
% it is the same for all classes as it depends
% only on K so we can still sum and minimize.
%
% We have to be a bit careful when minimizing.
%
% TODO: select a lambda for each class fixing sigma.

M = sum(forho,3); % sum over classes

[dummy,i] = max(M(:));
[m,n] = ind2sub(size(M),i);

% opt sigma
vout.sigma = opt.sigmamin*(q^m);
% opt lambda
vout.lambdas = guesses(m,n)*ones(1,T);
% This is awesome
if numel(savevars) > 0
	[ST,I] = dbstack();
	save(ST(1).name,savevars{:});
end	
