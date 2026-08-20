/* Adapted from Project.sas (lines 870-883): the PROC IML eigen-decomposition
   step used to regularize a near-singular random-effects covariance matrix
   before marginalizing the logistic mixed model. Fully self-contained in the
   original (a literal 2x2 matrix) — runs unmodified here. */

proc iml;
d={3.0359 0.2712, 0.2712 0.0187};
call eigen(evals, evecs, D);
print "Eigenvalues", evals;
print "Eigenvectors", evecs;
/*Replace small eigenvalues with a small positive number*/
evals=choose(evals >1e-6, evals, 1e-6);
evals=diag(evals);
print "Regularized Eigenvalues", evals;
/*Reconstruct the covariance matrix using regularized eignevalues*/
D_reg = evecs*evals*t(evecs);
l=root(D_reg);
print D_reg; print l;
quit;
