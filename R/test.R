
conditional.test = function(x, y, sx, data, test, B, alpha = 1, learning = TRUE) {

  if (learning) {

    # update the test counter.
    assign(".test.counter", get(".test.counter", envir = .GlobalEnv) + 1,
      envir = .GlobalEnv)

  }#THEN

  sx = sx[sx != ""]
  ndata = nrow(data)
  df = NULL
  perm.counter = NULL

  if (length(sx) == 0) {

    # all unconditional tests need this subsetting, do it here.
    datax = minimal.data.frame.column(data, x)
    datay = minimal.data.frame.column(data, y)

    # Mutual Infomation (chi-square asymptotic distribution)
    if (test == "mi") {

      statistic = mi.test(datax, datay, ndata, gsquare = TRUE)
      df = (nlevels(datax) - 1) * (nlevels(datay) - 1)
      p.value = pchisq(statistic, df, lower.tail = FALSE)

    }#THEN
    # Shrinked Mutual Infomation (chi-square asymptotic distribution)
    else if (test == "mi-sh") {

      statistic = shmi.test(datax, datay, ndata, gsquare = TRUE)
      df = (nlevels(datax) - 1) * (nlevels(datay) - 1)
      p.value = pchisq(statistic, df, lower.tail = FALSE)

    }#THEN
    # Mutual Infomation with df adjustment and data requirement heuristics
    # (chi-square asymptotic distribution)
    else if (test == "mi-adr") {

      # heuristic 1 : when less than 5 individuals per cell in the
      # contingency table, we claim independence (the test is not reliable)
      if (nrow(data) < (5 * nlevels(datax) * nlevels(datay))) {

        statistic = -1
        p.value = 1

      }#THEN
      else {

        # heuristic 2 : df is lowered when a column or row margin is empty in
        # the contingency table.
        test.res = mi.test(datax, datay, ndata, gsquare = TRUE, withdf=TRUE)
        statistic = test.res[1]
        df = test.res[3]

        # If the adjustement heuristic returns a df equal to zero, then one of
        # the X or Y variables can be considered one-dimension given the data
        # sample. In this case we claim independence.
        if (df == 0)
          p.value = 1
        else
          p.value = pchisq(statistic, df, lower.tail = FALSE)

      }#ELSE

    }#THEN
    # Pearson's X^2 test (chi-square asymptotic distribution)
    else if (test == "x2") {

      statistic = x2.test(datax, datay, ndata)
      df = (nlevels(datax) - 1) * (nlevels(datay) - 1)
      p.value = pchisq(statistic, df, lower.tail = FALSE)

    }#THEN
    # Canonical (Linear) Correlation (Student's t distribution)
    else if (test == "cor") {

      statistic = fast.cor(datax, datay, ndata)
      df = ndata - 2
      p.value = pt(abs((statistic * sqrt(ndata - 2) / sqrt(1 - statistic^2))),
                  df, lower.tail = FALSE) * 2

    }#THEN
    # Fisher's Z (asymptotic normal distribution)
    else if (test == "zf") {

      statistic = fast.cor(datax, datay, ndata)
      statistic = log((1 + statistic)/(1 - statistic))/2 * sqrt(ndata -3)
      p.value = pnorm(abs(statistic),
                  lower.tail = FALSE) * 2

    }#THEN
    # Mutual Information for Gaussian Data (chi-square asymptotic distribution)
    else if (test == "mi-g") {

      statistic = mig.test(datax, datay, ndata, gsquare = TRUE)
      df = 1
      p.value = pchisq(statistic, df, lower.tail = FALSE)

    }#THEN
    # Shrinked Mutual Information for Gaussian Data (chi-square asymptotic distribution)
    else if (test == "mi-g-sh") {

      statistic = shmig.test(datax, datay, ndata, gsquare = TRUE)
      df = 1
      p.value = pchisq(statistic, df, lower.tail = FALSE)

    }#THEN
    # Mutual Infomation (monte carlo permutation distribution)
    else if ((test == "mc-mi") || (test == "smc-mi")) {

      perm.test = mc.test(datax, datay, ndata, samples = B,
                    alpha = ifelse(test == "smc-mi", alpha, 1), test = 1L)
      statistic = perm.test[1]
      p.value = perm.test[2]
      perm.counter = perm.test[3]

    }#THEN
    # Mutual Infomation (semiparametric)
    else if (test == "sp-mi") {

      perm.test = mc.test(datax, datay, ndata, samples = B,
                    alpha = 1, test = 6L)
      statistic = perm.test[1]
      df = perm.test[2]
      perm.counter = perm.test[3]
      p.value = pchisq(statistic, df, lower.tail = FALSE)

    }#THEN
    # Pearson's X^2 test (monte carlo permutation distribution)
    else if ((test == "mc-x2") || (test == "smc-x2")) {

      perm.test = mc.test(datax, datay, ndata, samples = B,
                    alpha = ifelse(test == "smc-x2", alpha, 1), test = 2L)
      statistic = perm.test[1]
      p.value = perm.test[2]
      perm.counter = perm.test[3]

    }#THEN
    # Pearson's X^2 test (semiparametric)
    else if (test == "sp-x2") {

      perm.test = mc.test(datax, datay, ndata, samples = B,
                    alpha = 1, test = 7L)
      statistic = perm.test[1]
      df = perm.test[2]
      p.value = pchisq(statistic, df, lower.tail = FALSE)
      perm.counter = perm.test[3]

    }#THEN
    # Mutual Information for Gaussian Data (monte carlo permutation distribution)
    else if ((test == "mc-mi-g") || (test == "smc-mi-g")) {

      statistic = mig.test(datax, datay, ndata, gsquare = TRUE)
      perm.test = gmc.test(datax, datay, samples = B,
                  alpha = ifelse(test == "smc-mi-g", alpha, 1), test = 3L)
      p.value = perm.test[1]
      perm.counter = perm.test[2]

    }#THEN
    # Canonical (Linear) Correlation (monte carlo permutation distribution)
    else if ((test == "mc-cor") || (test == "smc-cor")) {

      statistic = fast.cor(datax, datay, ndata)
      perm.test = gmc.test(datax, datay, samples = B,
                  alpha = ifelse(test == "smc-cor", alpha, 1), test = 4L)
      p.value = perm.test[1]
      perm.counter = perm.test[2]

    }#THEN
    # Fisher's Z (monte carlo permutation distribution)
    else if ((test == "mc-zf") || (test == "smc-zf")) {

      statistic = fast.cor(datax, datay, ndata)
      statistic = log((1 + statistic)/(1 - statistic))/2 * sqrt(ndata -3)
      perm.test = gmc.test(datax, datay, samples = B,
                  alpha = ifelse(test == "smc-zf", alpha, 1), test = 5L)
      p.value = perm.test[1]
      perm.counter = perm.test[2]

    }#THEN

  }#THEN
  else {

    # build the contingency table only for discrete data.
    if (test %in% available.discrete.tests) {

      datax = minimal.data.frame.column(data, x)
      datay = minimal.data.frame.column(data, y)

      # if there is only one parent, get it easy.
      if (length(sx) == 1)
        config = minimal.data.frame.column(data, sx)
      else
        config = configurations(minimal.data.frame.column(data, sx))

    }#THEN

    # Conditional Mutual Infomation (chi-square asymptotic distribution)
    if (test == "mi") {

      statistic = cmi.test(datax, datay, config, ndata, gsquare = TRUE)
      df = (nlevels(datax) - 1) * (nlevels(datay) - 1) * nlevels(config)
      p.value = pchisq(statistic, df, lower.tail = FALSE)

    }#THEN
    # Shrinked Conditional Mutual Infomation (chi-square asymptotic distribution)
    else if (test == "mi-sh") {

      statistic = shcmi.test(datax, datay, config, ndata, gsquare = TRUE)
      df = (nlevels(datax) - 1) * (nlevels(datay) - 1) * nlevels(config)
      p.value = pchisq(statistic, df, lower.tail = FALSE)

    }#THEN
    # Mutual Infomation with df adjustment and data requirement heuristics
    # (chi-square asymptotic distribution)
    else if (test == "mi-adr") {

      # heuristic 1 : when less than 5 individuals per cell in the
      # contingency table, we claim independence (the test is not reliable)
      if (nrow(data) < (5 * nlevels(datax) * nlevels(datay) * nlevels(config))) {

        statistic = -1
        p.value = 1

      }#THEN
      else {

        # heuristic 2 : df is lowered when a column or row margin is empty in
        # the contingency table.
        test.res = cmi.test(datax, datay, config, ndata, gsquare = TRUE, withdf=TRUE)
        statistic = test.res[1]
        df = test.res[3]

        # If the adjustement heuristic returns a df equal to zero, then one of
        # the X or Y variables can be considered one-dimension given the data
        # sample. In this case we claim independence.
        if (df == 0)
          p.value = 1
        else
          p.value = pchisq(statistic, df, lower.tail = FALSE)

      }#ELSE

    }#THEN
    # Pearson's X^2 test (chi-square asymptotic distribution)
    else if (test == "x2") {

      statistic = cx2.test(datax, datay, config, ndata)
      df = (nlevels(datax) - 1) * (nlevels(datay) - 1) * nlevels(config)
      p.value = pchisq(statistic, df, lower.tail = FALSE)

    }#THEN
    # Canonical Partial Correlation (Student's t distribution)
    else if (test == "cor") {

      # define the degrees of freedom and check them.
      df = ndata - 2 - length(sx)
      if (df < 1)
        stop("trying to do a conditional independence test with zero degrees of freedom.")

      statistic = fast.pcor(x, y, sx, data, ndata, strict = !learning)
      p.value = pt(abs(statistic * sqrt(df) / sqrt(1 - statistic^2)), df, lower.tail = FALSE) * 2

    }#THEN
    # Fisher's Z (asymptotic normal distribution)
    else if (test == "zf") {

      # define the degrees of freedom and check them.
      df = ndata - 3 - length(sx)
      if (df < 1)
        stop("trying to do a conditional independence test with zero degrees of freedom.")

      statistic = fast.pcor(x, y, sx, data, ndata, strict = !learning)
      statistic = log((1 + statistic)/(1 - statistic))/2 * sqrt(df)
      p.value = pnorm(abs(statistic), lower.tail = FALSE) * 2

    }#THEN
    # Mutual Information for Gaussian Data (chi-square asymptotic distribution)
    else if (test == "mi-g") {

      statistic = cmig.test(x, y, sx, data, ndata, gsquare = TRUE)
      df = 1
      p.value = pchisq(statistic, df, lower.tail = FALSE)

    }#THEN
    # Shrinked Mutual Information for Gaussian Data (chi-square asymptotic distribution)
    else if (test == "mi-g-sh") {

      statistic = shcmig.test(x, y, sx, data, ndata, gsquare = TRUE)
      df = 1
      p.value = pchisq(statistic, df, lower.tail = FALSE)

    }#THEN
    # Mutual Infomation (monte carlo permutation distribution)
    else if ((test == "mc-mi") || (test == "smc-mi")) {

      perm.test = cmc.test(datax, datay, config, ndata, samples = B,
                    alpha = ifelse(test == "smc-mi", alpha, 1), test = 1L)
      statistic = perm.test[1]
      p.value = perm.test[2]
      perm.counter = perm.test[3]

    }#THEN
    # Mutual Infomation (semiparametric)
    else if (test == "sp-mi") {

      perm.test = cmc.test(datax, datay, config, ndata, samples = B,
                    alpha = 1, test = 6L)
      statistic = perm.test[1]
      df = perm.test[2]
      perm.counter = perm.test[3]
      p.value = pchisq(statistic, df, lower.tail = FALSE)

    }#THEN
    # Pearson's X^2 test (monte carlo permutation distribution)
    else if ((test == "mc-x2") || (test == "smc-x2")) {

      perm.test = cmc.test(datax, datay, config, ndata, samples = B,
                    alpha = ifelse(test == "smc-x2", alpha, 1), test = 2L)
      statistic = perm.test[1]
      p.value = perm.test[2]
      perm.counter = perm.test[3]

    }#THEN
    # Pearson's X^2 test (semiparametric)
    else if (test == "sp-x2") {

      perm.test = cmc.test(datax, datay, config, ndata, samples = B,
                    alpha = 1, test = 7L)
      statistic = perm.test[1]
      df = perm.test[2]
      perm.counter = perm.test[3]
      p.value = pchisq(statistic, df, lower.tail = FALSE)

    }#THEN
    # Mutual Information for Gaussian Data (monte carlo permutation distribution)
    else if ((test == "mc-mi-g") || (test == "smc-mi-g")) {

      statistic = cmig.test(x, y, sx, data, ndata, gsquare = TRUE)
      perm.test = cgmc.test(x, y, sx, data, ndata, samples = B,
                  alpha = ifelse(test == "smc-mi-g", alpha, 1), test = 3L)
      p.value = perm.test[1]
      perm.counter = perm.test[2]

    }#THEN
    # Canonical Partial Correlation (monte carlo permutation distribution)
    else if ((test == "mc-cor") || (test == "smc-cor")) {

      statistic = fast.pcor(x, y, sx, data, ndata, strict = !learning)
      perm.test = cgmc.test(x, y, sx, data, ndata, samples = B,
                  alpha = ifelse(test == "smc-cor", alpha, 1), test = 4L)
      p.value = perm.test[1]
      perm.counter = perm.test[2]

    }#THEN
    # Fisher's Z (monte carlo permutation distribution)
    else if ((test == "mc-zf") || (test == "smc-zf")) {

      df = ndata - 3 - length(sx)
      statistic = fast.pcor(x, y, sx, data, ndata, strict = !learning)
      statistic = log((1 + statistic)/(1 - statistic))/2 * sqrt(df)
      perm.test = cgmc.test(x, y, sx, data, ndata, samples = B,
                  alpha = ifelse(test == "smc-zf", alpha, 1), test = 5L)
      p.value = perm.test[1]
      perm.counter = perm.test[2]

    }#THEN

  }#ELSE

  if (learning) {

    # update the permutation counter.
    if (!is.null(perm.counter))
      assign(".test.counter.permut", get(".test.counter.permut",
        envir = .GlobalEnv) + perm.counter, envir = .GlobalEnv)

    return(p.value)

  }#THEN
  else {

    # build a valid object of class htest.
    result = structure(
        list(statistic = structure(statistic, names = test),
             p.value = p.value,
             method = test.labels[test],
             null.value = c(value = 0),
             alternative = ifelse(test %in% c("cor", "zf", "mc-cor", "mc-zf"),
               "two.sided", "greater"),
             data.name = paste(x, "~", y,
               ifelse(length(sx) > 0, "|", ""),
               paste(sx, collapse = " + "))
        ), class = "htest")

    if (!is.null(perm.counter))
      result$parameter[["Permutations counter"]] = perm.counter

    if (!is.null(df))
      result$parameter[["df"]] = df

    if (!is.null(B))
      result$parameter[["Monte Carlo samples"]] = B

    return(result)

  }#ELSE

}#CONDITIONAL.TEST

