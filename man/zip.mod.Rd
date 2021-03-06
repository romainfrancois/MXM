\name{Zero inflated Poisson and negative binomial regression}
\alias{zip.mod}
\alias{zip.reg}
\alias{zinb.mod}
\alias{zinb.reg}
\title{
Zero inflated Poisson and negative binomial regression
}

\description{
Zero inflated Poisson and negative binomial regression.
}

\usage{
zip.mod(target, dataset, wei = NULL, xnew = NULL) 
zip.reg(target, dataset, wei = NULL, lgy = NULL) 
zinb.mod(target, dataset, xnew = NULL)
zinb.reg(target, dataset, lgy = NULL)
}

\arguments{
\item{target}{
The target (dependent) variable. It must be a numerical vector with integers. 
}
\item{dataset}{
The indendent variable(s). It can be a vector, a matrix or a dataframe with continuous only variables, a data frame 
with mixed or only categorical variables. If this is NULL, a zero inflated Poisson distribution is fitted, no covariates 
are present.
}
\item{wei}{
A vector of weights to be used for weighted regression. The default value is NULL. An example where weights are used is surveys when stratified sampling has occured.
This is applicable only in the zero inflated Poisson distribution.
}
\item{xnew}{
If you have new values for the predictor variables (dataset) whose target variable you want to predict insert them here. 
If you put the "dataset" or leave it NULL it will calculate the regression fitted values.
}
\item{lgy}{
If you have already calculated the constant term of the ZIP regression plug it here. This is the sum of the logarithm of 
the factorial of the values. }
}

\details{
The zero inflated Poisson regression as suggested by Lambert (1992) is fitted. Unless you have a sufficient number of zeros, 
there is no reason to use this model. The "zip.reg" is an internal wrapper function and is used for speed up purposes. 
It is not to be called directly by the user unless they know what they are doing. The zero inflated negative binomial 
regression does not accept weights though.
}

\value{
A list including:
\item{be}{
The estimated coefficients of the model and for the zip.mod and zinb.mod the standard errors, 
Wald test statistics and p-values are included.
}
\item{prop}{
The estimated proportion of zeros. 
}
\item{loglik}{
The log-likelihood of the regression model. 
}
\item{est}{
The estimated values if "xnew" is not NULL.
}
}

\references{
Lambert D. (1992). Zero-inflated Poisson regression, with an application to defects in manufacturing. 
Technometrics, 34(1):1-14.

Rui Fang (2013). Zero-inflated neagative binomial (ZINB) regression model for over-dispersed count data with excess zeros and 
repeated measures, an application to human microbiota sequence data. MSc thesis, University of Colorado. 
https://mountainscholar.org/bitstream/handle/10968/244/FANG_ucdenveramc_1639M_10037.pdf?sequence=1&isAllowed=y
}

\author{
 Michail Tsagris

R implementation and documentation: Michail Tsagris \email{mtsagris@uoc.gr}
}

%\note{
%%  ~~further notes~~
%}

\seealso{
\code{ \link{testIndZIP}, \link{zip.regs}, \link{reg.fit}, \link{ridge.reg} }
}

\examples{
y <- rpois(100, 2)
x <- matrix( rnorm(100 * 2), ncol = 2)
a1 <- glm(y ~ x, poisson)
a2 <- zip.mod(y, x) 
summary(a1)
logLik(a1)
a2  ## a ZIP is not really necessary
y[1:20] <- 0
a1 <- glm(y ~ x, poisson)
a2 <- zip.mod(y, x) 
summary(a1)
logLik(a1)
a2  ## a ZIP is probably more necessary
}

