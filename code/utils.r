######################################
# shared functions among Shiny modules
######################################
#######################
# Multipurpose routines
#######################
# error text
errortxt <- function(txt) return(paste("<span style=\"color:#FF0000\">", txt, "</span>"))

# error message
errorMessage <- function(txt) {
  showModal(modalDialog(
    title = HTML("<span style = 'color:red'>Error Message</span>"),
    HTML(paste0("<span style = 'color:red'>", txt, "</span>")),
    easyClose = TRUE))
}
# template of the plot to show
templatePlot <- function(locs, eye) {
  expf <- 1.05 # expansion factor
  par(mar = c(0, 0, 0, 0))
  lty <- 1
  lwd <- 1
  linColor <- "lightgray"
  ellipseColor <- "gray92"
  pchColor <- "black"
  if(eye == "L") x <- -15
  else x <- 15
  xlim <- c(-30, 30)
  ylim <- c(-30, 30)
  if(!all(is.na(locs$x))) {
    if(min(locs$x, na.rm = TRUE) < xlim[1]) xlim[1] <- min(locs$x, na.rm = TRUE)
    if(max(locs$x, na.rm = TRUE) > xlim[2]) xlim[2] <- max(locs$x, na.rm = TRUE)
  }
  if(!all(is.na(locs$y))) {
    if(min(locs$y, na.rm = TRUE) < ylim[1]) ylim[1] <- min(locs$y, na.rm = TRUE)
    if(max(locs$y, na.rm = TRUE) > ylim[2]) ylim[2] <- max(locs$y, na.rm = TRUE)
  }
  xlim <- 10 * sign(xlim) * ceiling(abs(xlim / 10))
  ylim <- 10 * sign(ylim) * ceiling(abs(ylim / 10))
  r <- max(c(xlim, ylim))
  plot(0, 0, typ = "n", xlim = expf * xlim, ylim = expf * ylim, asp = 1,
       axes = FALSE, ann = FALSE, bty = "n")
  draw.ellipse(x, -1.5, 2.75, 3.75, col = ellipseColor, border = ellipseColor)
  lines(xlim, c(0, 0), col = linColor, lty = lty, lwd = lwd)
  lines(c(0, 0), ylim, col = linColor, lty = lty, lwd = lwd)
  text(expf * xlim[1], 0, xlim[1], adj = c(1, 0.5))
  text(expf * xlim[2], 0, xlim[2], adj = c(0, 0.5))
  text(0, expf * ylim[1], ylim[1], adj = c(0.5, 1))
  text(0, expf * ylim[2], ylim[2], adj = c(0.5, 0))
  l <- 10
  ang <- seq(0, 2 * pi, length.out = 100)
  while(l <= r) {
    x <- sapply(ang, function(a) l * cos(a))
    y <- sapply(ang, function(a) l * sin(a))
    y[x < xlim[1] | x > xlim[2]] <- NA
    x[x < xlim[1] | x > xlim[2]] <- NA
    x[y < ylim[1] | y > ylim[2]] <- NA
    y[y < ylim[1] | y > ylim[2]] <- NA
    lines(x, y, col = linColor, lty = lty, lwd = lwd)
    l <- l + 10
  }
}
# show plot with updated data
showPlot <- function(locs, eye, foveadb) {
  if(is.null(locs)) return(NULL)
  templatePlot(locs, eye)
  alpha <- "AA"
  # unfinished symbols are presented in gray, finished symbols in black
  cols <- brewer.pal(8, "Dark2")[1:max(locs$w, na.rm = TRUE)]
  cols[1] <- "#000000"
  fovcol <- "black"
  text(0, 0, foveadb, col = fovcol, font = 2)
  isna <- is.na(locs$th)
  if(any(isna))  points(locs$x[isna], locs$y[isna], pch = 19, cex = 0.75, col = paste0(cols[locs$w[isna]], alpha))
  if(any(!isna)) text(locs$x[!isna], locs$y[!isna], locs$th[!isna], col = cols[locs$w[!isna]], font = 2)
}
# format secods to mm:ss
secsToMins <- function(secs) {
  mm <- as.character(secs %/% 60)
  ss <- as.character(floor((secs / 60 - secs %/% 60) * 60))
  if(nchar(mm) == 1) mm <- paste0("0", mm)
  if(nchar(ss) == 1) ss <- paste0("0", ss)
  return(paste(mm, ss, sep = ":"))
}
#####################
# Routines for opiApp
#####################
# disable all buttons
disableAll <- function()
  lapply(c("settingsbtn", "gammabtn", "gridgenbtn", "patientsbtn", "clientbtn", "reportbtn"), disable)