# Mutual Information (discrete data)
mi.test = function(x, y, ndata, gsquare = TRUE, withdf = FALSE) {

  res = .Call("mi",
      x = x,
      y = y,
      lx = nlevels(x),
      ly = nlevels(y),
      length = ndata,
      withdf = withdf,
      PACKAGE = "bnlearn")

  res[1] = ifelse(gsquare, 2 * ndata * res[1], res[1])

  return(res)

}#MI.TEST

# Shrinked Mutual Information (discrete data)
shmi.test = function(x, y, ndata, gsquare = TRUE) {

  s = .Call("shmi",
      x = x,
      y = y,
      lx = nlevels(x),
      ly = nlevels(y),
      length = ndata,
      PACKAGE = "bnlearn")

  ifelse(gsquare, 2 * ndata * s, s)

}#SHMI.TEST

# Monte Carlo (discrete data)
mc.test = function(x, y, ndata, samples, alpha, test) {

  .Call("mcarlo",
        x = x,
        y = y,
        lx = nlevels(x),
        ly = nlevels(y),
        length = ndata,
        samples = samples,
        test = test,
        alpha = alpha,
        PACKAGE = "bnlearn")

}#MC.TEST

# Conditional Mutual Information (discrete data)
cmi.test = function(x, y, z, ndata, gsquare = TRUE, withdf = FALSE) {

  res = .Call("cmi",
      x = x,
      y = y,
      z = z,
      lx = nlevels(x),
      ly = nlevels(y),
      lz = nlevels(z),
      length = ndata,
      withdf = withdf,
      PACKAGE = "bnlearn")

  res[1] = ifelse(gsquare, 2 * ndata * res[1], res[1])

  return(res)

}#CMI.TEST

