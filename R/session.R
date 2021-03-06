session <- local({

  #generates a random session hash
  generate <- function(){
    characters <- c(0:9, letters[1:6]);
    hash <- paste(c("x0", sample(characters, 7, replace=TRUE)), collapse="")
    stopifnot(!file.exists(sessiondir(hash)));
    hash;
  }  
  
  #copies a session dir
  fork <- function(oldhash){
    olddir <- sessiondir(oldhash);
    forkdir <- tempfile("fork_dir");
    stopifnot(dir.create(forkdir));
    file.copy(olddir, forkdir, recursive=TRUE);
    stopifnot(identical(list.files(forkdir), basename(olddir)));
    
    newhash <- generate();
    newdir <- sessiondir(newhash);
    stopifnot(file.rename(list.files(forkdir, full.names=TRUE), newdir));
    newhash
  }
  
  #evaluates something inside a session
  eval <- function(input, args, storeval=FALSE, format="list"){
    
    #create a temporary dir
    execdir <- tempfile("ocpu_session_");
    stopifnot(dir.create(execdir));
    setwd(execdir);
    
    #copy files to execdir
    lapply(req$files(), function(x){
      stopifnot(file.copy(x$tmp_name, x$name))
    });
    
    #setup handler
    myhandler <- evaluate::new_output_handler(value=function(myval, visible=TRUE){
      if(isTRUE(storeval) && !isTRUE(is.null(myval))){
        assign(".val", myval, sessionenv);
      }
      if(isTRUE(visible)){
        #note: print can be really, really slow
        if(identical(class(myval), "list")){
          cat("List of length ", length(myval), "\n");
          cat(paste("[", names(myval), "]", sep="", collapse="\n"));
        } else {
          from("evaluate", "render")(myval);
        }
      }
      invisible();
    });
    
    #create session for output objects
    if(missing(args)){
      args <- new.env(parent=globalenv())
    } else {
      args <- as.environment(args);
      parent.env(args) <- globalenv();
    }

    #initiate environment
    sessionenv <- new.env(parent=args);        
    
    #setup some prelim
    pdf(tempfile(), width=11.69, height=8.27, paper="A4r")
    dev.control(displaylist="enable");    
    par("bg" = "white");  

    #run evaluation
    #note: perhaps we should move some of the above inside eval.secure    
    if(isTRUE(getOption("rapache"))){
      outputlist <- RAppArmor::eval.secure({
        output <- evaluate::evaluate(input=input, envir=sessionenv, stop_on_error=2, new_device=FALSE, output_handler=myhandler);
        list(output=output, sessionenv=sessionenv);
      }, profile = "opencpu-exec");
      output <- outputlist$output;
      sessionenv <- outputlist$sessionenv;
    } else {
      output <- evaluate::evaluate(input=input, envir=sessionenv, stop_on_error=2, new_device=FALSE, output_handler=myhandler);
    }
    dev.off();   
    
    #in case code changed dir
    setwd(execdir);
    
    #temp fix for evaluate bug
    output <- Filter(function(x){!emptyplot(x)}, output); 
    
    #store output
    save(file=".RData", envir=sessionenv, list=ls(sessionenv, all.names=TRUE));
    saveRDS(output, file=".REval");
    saveRDS(sessionInfo(), file=".RInfo");  
    saveRDS(.libPaths(), file=".Rlibs"); 

    #does not work on windows 
    #stopifnot(file.rename(execdir, sessiondir(hash))); 
    
    #store results permanently
    hash <- generate();  
    outputdir <- sessiondir(hash);
    
    #First try renaming to destionation directory
    if(!isTRUE(file.rename(execdir, outputdir))){
      #When rename fails, try copying instead
      suppressWarnings(dir.create(dirname(outputdir)));
      stopifnot(file.copy(execdir, dirname(outputdir), recursive=TRUE));
      setwd(dirname(outputdir));
      stopifnot(file.rename(basename(execdir), basename(outputdir)));
      unlink(execdir, recursive=TRUE);      
    }

    #Shortcuts to get object immediately
    if(format %in% c("json", "print")){
      sendobject(hash, get(".val", sessionenv), format);
    } else {
      #default: send 201 with output list.
      sendlist(hash)
    }
  }
  
  sendobject <- function(hash, obj, format){
    tmppath <- sessionpath(hash);
    outputpath <- paste(req$mount(), tmppath, "/", sep="");    
    res$setheader("Location", outputpath); 
    res$setheader("X-ocpu-session", hash)
    httpget_object(obj, format);
  }
  
  #redirects the client to the session location
  sendlist <- function(hash){
    tmppath <- sessionpath(hash);
    outputpath <- paste(req$mount(), tmppath, "/", sep="");
    
    #we are no longer redirecting
    #res$redirect(outputpath, 303);    
    
    outlist <- index(sessiondir(hash));
    text <- paste(outputpath, outlist, sep="", collapse="\n");
    res$setbody(text);
    res$setheader("Content-Type", 'text/plain; charset="UTF-8"');
    res$setheader("Location", outputpath);
    res$setheader("X-ocpu-session", hash)
    res$finish(201);    
  }
  
  #get a list of the contents of the current session
  index <- function(filepath){
    
    #verify session exists
    stopifnot(issession(filepath))
    
    #set the dir
    setwd(filepath)
    
    #outputs
    outlist <- vector();
    
    #list data files
    if(file.exists(".RData")){
      myenv <- new.env();
      load(".RData", myenv);
      if(length(ls(myenv, all.names=TRUE))){
        outlist <- c(outlist, paste("R", ls(myenv, all.names=TRUE), sep="/"));        
      }
    }
    
    #list eval files
    if(file.exists(".REval")){
      myeval <- readRDS(".REval");
      if(length(extract(myeval, "graphics"))){
        outlist <- c(outlist, paste("graphics", seq_along(extract(myeval, "graphics")), sep="/"));        
      }
      if(length(extract(myeval, "message"))){
        outlist <- c(outlist, "messages");        
      } 
      if(length(extract(myeval, "text"))){
        outlist <- c(outlist, "stdout");        
      }       
      if(length(extract(myeval, "warning"))){
        outlist <- c(outlist, "warnings");        
      }        
      if(length(extract(myeval, "source"))){
        outlist <- c(outlist, "source");        
      }   
      if(length(extract(myeval, "console"))){
        outlist <- c(outlist, "console");        
      }        
    }
    
    #list eval files
    if(file.exists(".RInfo")){
      outlist <- c(outlist, "info");
    }    
    
    #other files
    sessionfiles <- file.path("files", list.files(recursive=TRUE))
    if(length(sessionfiles)){
      outlist <- c(outlist, sessionfiles)
    }    
    
    return(outlist);
  }
  
  #actual directory
  sessiondir <- function(hash){
    file.path(gettmpdir(), "tmp_library", paste0("ocpu_tmp_", hash));
  }
  
  #http path for a session (not actual file path!)
  sessionpath <- function(hash){
    paste("/tmp/", hash, sep="");
  }  
  
  #test if a dir is a session
  issession <- function(mydir){
    any(file.exists(file.path(mydir, c(".RData", ".REval"))));
  }
  
  environment();
});