# enable all buttons
enableAll <- function()
  lapply(c("settingsbtn", "gammabtn", "gridgenbtn", "patientsbtn", "clientbtn", "reportbtn"), enable)
#######################
# Routines for gprofile
#######################
# generate LUT table
generateLUTtable <- function(setupTable) {
  lutTable <- data.frame(pix = unique(c(seq(setupTable$from[1], setupTable$to[1], by = setupTable$by[1]),
                                        seq(setupTable$from[2], setupTable$to[2], by = setupTable$by[2]),
                                        seq(setupTable$from[3], setupTable$to[3], by = setupTable$by[3]))))
  lutTable$lum1 <- as.numeric(NA)
  lutTable$lum2 <- as.numeric(NA)
  lutTable$lum3 <- as.numeric(NA)
  return(lutTable)
}
# plot LUT results so far
lutPlot <- function(lutTable, lutFit) {
  pix     <- lutTable$pix
  lum     <- apply(lutTable[,2:ncol(lutTable)], 1, mean, na.rm = TRUE) # mean
  lum2sem <- 2 * apply(lutTable[,2:ncol(lutTable)], 1, sd, na.rm = TRUE) / sqrt(ncol(lutTable) - 1) # 2 SEM
  lum2sem[is.na(lum2sem)] <- 0
  par(mar = c(8, 4, 6, 1))
  ymax <- ifelse(all(is.nan(lum)), 0, max(lum[!is.na(lum)]))
  if(ymax < 200) ymax <- 200
  plot(0, 0, typ = "n", xlim = c(0, 255), ylim = c(0, ymax),
       panel.first = grid(), xlab = "pixel value", ylab = "luminance (cd/m2)")
  arrows(pix, lum - lum2sem, pix, lum + lum2sem, length = 0, angle = 90)
  points(pix, lum, pch = 21, bg = "white")
  lines(lutFit$x, lutFit$y, col = "red")
}
# generate handsontables
setuptable <- function(table, readOnly = FALSE) {
  table <- rhandsontable(table, rowHeaders = c("sector 1", "sector 2", "sector 3"), selectCallback = TRUE, height = 100, rowHeaderWidth = 75)
  return(hot_cols(table, format = "1", colWidths = 50, readOnly = readOnly))
}
luttable <- function(table)
  return(hot_col(rhandsontable(table, rowHeaders = NULL, selectCallback = TRUE, height = 400), col = 1, readOnly = TRUE, format = "1"))
######################
# Routines for gridgen
######################
# build grid table
buildGridTable <- function(grids)
  return(data.frame("Code" = names(grids),
                    "Name" = sapply(grids, function(gg) gg$name),
                    "Locations" = sapply(grids, function(gg) nrow(gg$locs)),
                    "Waves" = sapply(grids, function(gg) max(gg$locs$w))))
# init locations
initLocs <- function()
  return(data.frame(x = as.numeric(NA), y = as.numeric(NA), w = as.integer(0)))