# Shrinked Conditional Mutual Information (discrete data)
shcmi.test = function(x, y, z, ndata, gsquare = TRUE) {

  s = .Call("shcmi",
      x = x,
      y = y,
      z = z,
      lx = nlevels(x),
      ly = nlevels(y),
      lz = nlevels(z),
      length = ndata,
      PACKAGE = "bnlearn")

  ifelse(gsquare, 2 * ndata * s, s)

}#SHCMI.TEST

# Conditional Monte Carlo (discrete data)
cmc.test = function(x, y, z, ndata, samples, alpha, test) {

  .Call("cmcarlo",
        x = x,
        y = y,
        z = z,
        lx = nlevels(x),
        ly = nlevels(y),
        lz = nlevels(z),
        length = ndata,
        samples = samples,
        test = test,
        alpha = alpha,
        PACKAGE = "bnlearn")

}#CMC.TEST

# Mutual Information (gaussian data)
mig.test = function(x, y, ndata, gsquare = TRUE) {

  s = .Call("mig",
      x = x,
      y = y,
      length = ndata,
      PACKAGE = "bnlearn")

  ifelse(gsquare, 2 * ndata * s, s)

}#MIG.TEST

# Shrinked Mutual Information (gaussian data)
shmig.test = function(x, y, ndata, gsquare = TRUE) {

  s = - 0.5 * log(1 - fast.shcor(x, y, ndata)^2)

  ifelse(gsquare, 2 * ndata * s, s)

}#SHMIG.TEST

