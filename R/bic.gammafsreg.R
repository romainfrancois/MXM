bic.gammafsreg <- function( target, dataset, wei = NULL, tol = 0, ncores = 1) {
  
  p <- dim(dataset)[2]  ## number of variables
  bico <- numeric( p )
  moda <- list()
  k <- 1   ## counter
  n <- length(target)  ## sample size
  tool <- NULL
  info <- matrix( 0, ncol = 2 )
  #check for NA values in the dataset and replace them with the variable median or the mode
  if ( any( is.na(dataset) ) ) {
    warning("The dataset contains missing values (NA) and they were replaced automatically by the variable (column) median (for numeric) or by the most frequent level (mode) if the variable is factor")
    if ( is.matrix(dataset) )  {
      dataset <- apply( dataset, 2, function(x){ x[which(is.na(x))] = median(x, na.rm = TRUE) ; return(x) } ) 
    } else {
      poia <- unique( which( is.na(dataset), arr.ind = TRUE )[, 2] )
      for( i in poia )  {
        xi <- dataset[, i]
        if ( is.numeric(xi) ) {                    
          xi[ which( is.na(xi) ) ] <- median(xi, na.rm = TRUE) 
        } else if ( is.factor( xi ) )     xi[ which( is.na(xi) ) ] <- levels(xi)[ which.max( as.vector( table(xi) ) )]
        dataset[, i] <- xi
      }
    }
  }
  
  dataset <- as.data.frame(dataset)

    durat <- proc.time()
    ini = BIC( glm( target ~ 1, weights = wei, family = Gamma(link = log), y = FALSE, model = FALSE ) )   ## initial BIC
	
    if (ncores <= 1) {
        for (i in 1:p) { 
          mi <- glm( target ~ dataset[, i], data = dataset[, i], family = Gamma(link = log), weights = wei )
          bico[i] <-  BIC(mi)
        }	      
      mat <- cbind(1:p, bico)
      if( any( is.na(mat) ) )   mat[ which( is.na(mat) ) ] = ini
      
    } else {
        cl <- makePSOCKcluster(ncores)
        registerDoParallel(cl)
        mod <- foreach( i = 1:p, .combine = rbind) %dopar% {
          ww <- glm( target ~ dataset[, i], data = dataset[, i], family =  Gamma(link = log), weights = wei )
          return( BIC(ww) )   ## initial BIC
        }
        stopCluster(cl) 
       
      mat <- cbind(1:p, mod)
      if ( any( is.na(mat) ) )    mat[ which( is.na(mat) ) ] = ini
    }
    
    colnames(mat) <- c("variable", "BIC")
    rownames(mat) <- 1:p
    sel <- which.min( mat[, 2] )
    sela <- sel
    
    if ( ini - mat[sel, 2] > tol ) {
      
      info[1, ] <- mat[sel, ]
      mat <- mat[-sel, , drop = FALSE]
        mi <- glm( target ~ dataset[, sel], family = Gamma(link = log), weights = wei, y = FALSE, model = FALSE )
        tool[1] <- BIC( mi )
      moda[[ 1 ]] <- mi
    }  else  {
      info <- info  
      sela <- NULL
    }
    ######
    ###     k equals 2
    ######
    if ( length(moda) > 0  &  nrow(mat) > 0 ) {
      
      k <- 2
      pn <- p - k  + 1
      mod <- list()
      
      if ( ncores <= 1 ) {
        bico <- numeric( pn )
          for ( i in 1:pn ) {
            ma <- glm( target ~., data = dataset[, c(sel, mat[i, 1]) ], family = Gamma(link = log), y = FALSE, model = FALSE )
            bico[i] <- BIC( ma )
          }
        mat[, 2] <- bico
       
      } else {
        cl <- makePSOCKcluster(ncores)
        registerDoParallel(cl)
        mod <- foreach( i = 1:pn, .combine = rbind) %dopar% {
          ww <- glm( target ~ dataset[, sel ] + dataset[, mat[i, 1] ], family = Gamma(link = log), weights = wei )
          return( BIC( ww ) )
        }
        stopCluster(cl)
        mat[, 2] <- mod
      }
      
      ina <- which.min( mat[, 2] )
      sel <- mat[ina, 1]
      if ( tool[1] - mat[ina, 2] <= tol ) {
        info <- info
      } else {
        tool[2] <- mat[ina, 2]
        info <- rbind(info, mat[ina, ] )
        sela <- info[, 1]
        mat <- mat[-ina, , drop = FALSE]
      }
      
    }
    #########
    ####      k is greater than 2
    #########
    if ( nrow(info) > 1  &  nrow(mat) > 0 ) {
      while (  k < n - 15  &  tool[ k - 1 ] - tool[ k ] > tol  & nrow(mat) > 0 ) {
        
        k <- k + 1
        pn <- p - k + 1
        
        if (ncores <= 1) {
            for ( i in 1:pn ) {
              ma <- glm( target ~., data = dataset[, c(sela, mat[i, 1]) ], family = Gamma(link = log), weights = wei, y = FALSE, model = FALSE )
              mat[i, 2] <- BIC( ma )
            }
          
        } else {
            cl <- makePSOCKcluster(ncores)
            registerDoParallel(cl)
            bico <- numeric(pn)
            mod <- foreach( i = 1:pn, .combine = rbind) %dopar% {
              ww <- glm( target ~., data = dataset[, c(sela, mat[i, 1]) ], family = Gamma(link = log), weights = wei )
              bico[i] <- BIC( ww )
            }
            stopCluster(cl)
          mat[, 2] <- mod
          
        }
        
        ina <- which.min( mat[, 2] )
        sel <- mat[ina, 1]
        if ( tool[k - 1] - mat[ina, 2]  <= tol ) {
          info <- rbind( info,  c( -10, 1e300 ) )
          tool[k] <- Inf
          
        } else {
          tool[k] <- mat[ina, 2]
          info <- rbind(info, mat[ina, ] )
          sela <- info[, 1]
          mat <- mat[-ina, , drop = FALSE]
        }
        
      }
      
    }
    
    duration <- proc.time() - durat

  d <- length(sela)
  final <- NULL
  
  if ( d >= 1 ) {
    final <- glm( target ~., data = dataset[, sela], weights = wei, family = Gamma(link = log), model = FALSE )
    info <- info[1:d, , drop = FALSE]
    colnames(info) <- c( "variables", "BIC" )
    rownames(info) <- info[, 1]
  }
  list( runtime = duration, mat = t(mat), info = info,ci_test = "testIndGamma",  final = final)
}
