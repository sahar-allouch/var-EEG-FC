function [Theta, W, objCon] = dp_glasso(S, ThetaInit, lambda, varargin)
%DP_GLASSO graphical lasso 
%
% [THETA, W] = DP_GLASSO(S, THETAINIT, LAMBDA) runs the graphical lasso on
%   sample covariance matrix S to estimate the regularised precision THETA 
%   and covariance W. The algorithm can be initialised with precision
%   matrix THETAINIT [defaults to diag(1/(diag(S)+lambda))]. Parameter 
%   LAMBDA controls the extent of the regularisation. 
% 
%   The algorithm uses the dp-glasso by Mazumder and Hastie, an improved
%   and more stable version of the graphical lasso glasso by Friedman,
%   Hastie and Tibshirani. It requires the mex binaries in the QPAS package
%   by Adrian Wills to run. 
%
%   Speed increases are generated by wrapping the dp-glasso program inside
%   a search for connected components. For each connected component in the
%   adjacency matrix of S, the dp-glasso code is run just for that
%   subgraph. This can offer large speed increases for moderately large
%   values of lambda. 
%
%   By default, a maximum of 100 iterations of the block coordinate descent
%   routine are run. The algorithm converges when the relative change in
%   the Frobenius norm of the precision matrix THETA is less than 10^-4. 
%
%   LAMBDA can be a path of regularisation parameters, passed in as a
%   vector. In this case, THETA and W are 3D arrays, with the results for
%   each value of LAMBDA stored at each index of the third dimension. 
%   The value of THETA from the previous (higher) value of LAMBDA is used
%   as a warm start on the next computation. 
%
% [THETA, W] = DP_GLASSO(S, THETAINIT, LAMBDA, MAXITER, OPTTOL, VERBOSE)
%   allows setting of the maximum iterations and optimisation tolerance as
%   described above. The VERBOSE flag is an integer in (0-3) which controls
%   the quantity of output to the screen. 
%
% [THETA, W, OBJECTIVE] = DP_GLASSO(...) also returns values for the
%   objective function in the minimisation routine, for every rotation of
%   columns in the block co-ordinate descent algorithm. 
%   OBJECTIVE is a cell array, with one cell for each connected component 
%   in S. There will be nCompleteIterations x nNodes values in each cell. 
%   The objective function is the L1 penalised log-likelihood for the
%   graphical lasso model. 
%   It is not possible to use a vector of LAMBDA values with three
%   outputs. 
%
%	See also glasso_FTH, L1precisionBCD, glasso, ROInets.glasso_frequentist. 

%	References:
%	Mazumder and Hastie (2012). "The graphical lasso: New insights and
%   alternatives," Electronic Journal of Statistics (6) 2125-2149.
%   Mazumder and Hastie (2012). "Exact Covariance Thresholding into 
%   Connected Components for Large-Scale Graphical Lasso," Journal of 
%   Machine Learning Research (13) 723-726. 
%   http://www.di.ens.fr/~mschmidt/Software/L1precision.html
%   http://statweb.stanford.edu/~tibs/glasso/index.html

%   This software builds on contributions by Mark Schmidt
%   (L1precisionBCD). See references above.
%   This code package was not released with a license.

%	Copyright 2014 OHBA
%	This program is free software: you can redistribute it and/or modify
%	it under the terms of the GNU General Public License as published by
%	the Free Software Foundation, either version 3 of the License, or
%	(at your option) any later version.
%	
%	This program is distributed in the hope that it will be useful,
%	but WITHOUT ANY WARRANTY; without even the implied warranty of
%	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%	GNU General Public License for more details.
%	
%	You should have received a copy of the GNU General Public License
%	along with this program.  If not, see <http://www.gnu.org/licenses/>.


% QPAS licence (called as subfunction):
%     +----------------------------------------------+
%     | Written by Adrian Wills,                     |
%     |            School of Elec. Eng. & Comp. Sci. |
%     |            University of Newcastle,          |
%     |            Callaghan, NSW, 2308, AUSTRALIA   |
%     |                                              |
%     | Last Revised  25 May 2007.                   |
%     |                                              |
%     | Copyright (C) Adrian Wills.                  |
%     +----------------------------------------------+
%    
%   The current version of this software is free of charge and 
%   openly distributed, BUT PLEASE NOTE:
%   
%   This software must be referenced when used in a published work.
%   
%   This software may not be re-distributed as a part of a commercial product. 
%   If you distribute it in a non-commercial products, please contact me first, 
%   to make sure you ship the most recent version.
%   
%   This software is distributed in the hope that it will be useful, 
%   but WITHOUT ANY WARRANTY; without even the implied warranty of 
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%   
%   IF IT FAILS TO WORK, IT'S YOUR LOSS AND YOUR PROBLEM.