# Conditional Mutual Information (gaussian data)
cmig.test = function(x, y, z, data, ndata, strict, gsquare = TRUE) {

  s = - 0.5 * log(1 - fast.pcor(x, y, z, data, ndata, strict)^2)

  ifelse(gsquare, 2 * ndata * s, s)

}#CMIG.TEST

# Shrinked Conditional Mutual Information (gaussian data)
shcmig.test = function(x, y, z, data, ndata, gsquare = TRUE) {

  s = - 0.5 * log(1 - fast.shpcor(x, y, z, data, ndata, strict = TRUE)^2)

  ifelse(gsquare, 2 * ndata * s, s)

}#SHCMIG.TEST

# Monte Carlo (gaussian data)
gmc.test = function(x, y, samples, alpha, test) {

  .Call("gauss_mcarlo",
        x = x,
        y = y,
        samples = samples,
        test = test,
        alpha = alpha,
        PACKAGE = "bnlearn")

}#GMC.TEST

# Conditional Monte Carlo (gaussian data)
cgmc.test = function(x, y, sx, data, ndata, samples, alpha, test) {

  .Call("gauss_cmcarlo",
        data = minimal.data.frame.column(data, c(x, y, sx)),
        length = ndata,
        samples = samples,
        test = test,
        alpha = alpha,
        PACKAGE = "bnlearn")

}#CGMC.TEST