# assemble grid table
fillPtsTable <- function(locs, readOnly = FALSE) {
  locsOut <- locs
  locsOut <- rhandsontable(locsOut, colHeaders = c("X", "Y", "Wave"),
                           selectCallback = TRUE, height = 300, rowHeaderWidth = 75,
                           readOnly = readOnly, contextMenu = TRUE) %>%
    hot_col(col = 3, format = "1") %>%
    hot_cols(halign = "htRight", valign = "htMiddle") %>%
    hot_context_menu(allowColEdit = FALSE, allowRowEdit = !readOnly)
  return(locsOut)
}
# show grid points
showGrid <- function(locs) {
  expf <- 1.05 # expansion factor
  par(mar = c(0, 0, 0, 0))
  lty <- 1
  lwd <- 1
  linColor     <- "lightgray"
  ellipseColor <- "gray92"
  xlim <- c(-30, 30)
  ylim <- c(-30, 30)
  if(!all(is.na(locs$x))) {
    if(min(locs$x, na.rm = TRUE) < xlim[1]) xlim[1] <- min(locs$x, na.rm = TRUE)
    if(max(locs$x, na.rm = TRUE) > xlim[2]) xlim[2] <- max(locs$x, na.rm = TRUE)
  }
  if(!all(is.na(locs$y))) {
    if(min(locs$y, na.rm = TRUE) < ylim[1]) ylim[1] <- min(locs$y, na.rm = TRUE)
    if(max(locs$y, na.rm = TRUE) > ylim[2]) ylim[2] <- max(locs$y, na.rm = TRUE)
  }
  xlim <- 10 * sign(xlim) * ceiling(abs(xlim / 10))
  ylim <- 10 * sign(ylim) * ceiling(abs(ylim / 10))
  r <- max(c(xlim, ylim))
  plot(0, 0, typ = "n", xlim = expf * xlim, ylim = expf * ylim, asp = 1,
       axes = FALSE, ann = FALSE, bty = "n")
  draw.ellipse(15, -1.5, 2.75, 3.75, col = ellipseColor, border = ellipseColor)
  lines(xlim, c(0, 0), col = linColor, lty = lty, lwd = lwd)
  lines(c(0, 0), ylim, col = linColor, lty = lty, lwd = lwd)
  text(expf * xlim[1], 0, xlim[1], adj = c(1, 0.5))
  text(expf * xlim[2], 0, xlim[2], adj = c(0, 0.5))
  text(0, expf * ylim[1], ylim[1], adj = c(0.5, 1))
  text(0, expf * ylim[2], ylim[2], adj = c(0.5, 0))
  l <- 10
  ang <- seq(0, 2 * pi, length.out = 100)
  while(l <= r) {
    x <- sapply(ang, function(a) l * cos(a))
    y <- sapply(ang, function(a) l * sin(a))
    y[x < xlim[1] | x > xlim[2]] <- NA
    x[x < xlim[1] | x > xlim[2]] <- NA
    x[y < ylim[1] | y > ylim[2]] <- NA
    y[y < ylim[1] | y > ylim[2]] <- NA
    lines(x, y, col = linColor, lty = lty, lwd = lwd)
    l <- l + 10
  }
  if(!all(is.na(locs))) {
    cols <- brewer.pal(8, "Dark2")[1:max(locs$w, na.rm = TRUE)]
    cols[1] <- "#000000"
    iszero <- locs$w == 0
    if(any(iszero))  text(locs$x[iszero], locs$y[iszero], ".", cex = 2)
    if(any(!iszero)) text(locs$x[!iszero], locs$y[!iszero], locs$w[!iszero], col = cols[locs$w[!iszero]], cex = 0.75, font = 2)
  }
}
#######################
# Routines for patients
#######################
# show or hide fields
showPatientFields <- function()
  lapply(c("id", "name", "surname", "dob", "gender", "type",
           "osva", "osrx", "osoverrx", "odva", "odrx", "odoverrx",
           "osdiagnostic", "oddiagnostic",
           "oscomments", "odcomments",
           "save", "cancel"), showElement)
hidePatientFields <- function()
  lapply(c("id", "name", "surname", "dob", "gender", "type",
           "osva", "osrx", "osoverrx", "odva", "odrx", "odoverrx",
           "osdiagnostic", "oddiagnostic",
           "oscomments", "odcomments",
           "save", "cancel"), hideElement)
# enable or disable fields
enableMandatoryFields <- function()
  lapply(c("id", "name", "surname"), enable)
disableMandatoryFields <- function()
  lapply(c("id", "name", "surname"), disable)