%	$LastChangedBy: giles.colclough@gmail.com $
%	$Revision: 214 $
%	$LastChangedDate: 2014-07-24 12:40:42 +0100 (Thu, 24 Jul 2014) $
%	Contact: giles.colclough@gmail.com
%	Originally written on: GLNXA64 by Giles Colclough, 05-Nov-2014 16:56:06

%% allow to be run on a vector of rho values
% do this by calling function recursively.
if isvector(lambda) && length(lambda) > 1,
    % prevent evaluation of optimisation condition on each rho value
    nargoutchk(1,2);
    
    assert(issorted(lambda),                                             ...
           [mfilename ':RhoVecNotSorted'],                               ...
           ['When passing in a path of regularisation parameters rho, ', ...
            'ensure the vector is sorted in ascending order. \n']);
    
    % run with largest rho then use successive results as warmup solutions
    for iR = length(lambda):-1:1,
        if iR < length(lambda),
            ThetaInit = Theta(:,:,iR+1);
        end%if
        [Theta(:,:,iR), W(:,:,iR)] = ROInets.dp_glasso(S, ThetaInit, ...
                                                       lambda(iR),   ...
                                                       varargin{:});
    end%for
    return
end%if

%% Function set-up
narginchk(3,7);

% Parse options
Opt = get_defaults(varargin{:});

% lock function in memory and check for necessary algorithms
if ~Opt.DEBUG,
    mlock
end
useQP = check_for_QP();

% check properties of covariance matrix input
validateattributes(S, {'numeric'}, {'2d', 'nonempty', 'nonnan', 'real'}, ...
                   mfilename, 'S', 1);

[nNodes, m] = size(S);
assert(isequal(nNodes, m) && ROInets.isposdef(S), ...
       [mfilename ':NotPosDefCovInput'],          ...
       'Covariance matrix input S must be square and positive semi-definite. \n');
assert(nNodes > 1,                    ...
       [mfilename ':ScalarCovInput'], ...
       'Expecting the input covariance S to be bigger than 1x1. \n');

% check properties of lambda
if ~isscalar(lambda),
    error([mfilename ':NonScalarRho'],                        ...
          '%s: Expected scalar regularization parameter. \n', ...
          mfilename); 
      
% check if no regularisation
elseif 0 == lambda,
    if nargout > 1,
        W      = S;
        objCon = 0;
    end%if
    Theta = ROInets.cholinv(S);
    return
    
else
    assert(lambda > 0,                    ...
           [mfilename ':NegativeRho'], ...
           'Regularisation parameter rho must be positive. \n');
end%if

    
% switch off display
displayBuffer = '    ';

if 2 <= Opt.verbose, 
    fprintf('Running %s:\n', mfilename);
end%if

% do we computate objective function (costly)?
if 3 <= nargout,
    computeObjective = true; 
else
    computeObjective = false;
end%if

%% Algorithm options
% QP
QP.solver = @qps_as;
QP.box    = lambda;
if 3 <= Opt.verbose,
    QP.verbose = 1;
else
    QP.verbose = 0;
end%if

% lasso
if useQP, 
    run_glasso = @dp_glasso_main;
else
    % run with original glasso code, not dp_glasso, but continue to exploit
    % block structure. 
    run_glasso = @L1precisionBCD_wrapper;
end%if

%% DP-GLASSO
% use adjacency matrix to find block diagonal struture
adjacency                       = abs(S) >= lambda;
adjacency(logical(eye(nNodes))) = true;

% list of connected components in adjacency matrix
componentList = ROInets.scomponents(sparse(adjacency));
nComponents   = max(componentList); 

% initialise matrices with off-diagonals to zero
diagInit = diag(S) + lambda;
W        = diag(diagInit);
Theta    = diag(1.0 ./ diagInit); % lamdba is >0 so no division issues
if ~exist('ThetaInit', 'var') || isempty(ThetaInit),
    ThetaInit = Theta;
end%if
objCon   = cell(nComponents, 1);