# Pearson's X^2 test (discrete data)
x2.test = function(x, y, ndata) {

  .Call("x2",
      x = x,
      y = y,
      lx = nlevels(x),
      ly = nlevels(y),
      length = ndata,
      PACKAGE = "bnlearn")

}#X2.TEST

# Pearson's Conditional X^2 test (discrete data)
cx2.test = function(x, y, z, ndata) {

  .Call("cx2",
      x = x,
      y = y,
      z = z,
      lx = nlevels(x),
      ly = nlevels(y),
      lz = nlevels(z),
      length = ndata,
      PACKAGE = "bnlearn")

}#CX2.TEST

# Fast implementation of the linear correlation coefficient.
fast.cor = function(x, y, ndata) {

  .Call("fast_cor",
        x = x,
        y = y,
        length = ndata,
        PACKAGE = "bnlearn")

}#FAST.COR

# Fast implementation of the partial correlation coefficient.
fast.pcor = function(x, y, sx, data, ndata, strict) {

  .Call("fast_pcor",
        data = minimal.data.frame.column(data, c(x, y, sx)),
        length = ndata,
        shrinkage = FALSE,
        strict = strict,
        PACKAGE = "bnlearn")

}#FAST.PCOR

# Fast implementation of the shrinked linear correlation coefficient.
fast.shcor = function(x, y, ndata) {

  .Call("fast_shcor",
        x = x,
        y = y,
        length = ndata,
        PACKAGE = "bnlearn")

}#FAST.SHCOR

# Fast implementation of the shrinked partial correlation coefficient.
fast.shpcor = function(x, y, sx, data, ndata, strict) {

  .Call("fast_pcor",
        data = minimal.data.frame.column(data, c(x, y, sx)),
        length = ndata,
        shrinkage = TRUE,
        strict = strict,
        PACKAGE = "bnlearn")

}#FAST.SHPCOR