# fill record with patient data
fillRecord <- function(input) {
  return(data.frame(id           = input$id,
                    name         = input$name,
                    surname      = input$surname,
                    dob          = input$dob,
                    gender       = input$gender,
                    type         = input$type,
                    osva         = input$osva,
                    osrx         = input$osrx,
                    osoverrx     = input$osoverrx,
                    osdiagnostic = input$osdiagnostic,
                    oscomments   = input$oscomments,
                    odva         = input$odva,
                    odrx         = input$odrx,
                    odoverrx     = input$odoverrx,
                    oddiagnostic = input$oddiagnostic,
                    odcomments   = input$odcomments,
                    stringsAsFactors = FALSE))
}
fillPatientFields <- function(session, idx, patientTable) {
  textFields <- c("id", "name", "surname", "type",
                  "osva", "osrx", "osoverrx", "odva", "odrx", "odoverrx",
                  "osdiagnostic", "oddiagnostic",
                  "oscomments", "odcomments")
  lapply(textFields, function(field) updateTextInput(session, field, value = patientTable[idx,field]))
  updateDateInput(session, "dob", value = patientTable$dob[idx])
  updateRadioButtons(session, "gender", selected = patientTable$gender[idx])
}
# save new patient
checkNewPatient <- function(input, patientTable) {
  saveok <- TRUE
  errtxt <- ""
  if(input$id          == "" ||
     input$name        == "" ||
     input$surname     == "" ||
     length(input$dob) == 0  ||
     is.null(input$gender)) {
    return(list(saveok = FALSE, errtxt = "please add mandatory fields: ID, Name, Surname, Date of Birth, and Gender"))
  } else if(input$id %in% patientTable$id) {
    # check that there is no other record with the same ID
    return(list(saveok = FALSE, errtxt = "Duplicated ID number"))
  } else if(input$id %in% patientTable$id) { # for same id, name, and surname needs to be same
    idx <- which(patientTable$id == input$id)
    if(input$name    != patientTable$name[idx] ||
       input$surname != patientTable$surname[idx]) {
      return(list(saveok = FALSE, errtxt = "Records with the same ID must have the same Name, Surname, and Date of Birth"))
    }
  }
  return(list(saveok = TRUE, errtxt = ""))
}
# save new patient
saveNewPatient <- function(input, patientTable) {
  df           <- fillRecord(input)
  df$created   <- format(Sys.time(), "%m/%d/%Y %H:%M:%S")
  df$modified  <- df$created
  patientTable <- rbind(patientTable, df) # append new record
  patientTable <- patientTable[order(patientTable$id),] # sort data
  save(patientTable, file = "../config/patientdb.rda")
  return(patientTable)
}
# save modified patient
saveModifiedPatient <- function(input, patientTable) {
  idx                <- input$patientdb_rows_selected         # idx of patient to modify
  df                 <- fillRecord(input)
  df$created         <- patientTable$created[idx]
  df$modified        <- format(Sys.time(), "%m/%d/%Y %H:%M:%S")
  patientTable[idx,] <- df                                    # modify record
  patientTable       <- patientTable[order(patientTable$id),] # sort data by ID
  save(patientTable, file = "../config/patientdb.rda")
  return(patientTable)
}
# delete patient
deletePatient <- function(idx, patientTable) {
  patientTable <- patientTable[-idx,] # delete record
  save(patientTable, file = "../config/patientdb.rda")
  return(patientTable)
}
# clear all data from fields
clearPatientFields <- function(session) {
  textFields <- c("id", "name", "surname", "type",
                  "osva", "osrx", "osoverrx", "odva", "odrx", "odoverrx",
                  "osdiagnostic", "oddiagnostic",
                  "oscomments", "odcomments")
  lapply(textFields, function(field) updateTextInput(session, field, value = ""))
  updateDateInput(session, "dob")
  updateRadioButtons(session, "gender", choices = c("F", "M"), selected = character(), inline = TRUE)
}
# select patient
selectPatient <- function(idx, patientTable)
  return(list(id      = patientTable$id[idx],
              name    = patientTable$name[idx],
              surname = patientTable$surname[idx],
              age     = getPatientAge(patientTable$dob[idx], Sys.Date()),
              gender  = patientTable$gender[idx],
              type    = patientTable$type[idx]))
# init selected patient
initPatient <- function()
  return(list(id = NA, name = NA, surname = NA, dob = NA, gender = NA, type = NA))