% extract unconnected nodes: the correct values for these were set in
% intialisation. 
[~, sociableComponents] = find_hermits(componentList);
nSociableComponents     = length(sociableComponents);

% run glasso algorithm on each block
for iComponent = 1:nSociableComponents,
    compNo = sociableComponents(iComponent);
    
    if Opt.verbose,
        fprintf('%s: running algorithm on block %d of %d \n', ...
                mfilename, iComponent, nSociableComponents);
    end%if
    
    % extract connected nodes for this component
    compInd = (componentList == compNo);
    assert(sum(compInd) > 1,                ...
           [mfilename ':UnexpectedHermit'], ...
           'Hermit component has not been caught. Check me out. \n');
     
    % run glasso on the block matrix
    [Theta(compInd, compInd), W(compInd, compInd), objVals] = ...
             run_glasso(S(compInd, compInd),                  ...
                        ThetaInit(compInd, compInd),          ...
                        lambda, Opt, QP,                      ...
                        computeObjective, displayBuffer);
                    
    if computeObjective, 
        objCon{iComponent} = objVals;
    end%if
end%for
end%dp_glasso
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Opt = get_defaults(varargin)
% GET_DEFAULTS parses inputs and assigns default function parameter values
P               = inputParser;
P.CaseSensitive = false;
P.FunctionName  = mfilename;
P.StructExpand  = true;  % If true, can pass parameter-value pairs in a struct
P.KeepUnmatched = false; % If true, accept unexpected inputs

defaults = struct('DEBUG',   false, ...
                  'verbose', 1,     ...
                  'optTol',  1e-4,  ...
                  'maxIter', 1000);
              
numValidFcn = @(n) isempty(n) || ( isnumeric(n) &&  isscalar(n) && ...
                                  ~isinf(n)     && ~isnan(n)    && n >= 0);

P.addOptional('maxIter', defaults.maxIter, numValidFcn);
P.addOptional('optTol',  defaults.optTol,  numValidFcn);
P.addOptional('verbose', defaults.verbose, numValidFcn);
P.addOptional('DEBUG',   defaults.DEBUG,   @islogical);

P.parse(varargin{:});
Opt = P.Results;

% catch empty inputs
names = fieldnames(Opt);
for iName = 1:length(names),
    if isempty(Opt.(names{iName})),
        Opt.(names{iName}) = defaults.(names{iName});
    end%if
end%for
end%get_defaults
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function l = objFun(S, P, rho)
%OBJFUN objective function for minimisation routine is penalised log-
% likelihood. 
l = - ROInets.logdet(P, 'chol') + sum(S(:) .* P(:)) + rho * sum(abs(P(:))); % trace(S * P) == sum(S(:) .* P(:)) if S is symmetric
end%minCond
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Theta, W, objCon] = dp_glasso_main(S, ThetaInit, lambda, Opt, QP, ...
                                              computeObjective, displayBuffer)
%DP_GLASSO_MAIN main DP_GLASSO algorithm
% Implements the full dp_glasso algorithm, as specified by Mazumder &
% Hastie. 

% initialise
nNodes            = ROInets.cols(S);
W                 = S + lambda .* eye(nNodes);
Theta             = ThetaInit;
QP.algorithmBound = repmat(QP.box, nNodes - 1, 1);

% track minimisation condition
if computeObjective,
    objCon    = NaN(1, nNodes * Opt.maxIter + 1);
    objCon(1) = objFun(S, Theta, lambda);
else
    objCon    = [];
end%if

% track convergence
chg       = 0;
ThetaNorm = norm(Theta, 'fro');

for iIter = 1:Opt.maxIter,
    if 2 <= Opt.verbose,
            fprintf('%s Iter = %d\tChg = %f\n', displayBuffer, iIter, chg);
    end%if
    
    % block coordinate descent
    for iCol = 1:nNodes,
        % partition rows and colums
        blockPartition = ROInets.setdiff_pos_int(1:nNodes, iCol);
        
        % run algorithm on block
        s_12     = S(blockPartition, iCol);
        H        = Theta(blockPartition, blockPartition);
        Theta_11 = (H + H.') ./ 2;  % ensure symmetry in Theta
        gamma    = QP.solver(Theta_11, Theta_11 * s_12,             ...
                             -QP.algorithmBound, QP.algorithmBound, ...
                             QP.verbose);
        
        w_12     = s_12 + gamma;
        theta_12 = - (Theta_11 * w_12) ./ W(iCol, iCol);
        theta_22 = (1 - w_12.' * theta_12) ./ W(iCol, iCol);
        
        % re-allocate values
        W(blockPartition, iCol)               = w_12;
        W(iCol, blockPartition)               = w_12.';
        Theta(blockPartition, blockPartition) = Theta_11;
        Theta(blockPartition, iCol)           = theta_12;
        Theta(iCol, blockPartition)           = theta_12.';
        Theta(iCol, iCol)                     = theta_22;
        
        % monitor convergence
        ThetaNormPrev = ThetaNorm;
        ThetaNorm     = norm(Theta, 'fro');
        chg           = abs(ThetaNorm - ThetaNormPrev) ./ ThetaNormPrev;
        
        % monitor objective condition
        if computeObjective,
            iGap         = (iIter-1) * nNodes + iCol + 1;
            objCon(iGap) = objFun(S, Theta, lambda);
        end%if
        
        if Opt.DEBUG,
            fprintf('%s Iter = %d\tChg = %g\n', displayBuffer, iIter, chg);
        end%if
    end%loop over columns
    
    % monitor convergence
    if chg < Opt.optTol && ~Opt.DEBUG,
        break
    end%if
end%loop over algorithm iterations

% remove unused entries in objective condition
if computeObjective, objCon(isnan(objCon)) = []; end%if

% report information about algorithm completion
if Opt.maxIter == iIter,
    warning([mfilename ':NoConvergence'],                            ...
            '%s %s: maximum iterations hit without convergence. \n', ...
            displayBuffer, mfilename);

elseif Opt.verbose,
    fprintf('%s %s: Solution found. \n', displayBuffer, mfilename);

else
    % display nothing
end%if

end%dp_glasso_block
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [hermits, sociables] = find_hermits(cc)
%FIND_HERMITS finds singly-connected components
%
% [H, NH] = FIND_HERMITS(CC) returns the component numbers H of hermits in
%   connected component list CC, and the component numbers NH of 
%   non-hermits. 
%   Hermits are components which are not connected to any other nodes. 

[sorted_cc, sI] = sort(cc);
repInd          = ~[1; diff(sorted_cc(:))];
undoSortI(sI)   = 1:length(sI);
sociables       = unique(cc(repInd(undoSortI)));
hermits         = ROInets.setdiff_pos_int(cc, sociables);
end%find_hermits
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [Theta, W, objCon] = L1precisionBCD_wrapper(S, ~, lambda, Opt, ...
                                                     ~, ~, ~)
%L1precisionBCD_wrapper calls ROInets.glasso_frequentist
% designed to plug in place of dp_glasso_main: has same argument list. 

[Theta, W] = ROInets.glasso_frequentist(S, lambda, Opt.verbose);
objCon     = NaN;
end%L1precisionBCD_wrapper
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function useQP = check_for_QP()
%CHECK_FOR_QP checks for existence of QPAS algorithm set

% define variable which will flag only on first run
persistent PRINT_SPEED_WARNING

if ~exist('PRINT_SPEED_WARNING', 'var') || isempty(PRINT_SPEED_WARNING),
    % This is the first time this function is run this session
    PRINT_SPEED_WARNING = true;
end%if

% Check for qp mex file
if exist('qps_as', 'file') == 3,
    useQP = 1;
    PRINT_SPEED_WARNING = false;
else 
    useQP = 0;
end%if

% Tell the user they should get compiled mex files
if PRINT_SPEED_WARNING,
    warning([mfilename ':GetMexFiles'],                                    ...
            ['%s will run much faster using the compiled qpas mex files ', ...
             'by Adrian Wills. \n',                                        ...
             'They are obtainable under an attribution, non-commercial ',  ...
             'license from \n ',                                           ...
             '<a href="http://sigpromu.org/quadprog/index.html">',         ...
             'http://sigpromu.org/quadprog/index.html</a>. \n'],           ...
            mfilename);
    PRINT_SPEED_WARNING = false; % prevent from displaying on repeated runs
end%if

% Tell the user about change of algorithm
if ~useQP && PRINT_SPEED_WARNING, 
    warning([mfilename ':ChangeOfAlgorithm'],                           ...
            ['%s: Running lasso with L1precisionBSD glasso algorithm ', ...
             'as qpas not available. \n'],                              ...
            mfilename);
end%if
end%check_for_qp
%% ------------------------------------------------------------------------
% [EOF]