# get patient's age
getPatientAge <- function(dob, date) {
  dob  <- as.POSIXlt(dob)
  date <- as.POSIXlt(date)
  age  <- date$year - dob$year
  # if month of DoB has not been reached yet, then a year younger
  idx <- which(date$mon < dob$mon)
  if(length(idx) > 0) age[idx]  <- age[idx] - 1
  # if same month as DoB but day has not been reached, then a year younger
  idx <- which(date$mon == dob$mon & date$mday < dob$mday)
  if(length(idx) > 0) age[idx]  <- age[idx] - 1
  return(age)
}
#####################
# Routines for client
#####################
falsePositivePars <- function(locs, w) {
  # generate an invisible stimulus
  idx <- sample(1:nrow(locs), 1)
  return(data.frame(x = locs$x[idx], y = locs$y[idx], w = w, db = 50))
}
falseNegativePars <- function(res, w) {
  # keep only the dimmest stimulus and select one at random
  resMin <- resMin[res$seen,c("x", "y", "level")]
  res <- unique(resMin[,c("x", "y")])
  for(i in 1:nrow(res))
    res$db[i] <- min(resMin$level[which(resMin$x == res$x[i] & resMin$y == res$y[i])])
  db <- sample(res$db, 1)
  # generate a very visible stimulus
  # TODO criterion. So far, I subtract 5 db
  return(data.frame(x = res$x[idx], y = res$y[idx], w = w, db = ifelse(db < 5, 0, db - 5)))
}
enableElements <- function(ids) lapply(ids, enable)
disableElements <- function(ids) lapply(ids, disable)
enableRunElements <- function()
  enableElements(c("close", "fovea", "run", "eye", "grid", "perimetry", "algorithm", "val", "algval"))
disableRunElements <- function()
  disableElements(c("close", "fovea", "run", "eye", "grid", "perimetry", "algorithm", "val", "algval"))
# patient's information to show: id, name, surname, age, gender
parsePatientOutput <- function(patient) {
  if(is.na(patient$id)) {
    txt <- errortxt("Please select a patient first")
  } else {
    txt <- paste0("<strong>Patient ID:</strong> ", patient$id, ". <strong>Type:</strong> ", patient$type, "</br>")
    txt <- paste0(txt, " <strong>Name:</strong> ",  patient$name, " ", patient$surname, "</br>")
    txt <- paste0(txt, " <strong>Age:</strong> ", patient$age, ". <strong>Gender:</strong> ", patient$gender, "</br>")
  }
  return(HTML(txt))
}
# prepare test results to show next to the plot
renderResult <- function(res, npoints) {
  if(!is.null(res)) {
    x <- tail(res$x, 1)
    y <- tail(res$y, 1)
    level <- tail(res$level, 1)
    time <- tail(res$time, 1)
    respWin <- tail(res$respWin, 1)
    seen <- tail(res$seen, 1)
    if(seen) {
      seentxt <- paste("Stimulus <strong>seen</strong>", "in", time, "ms")
    } else
      seentxt <- paste("Stimulus <strong>not seen</strong>")
    respWintxt <- paste("Response window was", respWin, "ms")
    npres <- sum(res$type == "N")
    nfinished <- sum(res$done) # locations finished
    # compute false positives and negatives
    fp  <- sum(res$type == "FP" & res$seen)
    fpt <- sum(res$type == "FP")
    fpp <- ifelse(fpt == 0, 0, round(100 * fp / fpt))
    fn  <- sum(res$type == "FN" & !res$seen)
    fnt <- sum(res$type == "FN")
    fnp <- ifelse(fnt == 0, 0, round(100 * fn / fnt))
    # compute response time SD and mean
    rt <- res$time[which(res$type == "N" & res$seen == TRUE)]
    if(length(rt) > 1) { # can only calculate SD if there are more than 2 response times available
      rtm  <- round(mean(rt))
      rtsd <- round(sd(rt))
    } else rtsd <- rtm <- ""
    # compute responses below 150 ms and above 600 ms
    resBelow150 <- sum(res$type == "N" & res$time < 150)
    resAbove600 <- sum(res$type == "N" & res$time > 600 & res$seen == TRUE)
    # calculate test time and pause time
    tttxt <- secsToMins(res$tt[length(res$tt)])  
    tptxt <- secsToMins(res$tp[length(res$tp)])
  } else {
    rtsd <- rtm <- respWintxt <- seentxt <- level <- x <- y <- time <- ""
    nfinished <- fp <- fpt <- fpp <- fn <- fnt <- fnp <- 0
    npres <- resBelow150 <- resAbove600 <- 0
    tttxt <- tptxt <- "00:00"
  }
  if(x != "") x <- paste(x, "degrees")
  if(y != "") y <- paste(y, "degrees")
  if(level != "") level <- paste(level, "dB")
  if(rtm != "") rtm <- paste(rtm, "ms")
  if(rtsd != "") rtsd <- paste(rtsd, "ms")
  # get state text
  txt <- paste("<strong>Stimulus x:</strong>", x, "<br/>")
  txt <- paste(txt, "<strong>Stimulus y:</strong>", y, "<br/>")
  txt <- paste(txt, "<strong>Level:</strong>", level, "<br/>")
  txt <- paste0(txt, seentxt, "<br/>")
  txt <- paste0(txt, respWintxt, "<br/>")
  # False positives and negatives
  txt <- paste(txt, "<strong>False Positives:</strong>", fp, "of", fpt)
  txt <- paste0(txt, " (", fpp, "%)<br/>")
  txt <- paste(txt, "<strong>False Negatives:</strong>", fn, "of", fnt)
  txt <- paste0(txt, " (", fnp, "%)<br/>")
  # Response Times
  txt <- paste(txt, "<strong>Responses < 150 ms:</strong>", resBelow150, "<br/>")
  txt <- paste(txt, "<strong>Responses > 600 ms:</strong>", resAbove600, "<br/>")
  txt <- paste(txt, "<strong>Mean Response Time:</strong>", rtm, "<br/>")
  txt <- paste(txt, "<strong>SD of Response Time:</strong>", rtsd, "<br/><br/>")
  # Progress
  txt <- paste(txt, "<strong>Finished:</strong>", nfinished, "of", npoints)
  txt <- paste0(txt, " (", round(100 * nfinished / npoints), "%)<br/>")
  txt <- paste(txt, "<strong>Presentations:</strong>", npres, "<br/>")
  # test time and pause time
  txt <- paste(txt, "<strong>Test Time (mm:ss):</strong>",  tttxt, "<br/>")
  txt <- paste(txt, "<strong>Pause Time (mm:ss):</strong>", tptxt, "<br/>")
  txt <- paste0(txt, "<br/>")
  return(HTML(txt))
}
# prepare results to save
prepareToSave <- function(patient, machine, perimetry, val, grid, eye,
                          algorithm, algval, tdate, ttime, comments, res,
                          foveadb, locs) {
  dat <- data.frame(id = patient$id, eye = eye, date = tdate, time = ttime,
                    machine = machine, perimetry = perimetry, fixedParam = val,
                    grid = grid, algorithm = algorithm, stopValue = algval,
                    age = patient$age, type = patient$type,
                    fp = NA, fpt = NA, fpr = NA, fn = NA, fnt = NA, fnr = NA,
                    npres = NA, rt150 = NA, rt600 = NA, rtsd = NA, rtm = NA,
                    duration = NA, pause = NA, comments = comments, foveadb = NA)
  # test and pause time
  dat$duration <- secsToMins(res$tt[length(res$tt)])
  dat$pause <- secsToMins(res$tp[length(res$tp)])
  # false positive and false negatives
  dat$fp  <- sum(res$type == "FP" & res$seen)
  dat$fpt <- sum(res$type == "FP")
  dat$fpr <- ifelse(dat$fpt == 0, 0, dat$fp / dat$fpt)
  dat$fn  <- sum(res$type == "FN" & !res$seen)
  dat$fnt <- sum(res$type == "FN")
  dat$fnr <- ifelse(dat$fnt == 0, 0, dat$fn / dat$fnt)
  # compute response time SD and mean
  rt <- res$time[which(res$type == "N" & res$seen == TRUE)]
  dat$rtm <- round(mean(rt))
  dat$rtsd <- round(sd(rt))
  # number of presentations and responses below 150 ms and above 600 ms
  dat$npres <- sum(res$type == "N")
  dat$rt150 <- sum(res$type == "N" & res$time < 150)
  dat$rt600 <- sum(res$type == "N" & res$time > 600 & res$seen == TRUE)
  if(!is.null(foveadb)) dat$foveadb <- foveadb
  # get results for each location
  dat[,paste0("l", 1:nrow(locs))] <- locs$th
  return(dat)
}
#####################
# Routines for report
#####################
# get all available reports and sort them by date, then time
getReports <- function(patientTable) {
  fnames <- paste("../results", dir("../results/", pattern = "*.csv"), sep = "/")
  reports <- do.call(rbind, lapply(fnames, function(ff) {
    dat <- read.csv(ff, stringsAsFactors = FALSE)
    return(dat[,setdiff(names(dat), paste0("l", 1:nrow(grids[[dat$grid[1]]]$locs)))])
  }))
  if(is.null(reports)) return(NULL)
  # merge with patient db table to get name, surname, and type of the patient
  reports <- merge(patientTable[,c("id", "name", "surname")], reports, by = "id")
  reports$date <- as.Date(reports$date)
  # sort by date and time
  reports <- reports[order(reports$time, decreasing = TRUE),]
  reports <- reports[order(reports$date, decreasing = TRUE),]
  return(reports)
}
# get record from results
getResults <- function(dat) {
  fname <- paste0("../results/", paste(dat$id, dat$grid, sep = "_"), ".csv")
  record <- read.csv(fname, stringsAsFactors = FALSE)
  record <- record[which(record$date == dat$date[1] & record$time == dat$time[1]),]
  fname <- paste0("../results/logs/", paste(dat$id, dat$grid, 
                                            gsub("-", "", record$date),
                                            gsub(":", "", record$time), sep = "_"), ".csv")
  res <- read.csv(fname, stringsAsFactors = FALSE)
  return(list(record = record, res = res))
}
# prepare test results to show next to the plot
generateReport <- function(record, res, npoints) {
  if(!is.null(record)) {
    id <- record$id
    age <- record$age
    type <- record$type
    machine <- record$machine
    perimetry <- record$perimetry
    fixedParam <- record$fixedParam
    algorithm <- record$algorithm
    stopValue <- record$stopValue
    npres <- sum(res$type == "N")
    # compute false positives and negatives
    fp  <- sum(res$type == "FP" & res$seen)
    fpt <- sum(res$type == "FP")
    fpp <- ifelse(fpt == 0, 0, round(100 * fp / fpt))
    fn  <- sum(res$type == "FN" & !res$seen)
    fnt <- sum(res$type == "FN")
    fnp <- ifelse(fnt == 0, 0, round(100 * fn / fnt))
    # compute response time SD and mean
    rt <- res$time[which(res$type == "N" & res$seen == TRUE)]
    if(length(rt) > 1) { # can only calculate SD if there are more than 2 response times available
      rtm  <- round(mean(rt))
      rtsd <- round(sd(rt))
    } else rtsd <- rtm <- ""
    # compute responses below 150 ms and above 600 ms
    resBelow150 <- sum(res$type == "N" & res$time < 150)
    resAbove600 <- sum(res$type == "N" & res$time > 600 & res$seen == TRUE)
    # calculate test time and pause time
    tttxt <- secsToMins(res$tt[length(res$tt)])  
    tptxt <- secsToMins(res$tp[length(res$tp)])
  } else {
    rtsd <- rtm <- id <- age <- type <- machine <- perimetry <- fixedParam <- algorithm <- stopValue <- ""
    fp <- fpt <- fpp <- fn <- fnt <- fnp <- 0
    npres <- resBelow150 <- resAbove600 <- 0
    tttxt <- tptxt <- "00:00"
  }
  if(rtm != "") rtm <- paste(rtm, "ms")
  if(rtsd != "") rtsd <- paste(rtsd, "ms")
  # patient info
  txt <- paste("<strong>Patient ID:</strong>", id, "<br/>")
  txt <- paste(txt, "<strong>Patient Age:</strong>", age, "<br/>")
  txt <- paste(txt, "<strong>Patient Type:</strong>", type, "<br/><br/>")
  # test info
  txt <- paste(txt, "<strong>Device:</strong>", machine, "<br/>")
  txt <- paste(txt, "<strong>Perimetry:</strong>", perimetry, "<br/>")
  if(perimetry == "luminance")
    txt <- paste(txt, "<strong>Fixed Size:</strong>", fixedParam, "\u00B0<br/>")
  else if(perimetry == "size")
    txt <- paste(txt, "<strong>Fixed Luminance:</strong>", fixedParam, "cd/m2<br/>")
  else 
    txt <- paste(txt, "<strong>Wrong perimetry</strong>", "<br/>")
  txt <- paste(txt, "<strong>Algorithm:</strong>", algorithm, "<br/>")
  if(algorithm == "Staircase")
    txt <- paste(txt, "<strong>Initial Estimate:</strong>", stopValue, "db<br/>")
  else if(algorithm == "Full Threshold")
    txt <- paste(txt, "<strong>Initial Estimate:</strong>", stopValue, "dB<br/>")
  else if(algorithm == "MOCS")
    txt <- paste(txt, "<strong>Number of Repetitions:</strong>", stopValue, "<br/>")
  else if(algorithm == "ZEST")
    txt <- paste(txt, "<strong>Estimate SD:</strong>", stopValue, "dB<br/>")
  else
    txt <- paste(txt, "<strong>Wrong algorithm</strong>", "<br/>")
  txt <- paste0(txt, "<br/>")
  # False positives and negatives
  txt <- paste(txt, "<strong>False Positives:</strong>", fp, "of", fpt)
  txt <- paste0(txt, " (", fpp, "%)<br/>")
  txt <- paste(txt, "<strong>False Negatives:</strong>", fn, "of", fnt)
  txt <- paste0(txt, " (", fnp, "%)<br/>")
  # Response Times
  txt <- paste(txt, "<strong>Responses < 150 ms:</strong>", resBelow150, "<br/>")
  txt <- paste(txt, "<strong>Responses > 600 ms:</strong>", resAbove600, "<br/>")
  txt <- paste(txt, "<strong>Mean Response Time:</strong>", rtm, "<br/>")
  txt <- paste(txt, "<strong>SD of Response Time:</strong>", rtsd, "<br/><br/>")
  # Progress, test time and pause time
  txt <- paste(txt, "<strong>Presentations:</strong>", npres, "<br/>")
  txt <- paste(txt, "<strong>Test Time (mm:ss):</strong>",  tttxt, "<br/>")
  txt <- paste(txt, "<strong>Pause Time (mm:ss):</strong>", tptxt, "<br/>")
  txt <- paste0(txt, "<br/>")
  return(txt)
}
# generate pdf report
savePDF <- function(fname, record, locs, res, eye, foveadb) {
  # width and height in inches
  width  <- 6
  height <- 2.5
  pdf(file = fname, width = width, height = height)
  par(mar = c(0, 0, 0, 0), ps = 8)
  scrlist <- mountlayout()
  # plot
  screen(scrlist$plot)
  showPlot(locs, eye, foveadb)
  # info
  screen(scrlist$info)
  dat <- parsetxt(generateReport(record, res, nrow(locs)))
  nblocks <- dat$nblocks
  nrows <- dat$nrows
  dat <- dat$dat
  top <- 1
  lineSep <- top / (sum(nrows) + (nblocks - 1))
  for(i in 1:nblocks) {
    txt <- dat[[i]]
    for(j in 1:nrows[i]) {
      text(0, top, txt[j,1], adj = c(0, 1), font = 2)
      text(1, top, txt[j,2], adj = c(1, 1))
      top <- top - lineSep
    }
    top <- top - lineSep
  }
  close.screen(all.screens = TRUE)
  invisible(dev.off())
}
parsetxt <- function(txt) {
  txt <- strsplit(strsplit(txt, split = "<br/><br/>")[[1]], "<br/>")
  txt <- lapply(txt, function(tt) {
    tt <- gsub("<strong>", "", tt, )
    tt <- strsplit(tt, "</strong>")
  })
  nblocks <- length(txt)
  nrows <- rep(NA, nblocks)
  for(i in 1:nblocks) {
    nrows[i] <- length(txt[[i]])
    txt[[i]] <- do.call(rbind, lapply(txt[[i]], function(tt) data.frame(title = trimws(tt[1]), txt = trimws(tt[2]))))
  }
  return(list(nblocks = nblocks, nrows = nrows, dat = txt))
}
# mount layout for report
mountlayout <- function() {
  # all the boxes are defined in mm divided by the width and height
  # of the page, also in mm
  boxPlot <- c(0.0125, 0.6625, 0.025, 0.975)
  boxInfo <- c(0.6625, 0.9875, 0.025, 0.975)
  scr <- split.screen(rbind(boxInfo, boxPlot))
  return(list(info = scr[1], plot = scr[2]))
}